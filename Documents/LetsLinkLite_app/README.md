# LetsLinkLite

## Overview
LetsLinkLite is a SwiftUI-based social events app that displays local events on a map, provides event details, and enables in-app chat and user profiles.

## Components
- iOS App (SwiftUI): Handles UI, navigation, map, chat, profiles, and local sample data injection.
- ScraperAgent (Python): Headless browser scripts for scraping live event and venue data from web sources, with geocoding and NLP parsing.

## Getting Started
### iOS App
1. Open `LetsLinkLite/LetsLinkLite.xcodeproj` in Xcode (iOS 17+).
2. Build & Run on simulator or device.
3. Explore the Events map, create events, chat, and profiles.

### ScraperAgent
```bash
cd ScraperAgent
pip install -r requirements.txt
python -m spacy download en_core_web_sm
playwright install
python scraper_agent.py "San Francisco"
```

## Project Status
- Done: Cleaned project structure, map & chat UI, profile UI, sample data loader, scraping agent skeleton.
- Next: Extend scrapers for real sites, integrate live data into the app, implement missing flows (report, follow, join), add persistence and real messaging.

## Directory Structure
```
README.md
LetsLinkLite/        # iOS app Xcode project
ScraperAgent/        # Python scraping agent
```
## Developer Onboarding & Resuming Work

If you are starting or resuming development, follow these steps from the project root (`LetsLinkLite_app`):

1. Clone the repository (if not already):
   ```bash
   git clone git@github.com:DavidKotyk/linkapp.git LetsLinkLite_app
   cd LetsLinkLite_app
   ```

2. iOS App Setup:
   ```bash
   cd LetsLinkLite/LetsLinkLite.xcodeproj
   open .
   # Build & run in Xcode (iOS 17+)
   ```

3. ScraperAgent Setup:
   ```bash
   cd ScraperAgent
   # Install Python deps and Playwright
   pip install -r requirements.txt
   python -m spacy download en_core_web_sm
   playwright install --with-deps
   ```

4. Local Testing:
   ```bash
   # Run scraper agent against a city
   python scraper_agent.py "San Francisco"
   # Or start the FastAPI server
   uvicorn server:app --host 0.0.0.0 --port 8000
   curl "http://localhost:8000/events?city=San%20Francisco"
   ```

5. Deployment (Cloud Run):
   See `ScraperAgent/Dockerfile` and README in `ScraperAgent/` for Docker build and Google Cloud Run deployment instructions.

All paths are relative to the root directory of the project (`LetsLinkLite_app`).