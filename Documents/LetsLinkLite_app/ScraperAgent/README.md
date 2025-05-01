# ScraperAgent

This directory provides a Python-based web scraping agent for gathering local event and venue data.

## Requirements
Install the dependencies using:
```
cd ScraperAgent
pip install -r requirements.txt
python -m spacy download en_core_web_sm
playwright install
```

## Usage
```
cd ScraperAgent
python scraper_agent.py "San Francisco"
```
This will output structured JSON containing scraped event and venue data.

## Structure
- `utils.py`: Proxy rotation, user-agent, and timing utilities.
- `geocode.py`: Geocoding using Nominatim (OpenStreetMap).
- `parser.py`: NLP parsing using spaCy for entity extraction.
- `scraper_agent.py`: Main orchestrator using Playwright to scrape various sources.
- `requirements.txt`: Python dependencies for the agent.

## Notes
- You must respect each site's Terms of Service.
- Configure `PROXIES` in `utils.py` to use your own proxy servers.
- Expand the `scrape_*` functions with actual parsing logic for each provider.
## Docker & Google Cloud Run

This agent can be containerized and deployed to Google Cloud Run for a fully-managed, autoscaling scraping service.

1. Build & push Docker image:
   ```bash
   cd ScraperAgent
   docker build -t gcr.io/<PROJECT-ID>/scraper-agent:latest .
   docker push gcr.io/<PROJECT-ID>/scraper-agent:latest
   ```

2. Deploy to Cloud Run:
   ```bash
   gcloud run deploy scraper-agent \
     --image gcr.io/<PROJECT-ID>/scraper-agent:latest \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --concurrency 1 \
     --port 8080
   ```

3. After deployment, your service URL will be printed. You can fetch events via:
   ```bash
   curl "https://<SERVICE-URL>/events?city=San Francisco"
   ```

Replace `<PROJECT-ID>` and `<SERVICE-URL>` with your GCP project ID and the URL shown by Cloud Run.