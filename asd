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
    
    print(f"Fetching rules for profile: {profile_key}...")
    
    while True:
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
                
                # Default severity (system default)
                effective_severity = rule.get('severity', 'INFO')
                
                # Check for profile-specific override in 'actives'
                if 'actives' in rule:
                    for active in rule['actives']:
                        if active.get('qProfile') == profile_key:
                            effective_severity = active.get('severity', effective_severity)
                            break
                
                # Store in dictionary (Handles deduplication automatically)
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

    return rules

def write_csv(filename, headers, rows):
    """
    Generic CSV writer
    """
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    print(f"Created file: {filename} ({len(rows)} rules)")

# --- MAIN EXECUTION ---

# 1. Fetch Data
p1_rules = get_active_rules(PROFILE_1_KEY)
p2_rules = get_active_rules(PROFILE_2_KEY)

# 2. Key Sets
p1_keys = set(p1_rules.keys())
p2_keys = set(p2_rules.keys())

# 3. Calculate Sets
only_p1_keys = p1_keys - p2_keys
only_p2_keys = p2_keys - p1_keys
in_both_keys = p1_keys & p2_keys  # Intersection ONLY

# 4. Prepare Data for CSVs

# List for Profile 1 Only
rows_p1_only = []
for k in only_p1_keys:
    rows_p1_only.append([k, p1_rules[k]['name'], p1_rules[k]['severity']])

# List for Profile 2 Only
rows_p2_only = []
for k in only_p2_keys:
    rows_p2_only.append([k, p2_rules[k]['name'], p2_rules[k]['severity']])

# List for Rules In Both (With comparison columns)
rows_in_both = []
for k in in_both_keys:
    name = p1_rules[k]['name'] # Name is same in both
    sev1 = p1_rules[k]['severity']
    sev2 = p2_rules[k]['severity']
    
    # Optional: Mark if severity is different
    diff_flag = "YES" if sev1 != sev2 else "NO"
    
    rows_in_both.append([k, name, sev1, sev2, diff_flag])

# 5. Write Files
print("\n--- Writing Output Files ---")
write_csv("profile1_only.csv", ["Rule Key", "Rule Name", "Severity"], rows_p1_only)
write_csv("profile2_only.csv", ["Rule Key", "Rule Name", "Severity"], rows_p2_only)
write_csv("rules_in_both.csv", ["Rule Key", "Rule Name", f"Severity_{PROFILE_1_KEY}", f"Severity_{PROFILE_2_KEY}", "Severity_Mismatch"], rows_in_both)

# 6. Sanity Check / Math Verification
print("\n--- Summary Verification ---")
print(f"Total Rules in Profile 1: {len(p1_keys)}")
print(f"Total Rules in Profile 2: {len(p2_keys)}")
print(f"----------------------------------------")
print(f"Unique to Profile 1:      {len(only_p1_keys)}")
print(f"Unique to Profile 2:      {len(only_p2_keys)}")
print(f"Shared (In Both):         {len(in_both_keys)}")
print(f"----------------------------------------")
print(f"Check P1: {len(only_p1_keys)} + {len(in_both_keys)} = {len(only_p1_keys) + len(in_both_keys)} (Should match P1 Total)")
print(f"Check P2: {len(only_p2_keys)} + {len(in_both_keys)} = {len(only_p2_keys) + len(in_both_keys)} (Should match P2 Total)")
