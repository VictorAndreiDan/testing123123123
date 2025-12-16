import requests
import urllib3

# Disable SSL warnings for internal domains
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- CONFIGURATION ---
# Based on your previous message, your base URL likely ends in /api
# Try: "https://test/api" or just "https://test" depending on your proxy setup
DT_BASE_URL = "https://test/api" 
DT_API_KEY = "YOUR_API_KEY_HERE"

def test_connection():
    # Endpoint to fetch first 10 projects
    url = f"{DT_BASE_URL}/api/v1/project"
    
    headers = {
        "X-Api-Key": DT_API_KEY,
        "Accept": "application/json"
    }
    
    params = {
        "pageSize": 1  # Just fetch 1 item to keep it light
    }

    print(f"Testing connection to: {url} ...")

    try:
        response = requests.get(url, headers=headers, params=params, verify=False)
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SUCCESS: Connection established and authenticated.")
            print(f"Server returned: {len(response.json())} projects in this page.")
        elif response.status_code == 401:
            print("❌ ERROR: Unauthorized. Check your API KEY.")
        elif response.status_code == 404:
            print("❌ ERROR: Endpoint not found. Check your URL.")
        else:
            print(f"❌ ERROR: Server returned {response.status_code}")
            print(f"Response: {response.text}")

    except Exception as e:
        print(f"❌ EXCEPTION: {e}")

if __name__ == "__main__":
    test_connection()
