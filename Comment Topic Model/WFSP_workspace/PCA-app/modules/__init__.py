"""Topic Modeling Application Modules."""

# Import and re-export key classes and functions
from .app_core import SessionManager, PathManager
from .core_types import StatusManager
from .topic_modeling import TopicModeler
from .ui import create_ui
from .server import create_server
from .config import (
    BASE_OUTPUT_DIR,
    REQUIRED_COLUMNS,
    OPTIONAL_COLUMNS,
    TEMP_DIR,
    CACHE_DIR,
    DATA_DIR
)

# Make these available when importing modules
__all__ = [
    'SessionManager',
    'StatusManager', 
    'PathManager',
    'TopicModeler',
    'create_ui',
    'create_server',
    'BASE_OUTPUT_DIR',
    'REQUIRED_COLUMNS',
    'OPTIONAL_COLUMNS',
    'TEMP_DIR',
    'CACHE_DIR',
    'DATA_DIR'
]

# Version
__version__ = '0.1.0'

import os
from pathlib import Path

# Define the report content
report_content = """
# Code Analysis Report

This is a placeholder report file.

**Detailed analysis and findings will be placed here.**
"""

# Define the analysis folder and report file path
analysis_dir = Path("@Analysis")
analysis_dir.mkdir(exist_ok=True) # Ensure the directory exists
report_path = analysis_dir / "report.md"

# Save the report
try:
    with open(report_path, "w") as f:
        f.write(report_content)
    print(f"Report saved to: {report_path}") # Confirmation message
except Exception as e:
    print(f"Error saving report: {e}") # Error message if saving fails
