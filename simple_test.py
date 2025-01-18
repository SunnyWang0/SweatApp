import requests, base64
with open("./sweat-gemini/buckedup.webp", "rb") as f:
    response = requests.post(
        "https://sweat-gemini.unleashai-inquiries.workers.dev/",
        json={"image": base64.b64encode(f.read()).decode()}
    )
print(response.json()) 