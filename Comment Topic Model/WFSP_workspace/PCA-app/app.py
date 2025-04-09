from __future__ import annotations

import logging
import sys
import os
from pathlib import Path
from typing import Callable
import shiny as sh
from shiny import App, Inputs, Outputs, Session, ui, reactive
from starlette.staticfiles import StaticFiles
import shinyswatch

# Import from modules package
from modules import (
    SessionManager, 
    create_ui,
    create_server,
    BASE_OUTPUT_DIR
)

# Set environment variables
os.environ["SHINY_NO_RELOAD"] = "1"  # Disable automatic reloading
os.environ["WATCHFILES_FORCE_POLLING"] = "0"  # Disable file system polling
os.environ["SHINY_LOG_LEVEL"] = "WARNING"  # Set logging level
os.environ["SHINY_DEV_MODE"] = "0"  # Disable development mode
os.environ["SHINY_RELOAD_THRESHOLD"] = "999999"  # Set reload threshold
os.environ["WATCHFILES_NO_WATCH_DIRS"] = "*"  # Disable directory watching

# Disable file watching
os.environ["SHINY_DISABLE_RELOAD"] = "1"
os.environ["WATCHFILES_DISABLE"] = "1"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('app.log')
    ]
)

logger = logging.getLogger(__name__)

# Suppress verbose loggers
mpl_logger = logging.getLogger('matplotlib.font_manager')
mpl_logger.setLevel(logging.ERROR)
logging.getLogger('umap').setLevel(logging.WARNING)
logging.getLogger('numba').setLevel(logging.WARNING)
logging.getLogger('sentence_transformers').setLevel(logging.WARNING)
logging.getLogger('bertopic').setLevel(logging.WARNING)
logging.getLogger('watchfiles').setLevel(logging.ERROR)

# Initialize application session manager
session_manager = SessionManager(BASE_OUTPUT_DIR)

def server(session_manager: SessionManager) -> Callable[[Inputs, Outputs, Session], None]:
    """Create server function with theme picker and session management.
    
    Args:
        session_manager: Session manager instance for handling file and state management
        
    Returns:
        Server function for Shiny application
    """
    def server(input: Inputs, output: Outputs, session: Session) -> None:
        logger.info(f"New session started: {session.id}")
        shinyswatch.theme_picker_server()
        try:
            create_server(session_manager)(input, output, session)
        except sh.types.SilentException:
            logger.warning("SilentException encountered and handled.")
    return server

def create_app(session_manager: SessionManager) -> sh.App:
    """Create the Shiny application."""
    return sh.App(
        ui=create_ui(),
        server=server(session_manager)
    )

# Create the app instance 
app = create_app(session_manager)

# Development server configuration
if __name__ == "__main__":
    from shiny import run_app
    import warnings
    
    # Suppress watchfiles warnings
    warnings.filterwarnings("ignore", category=UserWarning, module="watchfiles")
    
    logger.info("Starting server with reload completely disabled")
    
    run_app(
        app,
        reload=False,
        launch_browser=False,
        port=8000,
        host="localhost",
        autoreload_warning=False,
        _dev_mode=False,
        reload_mount=False,
        reload_dirs=None,
    )