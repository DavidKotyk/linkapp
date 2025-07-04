# FacebookScraper

A minimal Node.js and Playwright demo that proves headless browsing and scraping works.
This service ignores real Facebook events for now and scrapes example.com to return its page title.

## Prerequisites
- Node.js 18+ installed
- Internet connection

## Setup & Run Locally
```bash
cd facebook-scraper
npm install
# Install Playwright browsers
npx playwright install --with-deps

# Start the scraper service
npm start
```

The service will listen on port 8000 by default.

## Test
```bash
curl "http://localhost:8000/events?city=San%20Francisco"
```
Expected output:
```json
[
  {
    "site": "example.com",
    "title": "Example Domain",
    "city": "San Francisco"
  }
]
```

## Next Steps
- Replace `scrapeDemo()` in `index.js` with real Facebook event scraping logic using Playwright or Puppeteer.
- Update selectors, handle scrolling, and extract fields: title, date/time, location, description, link.
- Containerize with Docker for production or Cloud Run deployment.