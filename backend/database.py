import os
import sqlite3
import json
from models import DailyEntry, AIResponse

DB_FILE = "backend_daily_life_os.db"

def init_db():
    """
    Initializes a synchronized local backend database.
    (This is a safety shadow/backup of the Flutter frontend DB. 
    It holds raw data AND the AI analysis).
    """
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Mirroring Flutter schema
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS entries (
            date          TEXT PRIMARY KEY,
            mood          INTEGER,
            focus         INTEGER,
            sleep_hours   REAL,
            tasks_planned TEXT,
            tasks_completed TEXT,
            obstacles     TEXT,
            wins          TEXT,
            diet          TEXT,
            freeform      TEXT,
            photos_base64 TEXT,  -- JSON string of base64
            
            -- AI Filled
            daily_summary TEXT,
            insight       TEXT,
            suggestion    TEXT,
            new_categories TEXT, -- JSON structure
            updated_fields TEXT, -- JSON mapping changes (for audit)
            
            created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def save_entry(entry: DailyEntry, ai_resp: AIResponse):
    """
    Upserts a single journal entry linked to its AI output.
    """
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Data prep
    date = entry.date
    mood = entry.mood
    focus = entry.focus
    sleep_h = entry.sleep_hours
    plan = entry.tasks_planned
    done = entry.tasks_completed
    obs = entry.obstacles
    win = entry.wins
    diet = entry.diet
    free = entry.freeform
    photos = json.dumps(entry.photos_base64)

    # AI result prep
    summary = ai_resp.daily_summary
    insight = ai_resp.insight
    sug = ai_resp.suggestion
    cats = json.dumps([c.model_dump() for c in ai_resp.new_categories])
    upds = json.dumps(ai_resp.updated_fields)

    # Upsert pattern for sqlite
    cursor.execute('''
        INSERT INTO entries (date, mood, focus, sleep_hours, tasks_planned, tasks_completed, obstacles, wins, diet, freeform, photos_base64, daily_summary, insight, suggestion, new_categories, updated_fields)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(date) DO UPDATE SET
            mood=excluded.mood,
            focus=excluded.focus,
            sleep_hours=excluded.sleep_hours,
            tasks_planned=excluded.tasks_planned,
            tasks_completed=excluded.tasks_completed,
            obstacles=excluded.obstacles,
            wins=excluded.wins,
            diet=excluded.diet,
            freeform=excluded.freeform,
            photos_base64=excluded.photos_base64,
            daily_summary=excluded.daily_summary,
            insight=excluded.insight,
            suggestion=excluded.suggestion,
            new_categories=excluded.new_categories,
            updated_fields=excluded.updated_fields,
            created_at=CURRENT_TIMESTAMP
    ''', (date, mood, focus, sleep_h, plan, done, obs, win, diet, free, photos, summary, insight, sug, cats, upds))

    conn.commit()
    conn.close()
