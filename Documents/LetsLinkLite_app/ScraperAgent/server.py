from fastapi import FastAPI, HTTPException
import uvicorn

from scraper_agent import gather_data

app = FastAPI(
    title="LetsLinkLite Scraper API",
    description="API endpoint to fetch local events and venues",
)

@app.get("/events", summary="Get events for a city")
@app.get("/events/", summary="Get events for a city")
async def get_events(city: str):
    """
    Fetch events near the specified city.
    """
    try:
        data = await gather_data(city)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)