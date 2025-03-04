from dotenv import load_dotenv
import os
import requests
from typing import List, Callable, Dict, Any, Optional

# Load environment variables from .env file
load_dotenv()

# Load API keys from environment variables
api_key = os.getenv("ONE_WEATHER_MAP_KEY")
geo_key = os.getenv("GEOCODING_KEY")

def get_current_weather(lat: float, lon: float, units: str = "metric") -> Optional[Dict[str, Any]]:
    """
    Fetch current weather data from OpenWeatherMap API for the specified latitude and longitude.

    **Endpoint:**
    ```
    GET /data/3.0/onecall
    ```

    **Parameters:**
    - **lat** (`number`, required): Latitude in decimal degrees. Must be between -90 and 90.
    - **lon** (`number`, required): Longitude in decimal degrees. Must be between -180 and 180.
    - **units** (`string`, optional): Units of measurement. Available values: `standard`, `metric`, `imperial`. Default is `standard`.

    **Returns:**
    - `Dict[str, Any]`: A dictionary containing current weather data and alerts.
    - `None`: If the API request fails or no data is returned.

    **Example Usage:**
    ```python
    weather_data = get_current_weather(40.7128, -74.0060, units="metric")
    if weather_data:
        print(f"Temperature: {weather_data['temp']}°C")
        if 'weather' in weather_data:
            for weather in weather_data['weather']:
                print(f"Weather: {weather['description']}")
        if 'alerts' in weather_data:
            for alert in weather_data['alerts']:
                print(f"Alert: {alert['event']} - {alert['description']}")
    else:
        print("Weather data not available.")
    """
    url = "https://api.openweathermap.org/data/3.0/onecall"
    params = {
        'lat': lat,
        'lon': lon,
        'units': units,
        'exclude': 'minutely,hourly,daily,alerts',
        'appid': api_key  # Use the API key
    }
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print(f"Failed to fetch weather data: {response.status_code} {response.text}")
        return None
    return response.json().get("current", {})

def get_lat_lon(location: str) -> Optional[Dict[str, Any]]:
    """
    Get latitude and longitude for a given location using the OpenWeatherMap Geocoding API.

    **Endpoint:**
    ```
    GET /geo/1.0/direct
    ```

    **Parameters:**
    - **q** (`string`, required): Location name (e.g., "New York").
    - **limit** (`integer`, optional): Number of results to return. Default is 1.
    - **appid** (`string`, required): Your OpenWeatherMap API key.

    **Returns:**
    - `Dict[str, Any]`: A dictionary containing latitude, longitude, name, and country of the location.
    - `None`: If the API request fails or no data is returned.

    **Example Usage:**
    ```python
    location_data = get_lat_lon("London")
    if location_data:
        print(f"Latitude: {location_data['lat']}, Longitude: {location_data['lon']}")
    else:
        print("Location data not available.")
    """
    url = "http://api.openweathermap.org/geo/1.0/direct"
    params = {
        'q': location,
        'limit': 1,
        'appid': api_key  # Use the API key
    }
    response = requests.get(url, params=params)
    data = response.json()

    if response.status_code != 200 or not data:
        print(f"Could not get latitude and longitude for location: {location}")
        return None
    else:
        return {
            'lat': data[0]['lat'],
            'lon': data[0]['lon'],
            'name': data[0]['name'],
            'country': data[0]['country']
        }

# List of functions to be used by FunctionTool
weather_functions: List[Callable] = [get_current_weather, get_lat_lon]

if __name__ == "__main__":
    # Test the functions
    geo_data = get_lat_lon("New York")
    print(geo_data)
    if geo_data:
        weather_data = get_current_weather(geo_data['lat'], geo_data['lon'])
        print(weather_data)