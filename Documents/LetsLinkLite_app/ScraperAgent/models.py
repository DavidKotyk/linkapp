from pydantic import BaseModel, HttpUrl
from typing import List, Optional

class ScrapedEvent(BaseModel):
    source: str
    name: str
    url: HttpUrl
    date: Optional[str] = None
    venue: Optional[str] = None
    description: Optional[str] = None
    # Geocoded latitude and longitude as strings
    lat: Optional[str] = None
    lon: Optional[str] = None

class ScrapedEventsResponse(BaseModel):
    events: List[ScrapedEvent]