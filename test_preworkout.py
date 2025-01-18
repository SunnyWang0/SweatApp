import requests
import base64
import json
from pathlib import Path

def analyze_preworkout_image(image_path):
    # Read the image file and convert to base64
    with open(image_path, 'rb') as image_file:
        image_data = base64.b64encode(image_file.read()).decode('utf-8')
    
    # API endpoint
    url = 'https://sweat-gemini.unleashai-inquiries.workers.dev/'
    
    # Prepare the request
    payload = {
        'image': image_data
    }
    
    # Send POST request
    response = requests.post(url, json=payload)
    
    # Check if request was successful
    response.raise_for_status()
    
    # Parse and return the JSON response
    return response.json()

def print_analysis(analysis):
    print("\n=== Preworkout Analysis ===\n")
    
    print("Ingredients:")
    for ingredient in analysis['ingredients']:
        print(f"\n• {ingredient['name']} ({ingredient['quantity']})")
        for effect in ingredient['effects']:
            print(f"  - {effect}")
    
    print("\nQuality Ratings (out of 100):")
    for quality, rating in analysis['qualities'].items():
        print(f"• {quality.title()}: {rating}")

if __name__ == "__main__":
    # Replace with your image path
    image_path = "./sweat-gemini/buckedup.webp"
    
    if not Path(image_path).exists():
        print(f"Error: Image file '{image_path}' not found.")
        print("Please update the image_path variable with the correct path to your WebP image.")
        exit(1)
    
    try:
        analysis = analyze_preworkout_image(image_path)
        print_analysis(analysis)
    except requests.exceptions.RequestException as e:
        print(f"Error making request: {e}")
    except json.JSONDecodeError:
        print("Error: Unable to parse response from server")
    except Exception as e:
        print(f"Unexpected error: {e}") 