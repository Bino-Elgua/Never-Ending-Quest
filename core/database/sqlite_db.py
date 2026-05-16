import os
import sqlite3
import json
from typing import Dict, Any, List, Optional
from core.database.base import DatabaseService

class SQLiteDatabaseService(DatabaseService):
    """SQLite implementation of DatabaseService."""
    
    def __init__(self, db_path="neverendingquest.db"):
        self.db_path = db_path
        self._ensure_tables()

    def _get_conn(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _ensure_tables(self):
        with self._get_conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    session_id TEXT PRIMARY KEY,
                    party_tracker TEXT,
                    current_location TEXT,
                    campaign_data TEXT,
                    player_storage TEXT,
                    pacing_state TEXT,
                    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS conversation_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT,
                    history TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS campaign_summaries (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT,
                    module_name TEXT,
                    sequence INTEGER,
                    summary_data TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS characters (
                    session_id TEXT,
                    character_name TEXT,
                    char_data TEXT,
                    PRIMARY KEY (session_id, character_name)
                )
            """)

    def _ensure_session(self, session_id: str):
        with self._get_conn() as conn:
            conn.execute("INSERT OR IGNORE INTO sessions (session_id) VALUES (?)", (session_id,))
            conn.commit()

    def get_party_tracker(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT party_tracker FROM sessions WHERE session_id = ?", (session_id,)).fetchone()
            return json.loads(row['party_tracker']) if row and row['party_tracker'] else None

    def save_party_tracker(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("UPDATE sessions SET party_tracker = ?, last_updated = CURRENT_TIMESTAMP WHERE session_id = ?", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_character(self, session_id: str, character_name: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT char_data FROM characters WHERE session_id = ? AND character_name = ?", (session_id, character_name)).fetchone()
            return json.loads(row['char_data']) if row else None

    def save_character(self, session_id: str, character_name: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("""
                INSERT OR REPLACE INTO characters (session_id, character_name, char_data) 
                VALUES (?, ?, ?) 
            """, (session_id, character_name, json.dumps(data)))
            conn.commit()
            return True

    def get_current_location(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT current_location FROM sessions WHERE session_id = ?", (session_id,)).fetchone()
            return json.loads(row['current_location']) if row and row['current_location'] else None

    def save_current_location(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("UPDATE sessions SET current_location = ?, last_updated = CURRENT_TIMESTAMP WHERE session_id = ?", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_conversation_history(self, session_id: str) -> List[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT history FROM conversation_history WHERE session_id = ? ORDER BY created_at DESC LIMIT 1", (session_id,)).fetchone()
            return json.loads(row['history']) if row and row['history'] else []

    def save_conversation_history(self, session_id: str, history: List[Dict[str, Any]]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("INSERT INTO conversation_history (session_id, history) VALUES (?, ?)", (session_id, json.dumps(history)))
            conn.commit()
            return True

    def archive_conversation_history(self, session_id: str, module_name: str, sequence: int, history: List[Dict[str, Any]]) -> bool:
        # Note: SQLite implementation of campaign_archives is missing in Postgres version, I'll add a quick table
        with self._get_conn() as conn:
            conn.execute("CREATE TABLE IF NOT EXISTS campaign_archives (id INTEGER PRIMARY KEY, session_id TEXT, module_name TEXT, sequence INTEGER, archive_data TEXT)")
            conn.execute("INSERT INTO campaign_archives (session_id, module_name, sequence, archive_data) VALUES (?, ?, ?, ?)", (session_id, module_name, sequence, json.dumps(history)))
            conn.commit()
            return True

    def get_campaign_summaries(self, session_id: str, module_name: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_conn() as conn:
            if module_name:
                rows = conn.execute("SELECT summary_data FROM campaign_summaries WHERE session_id = ? AND module_name = ? ORDER BY sequence ASC", (session_id, module_name)).fetchall()
            else:
                rows = conn.execute("SELECT summary_data FROM campaign_summaries WHERE session_id = ? ORDER BY sequence ASC", (session_id,)).fetchall()
            return [json.loads(row['summary_data']) for row in rows]

    def save_campaign_summary(self, session_id: str, module_name: str, sequence: int, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("""
                INSERT OR IGNORE INTO campaign_summaries (session_id, module_name, sequence, summary_data) 
                VALUES (?, ?, ?, ?)
            """, (session_id, module_name, sequence, json.dumps(data)))
            conn.commit()
            return True

    def get_campaign_data(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT campaign_data FROM sessions WHERE session_id = ?", (session_id,)).fetchone()
            return json.loads(row['campaign_data']) if row and row['campaign_data'] else None

    def save_campaign_data(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("UPDATE sessions SET campaign_data = ?, last_updated = CURRENT_TIMESTAMP WHERE session_id = ?", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_player_storage(self, session_id: str) -> Dict[str, Any]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT player_storage FROM sessions WHERE session_id = ?", (session_id,)).fetchone()
            return json.loads(row['player_storage']) if row and row['player_storage'] else {"version": "1.0.0", "playerStorage": []}

    def save_player_storage(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("UPDATE sessions SET player_storage = ?, last_updated = CURRENT_TIMESTAMP WHERE session_id = ?", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_pacing_state(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            row = conn.execute("SELECT pacing_state FROM sessions WHERE session_id = ?", (session_id,)).fetchone()
            return json.loads(row['pacing_state']) if row and row['pacing_state'] else None

    def save_pacing_state(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            conn.execute("UPDATE sessions SET pacing_state = ?, last_updated = CURRENT_TIMESTAMP WHERE session_id = ?", (json.dumps(data), session_id))
            conn.commit()
            return True
