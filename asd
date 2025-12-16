import requests
import json
import urllib3

# Disable SSL warnings for internal domains
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- CONFIGURATION ---
DT_BASE_URL = "https://test/api/api" 
DT_API_KEY = "YOUR_API_KEY_HERE"

# Custom Field Config (Update if you get Error 400)
CUSTOM_LOGIC_KEY = "collectionLogic" 
CUSTOM_LOGIC_VALUE = "NONE"

# File to save results
OUTPUT_FILENAME = "project_keys.txt"

PROJECT_LIST = [
    "Frontend-App",
    "Backend-Service",
    "Authentication-Module",
    "Legacy-System"
]

def create_project(project_name):
    """
    Creates a project and returns the UUID.
    """
    url = f"{DT_BASE_URL}/api/v1/project"
    
    headers = {
        "X-Api-Key": DT_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    payload = {
        "name": project_name,
        "classifier": "APPLICATION",
        "active": True,
        CUSTOM_LOGIC_KEY: CUSTOM_LOGIC_VALUE
    }

    try:
        response = requests.put(url, headers=headers, json=payload, verify=False)
        
        if response.status_code == 201:
            return response.json().get('uuid')
        elif response.status_code == 409:
            return get_existing_uuid(project_name)
        else:
            return f"ERROR {response.status_code}: {response.text}"

    except Exception as e:
        return f"EXCEPTION: {str(e)}"

def get_existing_uuid(project_name):
    """
    Helper: Fetch UUID if project already exists.
    """
    url = f"{DT_BASE_URL}/api/v1/project"
    headers = {"X-Api-Key": DT_API_KEY}
    params = {"searchText": project_name}
    
    try:
        r = requests.get(url, headers=headers, params=params, verify=False)
        if r.status_code == 200:
            for p in r.json():
                if p.get('name') == project_name:
                    return f"{p.get('uuid')} (Existing)"
    except:
        pass
    return "ALREADY EXISTS (UUID Lookup Failed)"

def main():
    # header string formatting
    header = f"{'Project Name':<30} | {'Project Key (UUID)'}"
    separator = "-" * 80

    # Open the file in write mode
    with open(OUTPUT_FILENAME, "w") as f:
        
        # Print and write headers
        print(header)
        print(separator)
        f.write(header + "\n")
        f.write(separator + "\n")

        for name in PROJECT_LIST:
            uuid = create_project(name)
            
            # Format the output line
            line = f"{name:<30} | {uuid}"
            
            # 1. Print to Console
            print(line)
            
            # 2. Write to File
            f.write(line + "\n")
            
    print(f"\n[+] Processing complete. Results saved to '{OUTPUT_FILENAME}'")

if __name__ == "__main__":
    main()
