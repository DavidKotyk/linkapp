import asyncio
import json
import logging
import requests
import os
from playwright.async_api import async_playwright

from utils import random_delay, get_random_ua, rotate_proxy
from parser import parse_event_description
from geocode import geocode_address

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def scrape_yelp_city(page, city: str) -> list:
    """Scrape venue listings from Yelp for the given city."""
    url = f'https://www.yelp.com/search?find_desc=events&find_loc={city}'
    await page.goto(url)
    await random_delay()
    # TODO: parse dynamically loaded content
    # Placeholder: return empty list
    return []

async def scrape_eventbrite_city(page, city: str) -> list:
    """Scrape event listings from Eventbrite for the given city."""
    # Use all events listing for the city
    url = f'https://www.eventbrite.com/d/{city}/all-events/'
    await page.goto(url)
    await random_delay()
    # Wait for event cards to load
    try:
        await page.wait_for_selector(
            'div.eds-event-card-content__primary-content a.eds-media-card-content__action-link',
            timeout=10000
        )
    except:
        return []
    cards = await page.query_selector_all(
        'div.eds-event-card-content__primary-content a.eds-media-card-content__action-link'
    )
    data = []
    for card in cards:
        name = (await card.inner_text()).strip()
        href = await card.get_attribute('href')
        # Attempt to extract date/time within the same card
        parent = await card.evaluate_handle('el => el.closest("div.eds-event-card-content")')
        date = None
        try:
            date_el = await parent.query_selector('div.eds-text-bs--fixed')
            if date_el:
                date = (await date_el.inner_text()).strip()
        except:
            pass
        data.append({
            'source': 'Eventbrite',
            'name': name,
            'url': href,
            'date': date,
        })
    return data
async def scrape_meetup_city(page, city: str) -> list:
    """Scrape upcoming events from Meetup for the given city."""
    # Meetup search URL for upcoming events
    url = f'https://www.meetup.com/find/events/?allMeetups=true&userFreeform={city}'
    await page.goto(url)
    await random_delay()
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
    """Main entry point: gather and return combined structured data from multiple sources."""
    # Check for simplified mode: only fetch OSM parks (bypass Playwright)
    if os.getenv('SIMPLIFIED_AGENT', 'false').lower() in ('true', '1', 'yes'):
        results = []
        try:
            osm_data = scrape_osm_parks(city)
            results.extend(osm_data)
        except Exception as e:
            logger.error(f"Simplified OSM scrape failed: {e}")
        return results
    
    results = []
    # Launch browser-based scrapers
    try:
        async with async_playwright() as pw:
            browser = await pw.chromium.launch(headless=True)
            # Setup context with random UA and optional proxy
            ua = get_random_ua()
            proxy_cfg = rotate_proxy()
            if proxy_cfg:
                context = await browser.new_context(user_agent=ua, proxy=proxy_cfg)
            else:
                context = await browser.new_context(user_agent=ua)
            page = await context.new_page()
            # Yelp
            try:
                yelp_data = await scrape_yelp_city(page, city)
                results.extend(yelp_data)
            except Exception as e:
                logger.error(f"Yelp scrape failed: {e}")
            # Eventbrite
            try:
                eb_data = await scrape_eventbrite_city(page, city)
                results.extend(eb_data)
            except Exception as e:
                logger.error(f"Eventbrite scrape failed: {e}")
            # Meetup
            try:
                meet_data = await scrape_meetup_city(page, city)
                results.extend(meet_data)
            except Exception as e:
                logger.error(f"Meetup scrape failed: {e}")
            await browser.close()
    except Exception as e:
        logger.error(f"Browser scrapers failed: {e}")
    # Fetch nearby parks via OSM Nominatim as fallback real data
    try:
        osm_data = scrape_osm_parks(city)
        results.extend(osm_data)
    except Exception as e:
        logger.error(f"OSM parks fetch failed: {e}")
    # Geocode and NLP parse for enriched fields
    for item in results:
        if 'address' in item:
            try:
                coords = geocode_address(item['address'])
                item['coordinates'] = coords
            except Exception as e:
                logger.error(f"Geocode failed: {e}")
        if 'description' in item:
            try:
                item['entities'] = parse_event_description(item['description'])
            except Exception as e:
                logger.error(f"Description parse failed: {e}")
    # TODO: normalize, dedupe, filter by relevance/distance
    return results

if __name__ == '__main__':
    import sys
    city = sys.argv[1] if len(sys.argv) > 1 else 'San Francisco'
    data = asyncio.run(gather_data(city))
    print(json.dumps(data, indent=2))