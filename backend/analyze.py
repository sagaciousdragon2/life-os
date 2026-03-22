import json
import httpx
from pydantic import ValidationError
from models import DailyEntry, AIResponse

# Configure Ollama endpoint
# Assuming Ollama is running locally on default port 11434
# For vision tests (e.g. photos), you'd need a multimodal model like llava or qwen2.5-vl:3b
OLLAMA_API_URL = "http://localhost:11434/api/generate"
# Fallback text model if no multimodal is available, or use a general instruction model
MODEL_NAME = "phi4:mini"

SYSTEM_PROMPT = """You are my brutally honest personal life analyst.
Take this raw daily entry and return ONLY valid JSON. 

Rules:
- Fill missing or unwritten structured fields intelligently from the freeform brain dump or photos (if any text/context was passed). Make educated guesses if a user mentions diet in the freeform field!
- Extract new_categories: array of {category: str, content: str} representing detected themes (e.g. "Emotional State", "Dreams", "Work Anxiety").
- Provide a daily_summary: 1 concise sentence summarizing the day.
- Provide an insight: 1 pattern, behavioral observation, or trend.
- Provide a suggestion: 1 tiny, actionable tip for tomorrow.

Output EXACT JSON structure matching this schema:
{
  "updated_fields": {
    "diet": "extracted food string if missing",
    "tasks_completed": "found tasks in freeform",
    ...
  },
  "new_categories": [
    {"category": "Theme", "content": "Explanation"}
  ],
  "daily_summary": "1 sentence.",
  "insight": "1 behavior pattern.",
  "suggestion": "1 tip."
}
Only output the raw JSON object. Do not include markdown formatting like ```json.
"""

def is_ollama_ready() -> bool:
    """Check if local Ollama daemon is running."""
    try:
        res = httpx.get("http://localhost:11434/")
        return "Ollama is running" in res.text
    except Exception:
        return False

async def analyze_day(entry: DailyEntry) -> AIResponse:
    """
    Calls locally hosted Ollama instance to analyze the day.
    """
    
    # Strip base64 photos from prompt payload to avoid blowing up the context window for text models.
    # If using LLaVA/qwen2.5-vl, you'd format them into Ollama's "images" payload field.
    photos = entry.photos_base64
    entry.photos_base64 = []  
    
    user_prompt = f"Day Context:\n{entry.model_dump_json(indent=2)}"

    payload = {
        "model": MODEL_NAME,
        "prompt": user_prompt,
        "system": SYSTEM_PROMPT,
        "stream": False,
        "format": "json", # Modern Ollama supports JSON mode!
    }

    # Add vision data if available
    if photos:
        payload["images"] = photos

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(OLLAMA_API_URL, json=payload)
            resp.raise_for_status()
            
            # The full response
            ollama_dict = resp.json()
            response_text = ollama_dict.get("response", "")
            
            # Parse strictly as expected JSON
            parsed_json = json.loads(response_text)
            
            # Validate through Pydantic
            ai_output = AIResponse(**parsed_json)
            return ai_output
            
    except Exception as e:
        print(f"Ollama inference error: {e}")
        # Return fallback stub if Ollama is unavailable or failed to parse
        return AIResponse(
            updated_fields={},
            new_categories=[{"category": "System", "content": "Local AI unavailable or failed to parse."}],
            daily_summary="Could not generate summary due to local AI error.",
            insight="Make sure Ollama is running and the model is downloaded run `ollama run phi4:mini`.",
            suggestion="Start the local Ollama service to get insights."
        )

