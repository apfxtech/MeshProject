import requests
import json

response = requests.get("https://malla.meshworks.ru/api/locations?")
print(response.status_code)
with open("./api/locations.json", "w", encoding="utf-8") as json_file:
    data = json.loads(response.content)
    json.dump(data, json_file, indent=4, ensure_ascii=False)

response = requests.get("https://malla.meshworks.ru/api/analytics")
print(response.status_code)
with open("./api/analytics.json", "w", encoding="utf-8") as json_file:
    data = json.loads(response.content)
    json.dump(data, json_file, indent=4, ensure_ascii=False)