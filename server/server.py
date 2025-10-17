from logger import SingletonLogger
import asyncio
import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
from provider import OpenAiProvider
import sys

logger = SingletonLogger().get()

class MainApp:
    def __init__(self):
        self.loop = asyncio.get_running_loop()
        
        pub.subscribe(self.onClose, "meshtastic.connection.lost")
        pub.subscribe(self.onConnection, "meshtastic.connection.established")
        pub.subscribe(self.onReceiveText, "meshtastic.receive.text")
        
        ports = meshtastic.util.findPorts()
        if len(ports) <= 0: self.close()
        self.ports, port = ports, ports[0]
        self.client = SerialInterface(devPath=port)

        self.init = False
        self.provider = OpenAiProvider()

    def onReceiveText(self, packet, interface):
        # Schedule async processing to avoid blocking the callback thread
        self.loop.call_soon_threadsafe(
            lambda: self.loop.create_task(self.process_message_async(packet, interface))
        )

    async def process_message_async(self, packet, interface):
        user_origin: str = packet['fromId']
        user_dest:   str = packet['toId']
        node_origin: int = packet['from']
        node_dest:   int = packet['to']
        payload:     str = packet.get('decoded', {}).get('payload', b'').decode('utf-8')

        if not self.init: return
        forMyUser = user_dest == self.user_id
        forMyNode = node_dest == self.my_id

        logger.info(f"Получено сообщение: '{payload[:20]}...'")
        logger.info(f"Origin: {node_origin}, {user_origin}; Dest: {node_dest}, {user_dest}")
        logger.info(f"{forMyNode = }, {forMyUser = }")

        if forMyUser or forMyNode:
            await self.processCommands_async(payload, user_origin, user_dest)
    
    async def processCommands_async(self, payload: str, origin: str, dest: str):
        args = payload.split(' ')
        if not args[0].startswith('/'): return
        logger.info(f'Полученна команда {args[0]}')
        match args[0]:
            case '/ping':
                self.client.sendText(
                    text=f"pong",
                    destinationId=origin
                )
            case '/help':
                self.client.sendText(
                    text=f"/ping, /clear, /set <baseurl, key, model>, /ask 'text'",
                    destinationId=origin
                )
            case '/ask':
                response = "Help: /ask привет"
                if len(args) > 1:
                    response = self.provider.ask(
                        user_id=origin,
                        text=" ".join(args[1:])
                    )
                    print(response, len(response))

                chunks = self.provider.split_blocks(response, 75)
                for chunk in chunks:
                    print(chunk)
                    self.client.sendText(
                        text=chunk,
                        destinationId=origin
                    )
                    await asyncio.sleep(5)

            case '/clear':
                self.provider.clear(origin)
                self.client.sendText(
                    text=f"Истроия очищенна",
                    destinationId=origin
                )
            case '/set':
                set_text = "Help: /set <baseurl, key, model>"
                if len(args) == 2:
                    value = args[1]
                    if value.startswith("sk-"):
                        set_params = {"api_key": value}
                        set_text = "Ключ установлен"
                    elif value.startswith("http"):
                        set_params = {"base_url": value}
                        set_text = "Endpoint установлен"
                    else:
                        set_params = {"model": value}
                        set_text = "Модель установлена"

                    self.provider.set(
                        user_id=origin,
                        params=set_params
                    )

                self.client.sendText(
                    text=set_text,
                    destinationId=origin
                )
            case _: 
                pass

    def onConnection(self, interface, topic=pub.AUTO_TOPIC):
        self.my_id = self.client.getMyNodeInfo()['num']
        user = self.client.getMyNodeInfo()['user']
        self.user_id = user['id']
        self.long_name = user['longName']
        self.short_name = user['shortName']
        self.device = user['hwModel']
        self.key = user['publicKey']
        self.init = True

        logger.info(f"Соединение установлено: {self.long_name } ({self.short_name })")
        logger.info(f"Device: {self.device}, num: {self.my_id}, id: {self.user_id}")

    def onClose(self, interface, topic=pub.AUTO_TOPIC):
        logger.warning(f"Соединение потерянно")
        self.init = False
        self.close()

    def close(self):
        logger.warning(f"Закрытие соединения")
        self.client.close()
        logger.warning(f"Закрытие программы")
        sys.exit(1)

async def main():
    app = MainApp()
    while True: 
        await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.warning("Завершение программы пользователем.")