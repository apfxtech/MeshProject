import meshtastic
from pubsub import pub
import logging

logging.root.setLevel(logging.NOTSET)
logging.basicConfig(
    level="DEBUG",
    format="%(asctime)s %(name)s [%(levelname)s] %(message)s",
    datefmt='%d-%b-%y %H:%M:%S',
    force=True,
    handlers=[
        logging.FileHandler("server.log")
    ]
)

logger = logging.getLogger("main")
client = None

def onReceive(packet, client):
    logger.debug(f"Received: {packet}")

def onConnection(client, topic=pub.AUTO_TOPIC): 
    client.sendText("hello from python")

if __name__ == "__main__":
    serial_ports = meshtastic.util.findPorts()
    client = meshtastic.serial_client.Serialclient()
    pub.subscribe(onReceive, "meshtastic.receive")
    pub.subscribe(onConnection, "meshtastic.connection.established")

