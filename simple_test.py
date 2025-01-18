import requests
import base64
import json

try:
    with open("./sweat-gemini/buckedup.webp", "rb") as f:
        image_bytes = f.read()
        image_base64 = base64.b64encode(image_bytes).decode()
        
        response = requests.post(
            "https://sweat-gemini.unleashai-inquiries.workers.dev/",
            json={
                "image": image_base64
            },
            headers={"Content-Type": "application/json"}
        )
        
    if response.status_code == 200:
        result = response.json()
        print("Success! Analysis:")
        print(json.dumps(result, indent=2))
    else:
        print(f"Error {response.status_code}:")
        print(response.text)
        
except Exception as e:
    print(f"Error: {e}") 