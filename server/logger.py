import logging
import threading
import os

class SingletonLogger:
    _instance = None
    _lock = threading.Lock()
    ROOT_PATH = "./logs/pyroot.log"
    FILE_PATH = "./logs/server.log"

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None: 
                    cls._instance = super().__new__(cls)
                    cls._instance._init_logger()
        return cls._instance

    def _init_logger(self):
        self.clear()
        log_root_format = "%(asctime)s %(name)s [%(levelname)s] %(message)s"
        log_priv_format = "%(asctime)s  [%(levelname)s] %(message)s"
        date_format = "%d-%b-%y %H:%M:%S"

        logging.root.setLevel(logging.NOTSET)
        logging.basicConfig(
            level=logging.DEBUG,
            format=log_root_format,
            datefmt=date_format, force=True,
            handlers=[logging.FileHandler(self.ROOT_PATH)]
        )

        self.logger = logging.getLogger("SingletonLogger")
        self.logger.setLevel(logging.INFO)
        formatter = logging.Formatter(log_priv_format, datefmt=date_format)

        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        self.logger.addHandler(console_handler)

        if not any(isinstance(h, logging.FileHandler) \
                and h.baseFilename.endswith(self.FILE_PATH) \
                for h in self.logger.handlers):
            
            file_handler = logging.FileHandler(self.FILE_PATH)
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)

    def clear(self):
        try:
            os.remove(self.ROOT_PATH)
            self.logger.info("Logs 'root' removed") 
        except:
            pass

    def get(self):
        return self.logger
