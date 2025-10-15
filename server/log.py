import logging
import threading
import os

class SingletonLogger:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        """Создаёт только один экземпляр логгера."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None: 
                    cls._instance = super().__new__(cls)
                    cls._instance._init_logger()
        return cls._instance

    def _init_logger(self):
        """Первичная настройка логирования (только при первом вызове)."""
        log_root_format = "%(asctime)s %(name)s [%(levelname)s] %(message)s"
        log_priv_format = "%(asctime)s  [%(levelname)s] %(message)s"
        date_format = "%d-%b-%y %H:%M:%S"

        logging.root.setLevel(logging.NOTSET)
        logging.basicConfig(
            level=logging.DEBUG,
            format=log_root_format,
            datefmt=date_format, force=True,
            handlers=[logging.FileHandler("root.log")]
        )

        self.logger = logging.getLogger("public")
        self.logger.setLevel(logging.INFO)
        formatter = logging.Formatter(log_priv_format, datefmt=date_format)

        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        self.logger.addHandler(console_handler)

        if not any(isinstance(h, logging.FileHandler) \
                and h.baseFilename.endswith("server.log") \
                for h in self.logger.handlers):
            
            file_handler = logging.FileHandler("server.log")
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)

    def clear(self):
        os.remove("./root.log")
        self.logger.info("Logs 'root' removed")

    def get(self):
        return self.logger
