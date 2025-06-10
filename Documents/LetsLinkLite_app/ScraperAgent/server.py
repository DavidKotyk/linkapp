# Core dependencies
from fastapi import FastAPI, HTTPException
from dotenv import load_dotenv
import uvicorn
import os

# Load environment variables
load_dotenv()
from scraper_agent import gather_data
from typing import List
from models import ScrapedEvent

app = FastAPI(
    title="LetsLink Lite Facebook Events Scraper",
    description="API to scrape Facebook Events using a shared LetsLink account",
)

@app.get("/events", response_model=List[ScrapedEvent])
@app.get("/events/", response_model=List[ScrapedEvent])
async def get_events(city: str = "") -> list[ScrapedEvent]:
    """
    Scrape Eventbrite events for the given city and return a list of events.
    """
    try:
        events = await gather_data(city)
        return events
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))