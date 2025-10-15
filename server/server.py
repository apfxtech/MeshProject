import asyncio
import meshtastic
from meshtastic.serial_interface import SerialInterface
from pubsub import pub
import logging
import sys

logging.root.setLevel(logging.NOTSET)
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s %(name)s [%(levelname)s] %(message)s",
    datefmt='%d-%b-%y %H:%M:%S',
    force=True,
    handlers=[logging.FileHandler("server.log")]
)

logger = logging.getLogger("main")

class MainApp:
    def __init__(self):
        pub.subscribe(self.onClose, "meshtastic.connection.lost")
        pub.subscribe(self.onConnection, "meshtastic.connection.established")
        pub.subscribe(self.onReceivePacket, "meshtastic.receive")
        pub.subscribe(self.onReceiveText, "meshtastic.receive.text")
        
        ports = meshtastic.util.findPorts()
        if ports <= 0: self.close()
        self.ports, port = ports, ports[0]
        self.client = SerialInterface(devPath=port)

    def onReceivePacket(self, packet, interface):
        logger.debug(f"Получен пакет: {packet}")

    def onReceiveText(self, packet, interface):
        logger.debug(f"Получено сообщение: {packet}")
    
    def onConnection(self, client, topic=pub.AUTO_TOPIC):
        logger.info(f"Соединение установлено")

    def onClose(self, client, topic=pub.AUTO_TOPIC):
        logger.warning(f"Соединение потерянно")
        self.close()

    def close(self):
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
