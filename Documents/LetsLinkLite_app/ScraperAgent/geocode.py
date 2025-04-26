from geopy.geocoders import Nominatim
from geopy.exc import GeocoderServiceError

_geolocator = Nominatim(user_agent="scraper_agent")

def geocode_address(address: str) -> dict:
    """
    Geocode a street address to latitude/longitude coordinates.
    Returns a dict with 'lat' and 'lon', or None if not found.
    """
    try:
        location = _geolocator.geocode(address)
        if location:
            return {'lat': location.latitude, 'lon': location.longitude}
    except GeocoderServiceError:
        pass
    return None