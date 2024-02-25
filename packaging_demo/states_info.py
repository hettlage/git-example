import json
from pathlib import Path
from typing import List

THIS_DIR = Path(__file__).parent
CITIES_JSON_PATH = THIS_DIR / "cities.json"

def is_city_capital_of_state(city: str, state: str) -> bool:
    cities_json = CITIES_JSON_PATH.read_text()
    cities: List[dict] = json.loads(cities_json)
    matching_cities: List[dict] = [city for city in cities if city["city"]]
    if len(matching_cities) == 0:
        return False
    matched_city = matching_cities[0]
    return matched_city["state"] == state

if __name__ == "__main__":
    print(is_city_capital_of_state(city="Montgomery", state="Alabama"))
