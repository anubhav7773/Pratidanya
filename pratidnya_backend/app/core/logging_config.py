import sys
import logging

class RenderLogFormatter(logging.Formatter):
    """
    Format logs for high visibility in Render / CloudWatch consoles.
    Outputs structured human-readable logs with icons and clear metadata.
    """
    GREY = "\x1b[38;20m"
    GREEN = "\x1b[32;20m"
    YELLOW = "\x1b[33;20m"
    RED = "\x1b[31;20m"
    BOLD_RED = "\x1b[31;1m"
    RESET = "\x1b[0m"

    def format(self, record):
        log_fmt = "[RENDER ACTIVITY] [%(asctime)s] [%(levelname)s] %(message)s"
        formatter = logging.Formatter(log_fmt, datefmt="%Y-%m-%d %H:%M:%S")
        return formatter.format(record)

def setup_render_logger() -> logging.Logger:
    logger = logging.getLogger("pratidnya_activity")
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(RenderLogFormatter())
        logger.addHandler(handler)

    logger.propagate = False
    return logger

render_logger = setup_render_logger()
