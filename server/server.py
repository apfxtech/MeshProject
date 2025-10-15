from log import SingletonLogger
import asyncio
import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
import sys

SingletonLogger().clear()
logger = SingletonLogger().get()

class MainApp:
    def __init__(self):
        pub.subscribe(self.onClose, "meshtastic.connection.lost")
        pub.subscribe(self.onConnection, "meshtastic.connection.established")
        pub.subscribe(self.onReceivePacket, "meshtastic.receive")
        pub.subscribe(self.onReceiveText, "meshtastic.receive.text")
        
        ports = meshtastic.util.findPorts()
        if len(ports) <= 0: self.close()
        self.ports, port = ports, ports[0]
        self.client = SerialInterface(devPath=port)

    def onReceivePacket(self, packet, interface):
        logger.debug(f"Получен пакет: {packet}")

    def onReceiveText(self, packet, interface):
        logger.debug(f"Получено сообщение: {packet}")
    
    def onConnection(self, interface, topic=pub.AUTO_TOPIC):
        logger.info(f"Соединение установлено")

    def onClose(self, interface, topic=pub.AUTO_TOPIC):
        logger.warning(f"Соединение потерянно")
        self.close()

    def close(self):
        logger.warning(f"Закрытие программы")
        self.client.close()
        sys.exit(1)

async def main():
    app = MainApp()
    while True: await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.warning("Завершение программы пользователем.")
