import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, Any, List, Optional
from core.database.base import DatabaseService

class PostgresDatabaseService(DatabaseService):
    """PostgreSQL implementation of DatabaseService."""
    
    def __init__(self):
        self.conn_str = os.environ.get("DATABASE_URL", "dbname=neq user=postgres password=postgres host=localhost")
        self._ensure_tables()

    def _get_conn(self):
        return psycopg2.connect(self.conn_str, cursor_factory=RealDictCursor)

    def _ensure_tables(self):
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                # Sessions table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS sessions (
                        session_id TEXT PRIMARY KEY,
                        party_tracker JSONB,
                        current_location JSONB,
                        campaign_data JSONB,
                        player_storage JSONB,
                        pacing_state JSONB,
                        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                # Conversation history table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS conversation_history (
                        id SERIAL PRIMARY KEY,
                        session_id TEXT REFERENCES sessions(session_id),
                        history JSONB,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                # Campaign summaries table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS campaign_summaries (
                        id SERIAL PRIMARY KEY,
                        session_id TEXT REFERENCES sessions(session_id),
                        module_name TEXT,
                        sequence INTEGER,
                        summary_data JSONB,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                # Campaign archives table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS campaign_archives (
                        id SERIAL PRIMARY KEY,
                        session_id TEXT REFERENCES sessions(session_id),
                        module_name TEXT,
                        sequence INTEGER,
                        archive_data JSONB,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                # Characters table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS characters (
                        session_id TEXT REFERENCES sessions(session_id),
                        character_name TEXT,
                        char_data JSONB,
                        PRIMARY KEY (session_id, character_name)
                    )
                """)
            conn.commit()

    def _ensure_session(self, session_id: str):
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO sessions (session_id) VALUES (%s) ON CONFLICT DO NOTHING", (session_id,))
            conn.commit()

    def get_party_tracker(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT party_tracker FROM sessions WHERE session_id = %s", (session_id,))
                row = cur.fetchone()
                return row['party_tracker'] if row else None

    def save_party_tracker(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE sessions SET party_tracker = %s, last_updated = CURRENT_TIMESTAMP WHERE session_id = %s", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_character(self, session_id: str, character_name: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT char_data FROM characters WHERE session_id = %s AND character_name = %s", (session_id, character_name))
                row = cur.fetchone()
                return row['char_data'] if row else None

    def save_character(self, session_id: str, character_name: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO characters (session_id, character_name, char_data) 
                    VALUES (%s, %s, %s) 
                    ON CONFLICT (session_id, character_name) DO UPDATE SET char_data = EXCLUDED.char_data
                """, (session_id, character_name, json.dumps(data)))
            conn.commit()
            return True

    def get_current_location(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT current_location FROM sessions WHERE session_id = %s", (session_id,))
                row = cur.fetchone()
                return row['current_location'] if row else None

    def save_current_location(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE sessions SET current_location = %s, last_updated = CURRENT_TIMESTAMP WHERE session_id = %s", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_conversation_history(self, session_id: str) -> List[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT history FROM conversation_history WHERE session_id = %s ORDER BY created_at DESC LIMIT 1", (session_id,))
                row = cur.fetchone()
                return row['history'] if row else []

    def save_conversation_history(self, session_id: str, history: List[Dict[str, Any]]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO conversation_history (session_id, history) VALUES (%s, %s)", (session_id, json.dumps(history)))
            conn.commit()
            return True

    def archive_conversation_history(self, session_id: str, module_name: str, sequence: int, history: List[Dict[str, Any]]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO campaign_archives (session_id, module_name, sequence, archive_data) 
                    VALUES (%s, %s, %s, %s)
                """, (session_id, module_name, sequence, json.dumps(history)))
            conn.commit()
            return True

    def get_campaign_summaries(self, session_id: str, module_name: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                if module_name:
                    cur.execute("SELECT summary_data FROM campaign_summaries WHERE session_id = %s AND module_name = %s ORDER BY sequence ASC", (session_id, module_name))
                else:
                    cur.execute("SELECT summary_data FROM campaign_summaries WHERE session_id = %s ORDER BY sequence ASC", (session_id,))
                rows = cur.fetchall()
                return [row['summary_data'] for row in rows]

    def save_campaign_summary(self, session_id: str, module_name: str, sequence: int, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO campaign_summaries (session_id, module_name, sequence, summary_data) 
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (session_id, module_name, sequence, json.dumps(data)))
            conn.commit()
            return True

    def get_campaign_data(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT campaign_data FROM sessions WHERE session_id = %s", (session_id,))
                row = cur.fetchone()
                return row['campaign_data'] if row else None

    def save_campaign_data(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE sessions SET campaign_data = %s, last_updated = CURRENT_TIMESTAMP WHERE session_id = %s", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_player_storage(self, session_id: str) -> Dict[str, Any]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT player_storage FROM sessions WHERE session_id = %s", (session_id,))
                row = cur.fetchone()
                return row['player_storage'] if row and row['player_storage'] else {"version": "1.0.0", "playerStorage": []}

    def save_player_storage(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE sessions SET player_storage = %s, last_updated = CURRENT_TIMESTAMP WHERE session_id = %s", (json.dumps(data), session_id))
            conn.commit()
            return True

    def get_pacing_state(self, session_id: str) -> Optional[Dict[str, Any]]:
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT pacing_state FROM sessions WHERE session_id = %s", (session_id,))
                row = cur.fetchone()
                return row['pacing_state'] if row else None

    def save_pacing_state(self, session_id: str, data: Dict[str, Any]) -> bool:
        self._ensure_session(session_id)
        with self._get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE sessions SET pacing_state = %s, last_updated = CURRENT_TIMESTAMP WHERE session_id = %s", (json.dumps(data), session_id))
            conn.commit()
            return True
