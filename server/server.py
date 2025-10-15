from logger import SingletonLogger
import asyncio
import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
import sys

logger = SingletonLogger().get()

class MainApp:
    def __init__(self):
        pub.subscribe(self.onClose, "meshtastic.connection.lost")
        pub.subscribe(self.onConnection, "meshtastic.connection.established")
        #pub.subscribe(self.onReceivePacket, "meshtastic.receive")
        pub.subscribe(self.onReceiveText, "meshtastic.receive.text")
        
        ports = meshtastic.util.findPorts()
        if len(ports) <= 0: self.close()
        self.ports, port = ports, ports[0]
        self.client = SerialInterface(devPath=port)

        self.init = False

    # def onReceivePacket(self, packet, interface):
    #     logger.info(f"Получен пакет: {packet}")

    def onReceiveText(self, packet, interface):
        user_origin: str = packet['fromId']
        user_dest:   str = packet['toId']
        node_origin: int = packet['from']
        node_dest:   int = packet['to']
        payload:     str = packet.get('decoded', {}).get('payload', b'').decode('utf-8')

        if not self.init: return
        forMyUser = user_dest == self.user_id
        forMyNode = node_dest == self.my_id

        logger.info(f"Получено сообщение: '{payload[:10]}'")
        logger.info(f"Origin: {node_origin}, {user_origin}; Dest: {node_dest}, {user_dest}")
        logger.info(f"{forMyNode = }, {forMyUser = }")

        if forMyUser or forMyNode:
            self.processCommands(payload, user_origin, user_dest)
    
    def processCommands(self, payload: str, origin: str, dest: str):
        try:
            args = payload.split(' ')
            if args[0].startswith('/'):
                logger.info(f'Полученна команда {args[0]}')
                return 
            
            match(args[0]):
                case '/ping':
                    self.client.sendText(
                        text=f"pong",
                        destinationId=origin
                    )
                case '/help':
                    self.client.sendText(
                        text=f"/ping, /ask",
                        destinationId=origin
                    )
                case '/ask':
                    self.client.sendText(
                        text=f"Тупой ответ.",
                        destinationId=origin
                    )
                case _: 
                    pass

        except Exception as e:
            logger.error(e)

    def onConnection(self, interface, topic=pub.AUTO_TOPIC):
        self.my_id = user = self.client.getMyNodeInfo()['num']
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
    while True: await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.warning("Завершение программы пользователем.")
