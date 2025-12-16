import requests
import json

# --- Configuration ---
# specific the base URL of your Dependency-Track instance
DT_API_URL = "http://localhost:8080" 
# Replace with your actual API Key (Permissions required: PORTFOLIO_MANAGEMENT)
DT_API_KEY = "YOUR_API_KEY_HERE"

# List of projects you want to create
PROJECT_LIST = [
    "Frontend-App",
    "Backend-Service",
    "Authentication-Module",
    "Legacy-System"
]

def create_project(project_name):
    """
    Creates a project in Dependency-Track and returns the UUID.
    """
    url = f"{DT_API_URL}/api/v1/project"
    
    headers = {
        "X-Api-Key": DT_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    # Payload for project creation
    # You can add "version": "1.0" or "classifier": "APPLICATION" if needed
    payload = {
        "name": project_name,
        "classifier": "APPLICATION", 
        "active": True
    }

    try:
        # Dependency-Track uses PUT to create a new project
        response = requests.put(url, headers=headers, json=payload)
        
        # If successful (HTTP 201 Created)
        if response.status_code == 201:
            data = response.json()
            return data.get('uuid')
        
        # If project already exists (HTTP 409 Conflict)
        elif response.status_code == 409:
            return "ALREADY EXISTS"
            
        else:
            return f"ERROR: {response.status_code} - {response.text}"

    except Exception as e:
        return f"EXCEPTION: {str(e)}"

def main():
    print(f"{'Project Name':<30} | {'Project Key (UUID)'}")
    print("-" * 70)
    
    results = []

    for name in PROJECT_LIST:
        uuid = create_project(name)
        results.append((name, uuid))
        print(f"{name:<30} | {uuid}")

if __name__ == "__main__":
    main()
