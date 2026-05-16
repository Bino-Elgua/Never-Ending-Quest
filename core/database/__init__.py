import os
from core.database.base import DatabaseService
from core.database.file_db import FileDatabaseService
from core.database.sqlite_db import SQLiteDatabaseService

def get_db() -> DatabaseService:
    """Factory to get the configured database service."""
    db_type = os.environ.get("DATABASE_TYPE", "sqlite")
    
    if db_type == "sqlite":
        return SQLiteDatabaseService()
    
    return FileDatabaseService()
