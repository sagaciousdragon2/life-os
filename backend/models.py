from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Dict

class DailyEntry(BaseModel):
    """
    Input model exactly matching the Flutter Frontend JSON mapping.
    """
    date: str
    mood: int
    focus: int
    sleep_hours: float
    tasks_planned: str
    tasks_completed: str
    obstacles: str
    wins: str
    diet: str
    freeform: str
    photos_base64: List[str]

    model_config = ConfigDict(extra="ignore")

class CategoryItem(BaseModel):
    """
    Ollama-detected topic/category from freeform texts and images.
    """
    category: str
    content: str

class AIResponse(BaseModel):
    """
    Structured output forced from the local LLM.
    """
    updated_fields: Optional[Dict[str, str]] = {}
    new_categories: List[CategoryItem] = []
    daily_summary: str
    insight: str
    suggestion: str
