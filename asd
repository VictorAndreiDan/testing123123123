import requests
import json
import urllib3
import os

# Disable SSL warnings for internal domains
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- CONFIGURATION ---
DT_BASE_URL = "https://test/api/api" 
DT_API_KEY = "YOUR_API_KEY_HERE"

# Custom Field Config (Update if you get Error 400)
CUSTOM_LOGIC_KEY = "collectionLogic" 
CUSTOM_LOGIC_VALUE = "NONE"

# File names
INPUT_FILENAME = "projects_to_create.txt"
OUTPUT_FILENAME = "project_keys.txt"

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
    # 1. Read from Input File
    if not os.path.exists(INPUT_FILENAME):
        print(f"❌ ERROR: Could not find '{INPUT_FILENAME}'.")
        print("   -> Please create this file and add one project name per line.")
        return

    print(f"Reading projects from '{INPUT_FILENAME}'...")
    
    with open(INPUT_FILENAME, "r") as f:
        # Read lines, strip whitespace, and ignore empty lines
        project_list = [line.strip() for line in f if line.strip()]

    if not project_list:
        print("❌ ERROR: The input file is empty.")
        return

    print(f"Found {len(project_list)} projects to process.\n")

    # 2. Process and Write to Output File
    header = f"{'Project Name':<40} | {'Project Key (UUID)'}"
    separator = "-" * 90

    with open(OUTPUT_FILENAME, "w") as f_out:
        # Write headers
        print(header)
        print(separator)
        f_out.write(header + "\n")
        f_out.write(separator + "\n")

        for name in project_list:
            uuid = create_project(name)
            
            # Format output
            line = f"{name:<40} | {uuid}"
            
            # Print to console and file
            print(line)
            f_out.write(line + "\n")
            
    print(f"\n[+] Done! Results saved to '{OUTPUT_FILENAME}'")

if __name__ == "__main__":
    main()
