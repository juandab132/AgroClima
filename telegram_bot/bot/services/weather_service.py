import httpx
import json
import os

class WeatherService:
    BASE_URL = "https://api.open-meteo.com/v1/forecast"

    async def get_forecast(self, lat: float, lon: float):
        params = {
            "latitude": lat,
            "longitude": lon,
            "daily": "temperature_2m_min,temperature_2m_max,precipitation_probability_mean,windspeed_10m_max",
            "timezone": "America/Bogota",
            "forecast_days": 7
        }
        async with httpx.AsyncClient() as client:
            response = await client.get(self.BASE_URL, params=params)
            if response.status_code == 200:
                return response.json()
            return None

    def get_municipios(self):
        path = os.path.join(os.path.dirname(__file__), "..", "data", "municipios_narino.json")
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
