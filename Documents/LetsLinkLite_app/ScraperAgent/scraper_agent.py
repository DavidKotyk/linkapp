import os
import json
import requests
from dotenv import load_dotenv
from playwright.async_api import async_playwright
from browser_use import Agent, Browser, BrowserConfig
from browser_use.browser.context import BrowserContextConfig
from langchain_openai import ChatOpenAI
from controller import controller

load_dotenv()

async def scrape_yelp_city(page, city: str) -> list:
    """Scrape venue listings from Yelp for the given city."""
    url = f'https://www.yelp.com/search?find_desc=events&find_loc={city}'
    await page.goto(url)
    # TODO: parse dynamically loaded content
    # Placeholder: return empty list
    return []

async def scrape_eventbrite_city(page, city: str) -> list:
    """Scrape event listings from Eventbrite for the given city."""
    # Build Eventbrite city slug (e.g., "San Francisco" -> "san-francisco")
    city_slug = city.strip().lower().replace(' ', '-')
    url = f'https://www.eventbrite.com/d/{city_slug}/all-events/'
    # Navigate to the Eventbrite city page; dynamic content will load
    await page.goto(url)
    # Wait for event link elements to load
    # Wait for event link elements to be attached to the DOM
    try:
        await page.wait_for_selector('a.event-card-link', state='attached', timeout=10000)
    except:
        return []
    cards = await page.query_selector_all('a.event-card-link')
    data = []
    seen = set()
    for card in cards:
        href = await card.get_attribute('href') or ''
        if not href or href in seen:
            continue
        seen.add(href)
        # Event name from aria-label or link text
        # Extract location if available
        venue = await card.get_attribute('data-event-location')
        name = await card.get_attribute('aria-label') or (await card.inner_text())
        data.append({
            'source': 'Eventbrite',
            'name': name.strip(),
            'url': href,
            'date': None,
            'venue': venue.strip() if venue else None,
        })
    return data
 
async def scrape_eventbrite_details(page, event_url: str) -> dict:
    """Scrape full event details from an Eventbrite event page."""
    details = {"description": None, "venue": None}
    # Navigate to the event page
    await page.goto(event_url)
    # Extract event description
    try:
        # Description container with user-generated content
        await page.wait_for_selector('div.has-user-generated-content.event-description', state='attached', timeout=5000)
        desc_el = await page.query_selector('div.has-user-generated-content.event-description')
        if desc_el:
            details["description"] = (await desc_el.inner_text()).strip()
    except:
        pass
    # Extract venue/address
    try:
        # Eventbrite uses a div with class 'location-info__address' to display address
        venue_el = await page.query_selector('div.location-info__address')
        if venue_el:
            raw = (await venue_el.inner_text()).strip()
            # Split into non-empty lines and remove 'Show map'
            lines = [l.strip() for l in raw.splitlines() if l.strip() and not l.lower().startswith('show map')]
            # Pick the first line that looks like a street address (contains a digit)
            addr = None
            for l in lines:
                if any(ch.isdigit() for ch in l):
                    addr = l
                    break
            # Fallback to last meaningful line or raw text
            if not addr:
                addr = lines[-1] if lines else raw
            details["venue"] = addr
    except:
        pass
    return details
async def scrape_meetup_city(page, city: str) -> list:
    """Scrape upcoming events from Meetup for the given city."""
    # Meetup search URL for upcoming events
    url = f'https://www.meetup.com/find/events/?allMeetups=true&userFreeform={city}'
    await page.goto(url)
    try:
        await page.wait_for_selector('li.event-listing-container-li', timeout=10000)
    except:
        return []
    items = await page.query_selector_all('li.event-listing-container-li')
    data = []
    for it in items[:10]:
        # title
        h3 = await it.query_selector('h3')
        title = (await h3.inner_text()).strip() if h3 else None
        # link
        a = await it.query_selector('a')
        href = await a.get_attribute('href') if a else None
        # datetime
        time_el = await it.query_selector('time')
        date = await time_el.get_attribute('datetime') if time_el else None
        data.append({
            'source': 'Meetup',
            'name': title,
            'url': href,
            'date': date,
        })
    return data

def scrape_osm_parks(city: str) -> list:
    """Fetch parks near the city via OSM Nominatim API."""
    url = 'https://nominatim.openstreetmap.org/search'
    params = {'format': 'json', 'q': f'park {city}', 'limit': 10}
    resp = requests.get(url, params=params, headers={'User-Agent': 'scraper-agent/1.0'})
    if resp.status_code != 200:
        return []
    results = []
    for item in resp.json():
        results.append({
            'source': 'OSM',
            'name': item.get('display_name'),
            'lat': item.get('lat'),
            'lon': item.get('lon'),
        })
    return results

async def gather_data(city: str) -> list:
    """
    Scrape Eventbrite events for the given city, including full details.
    Returns a list of enriched event dicts.
    """
    # Geocode the city to get a default latitude/longitude for each event
    def geocode_city(query: str) -> tuple[str, str]:
        try:
            url = 'https://nominatim.openstreetmap.org/search'
            params = {'format': 'json', 'q': query, 'limit': 1}
            resp = requests.get(url, params=params, headers={'User-Agent': 'scraper-agent/1.0'})
            if resp.status_code == 200:
                data = resp.json()
                if data and isinstance(data, list):
                    lat = data[0].get('lat')
                    lon = data[0].get('lon')
                    if lat and lon:
                        return lat, lon
        except Exception:
            pass
        # Fallback coordinates (0,0) if geocoding fails
        return '0.0', '0.0'

    default_lat, default_lon = geocode_city(city)
    # Use Playwright to scrape Eventbrite listings and enrich with details
    events: list[dict] = []
    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page()
        # Scrape basic listings
        listings = await scrape_eventbrite_city(page, city)
        # Determine how many events to enrich with details
        limit = int(os.getenv("EVENTBRITE_DETAIL_LIMIT", "5"))
        for idx, listing in enumerate(listings):
            url = listing.get("url")
            # Fetch details for first N events
            if idx < limit and url:
                try:
                    details = await scrape_eventbrite_details(page, url)
                    listing.update(details)
                except Exception:
                    pass
            # Determine geocoded coordinates per event (by venue or fallback to city)
            venue = listing.get('venue')
            if venue:
                query = f"{venue}, {city}"
                lat, lon = geocode_city(query)
            else:
                lat, lon = default_lat, default_lon
            listing['lat'] = lat
            listing['lon'] = lon
            events.append(listing)
        await browser.close()
    return events

if __name__ == '__main__':
    import sys, asyncio
    city = sys.argv[1] if len(sys.argv) > 1 else ''
    events = asyncio.run(gather_data(city))
    print(json.dumps({"events": events}, indent=2))