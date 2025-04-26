import random
import asyncio
from fake_useragent import UserAgent

# Example proxy list; replace with your own proxy endpoints
PROXIES = [
    # 'http://username:password@proxy1:port',
    # 'http://username:password@proxy2:port',
]

def get_random_ua() -> str:
    """
    Return a random User-Agent string to help avoid blocks.
    """
    ua = UserAgent()
    return ua.random

def rotate_proxy() -> dict:
    """
    Return a proxy configuration dict for Playwright.
    """
    proxy_url = random.choice(PROXIES) if PROXIES else None
    return { 'server': proxy_url } if proxy_url else {}

async def random_delay(min_delay: float = 1.0, max_delay: float = 3.0) -> None:
    """
    Async sleep for a random duration between min_delay and max_delay.
    """
    await asyncio.sleep(random.uniform(min_delay, max_delay))