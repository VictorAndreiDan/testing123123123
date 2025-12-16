import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- ADJUST THIS ---
# Based on your openapi link: https://test/api/api/openapi.json
# Try these variations if the first one fails:
# 1. https://test/api
# 2. https://test/api/api
DT_BASE_URL = "https://test/api" 
DT_API_KEY = "YOUR_API_KEY_HERE"

def debug_connection():
    url = f"{DT_BASE_URL}/api/v1/project"
    
    headers = {
        "X-Api-Key": DT_API_KEY,
        "Accept": "application/json"
    }
    
    print(f"1. Target URL: {url}")
    
    try:
        response = requests.get(url, headers=headers, params={"pageSize": 1}, verify=False)
        
        print(f"2. Status Code: {response.status_code}")
        
        # KEY FIX: Check content before converting to JSON
        print("3. Response Content (First 500 chars):")
        print("-" * 40)
        print(response.text[:500]) # Print raw text
        print("-" * 40)

        # Only try to parse JSON if it looks like JSON
        if response.text.strip().startswith("{") or response.text.strip().startswith("["):
            print("4. JSON Parse Success:", response.json())
        else:
            print("4. ERROR: Response is NOT JSON (likely HTML or plain text).")
            print("   -> Check your URL path.")

    except Exception as e:
        print(f"EXCEPTION: {e}")

if __name__ == "__main__":
    debug_connection()
