from fastapi import FastAPI, HTTPException
from contextlib import asynccontextmanager
from models import DailyEntry, AIResponse
import analyze
import database
import uvicorn

# Lifecycle manager to handle startup/shutdown tasks
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Setup database on startup
    database.init_db()
    yield
    # Cleanup on shutdown (if needed)

app = FastAPI(
    title="Daily Life OS - AI Backend",
    description="Local FastAPI connected to Ollama for privacy-focused daily journaling analysis.",
    version="1.0.0",
    lifespan=lifespan
)

@app.get("/health")
async def health_check():
    """Simple health check endpoint."""
    return {"status": "ok", "ollama_available": analyze.is_ollama_ready()}

@app.post("/analyze", response_model=AIResponse)
async def analyze_entry(entry: DailyEntry):
    """
    Receives frontend journal data.
    1. Sends to local Ollama model for analysis.
    2. Returns structured JSON containing insights, suggestions, and deduced categories.
    """
    try:
        # Call the Ollama LLM
        result = await analyze.analyze_day(entry)
        
        # Save exact payload to local SQLite (backend sync)
        # (This mirrors the frontend DB and acts as the true backup/source)
        database.save_entry(entry, result)
        
        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.post("/transcribe")
async def transcribe_voice():
    """
    Stub endpoint for future voice transcription via local Whisper model.
    """
    return {"text": "This is a placeholder voice transcription. In a real scenario, this endpoint would receive audio bytes and run openai/whisper locally."}

if __name__ == "__main__":
    # Run the server on port 8000
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
