import os
from core.database.base import DatabaseService
from core.database.file_db import FileDatabaseService
from core.database.postgres_db import PostgresDatabaseService

def get_db() -> DatabaseService:
    """Factory to get the configured database service."""
    db_type = os.environ.get("DATABASE_TYPE", "file")
    
    if db_type == "postgres":
        return PostgresDatabaseService()
    
    return FileDatabaseService()
