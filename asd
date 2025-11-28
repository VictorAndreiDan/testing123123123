import requests
import csv

# --- CONFIGURATION ---
SONAR_URL = "http://localhost:9000"  # Your SonarQube URL
TOKEN = "YOUR_AUTH_TOKEN_HERE"       # Your User Token
PROFILE_1_KEY = "AX-abc123_key"      # Key for Profile 1
PROFILE_2_KEY = "AX-xyz789_key"      # Key for Profile 2
# ---------------------

def get_active_rules(profile_key):
    """
    Fetches rules and their effective severity for a specific profile.
    Returns: { rule_key: {'name': str, 'severity': str} }
    """
    rules = {}
    page = 1
    page_size = 500
    
    print(f"Fetching rules and severity for profile: {profile_key}...")
    
    while True:
        # We request 'actives' to get the profile-specific severity
        params = {
            'qprofile': profile_key,
            'activation': 'true',
            'p': page,
            'ps': page_size,
            'f': 'name,severity,actives' 
        }
        
        try:
            response = requests.get(
                f"{SONAR_URL}/api/rules/search", 
                auth=(TOKEN, ''), 
                params=params
            )
            response.raise_for_status()
            data = response.json()
            
            if 'rules' not in data or not data['rules']:
                break
                
            for rule in data['rules']:
                key = rule['key']
                name = rule['name']
                
                # Logic to find the effective severity in this profile
                # The API returns an 'actives' list. We find the entry matching our profile.
                effective_severity = rule.get('severity', 'INFO') # Default fallback
                
                if 'actives' in rule:
                    for active in rule['actives']:
                        # The API usually only returns the relevant active due to the 
                        # qprofile param, but we check to be safe.
                        if active.get('qProfile') == profile_key:
                            effective_severity = active.get('severity', effective_severity)
                            break
                
                rules[key] = {
                    'name': name,
                    'severity': effective_severity
                }
            
            if page * page_size >= data['total']:
                break
                
            page += 1
            
        except requests.exceptions.RequestException as e:
            print(f"Error fetching rules: {e}")
            break

    print(f"Found {len(rules)} rules.")
    return rules

def write_to_csv(filename, rule_data_dict):
    """
    Writes the rule data to a CSV file.
    rule_data_dict: { key: {'name':..., 'severity':...} }
    """
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        # Updated header to include Severity
        writer.writerow(["Rule Key", "Rule Name", "Severity"])
        
        for key, data in rule_data_dict.items():
            writer.writerow([key, data['name'], data['severity']])
            
    print(f"Created file: {filename} ({len(rule_data_dict)} rules)")

# --- MAIN EXECUTION ---

# 1. Fetch Data
p1_rules = get_active_rules(PROFILE_1_KEY)
p2_rules = get_active_rules(PROFILE_2_KEY)

# 2. Convert keys to sets for comparison
p1_keys = set(p1_rules.keys())
p2_keys = set(p2_rules.keys())

# 3. Perform Set Operations
only_in_p1_keys = p1_keys - p2_keys
only_in_p2_keys = p2_keys - p1_keys
in_both_keys = p1_keys & p2_keys

# 4. Reconstruct dictionaries for output
only_p1_output = {k: p1_rules[k] for k in only_in_p1_keys}
only_p2_output = {k: p2_rules[k] for k in only_in_p2_keys}

# For rules in BOTH, we usually display the severity from Profile 1.
# (If you need to see if severities differ between profiles, let me know!)
in_both_output = {k: p1_rules[k] for k in in_both_keys}

# 5. Write Files
print("--- Writing Output Files ---")
write_to_csv("profile1_only.csv", only_p1_output)
write_to_csv("profile2_only.csv", only_p2_output)
write_to_csv("rules_in_both.csv", in_both_output)

print("Done.")
