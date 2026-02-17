#!/bin/bash
# Pangolin API Helper Script
# Usage: ./pangolin_api.sh <command> [args...]

set -e

API_KEY="${PANGOLIN_API_KEY}"
BASE_URL="${PANGOLIN_ADDRESS:-https://pangolin.example.com}"
MEMORY_FILE="/root/.nanobot/workspace/memory/MEMORY.md"
ORG_ID_FILE="/root/.nanobot/workspace/memory/.pangolin_org_id"

# Validate API key
if [[ -z "$API_KEY" ]]; then
    echo "❌ PANGOLIN_API_KEY not set"
    exit 1
fi

# Helper: Make API call
api_call() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $API_KEY" "$BASE_URL/v1/$endpoint"
}

# Helper: Extract org ID from orgs list
find_org_id() {
    local name="$1"
    api_call "orgs" | grep -oP '"id":"\K[^"]+' | head -1
}

# Setup: Discover org and store credentials
setup() {
    echo "🔍 Pangolin API Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Note: Your API key does not have root access to list orgs."
    echo "Please provide your ORG_ID manually (or press Enter to skip):"
    read -p "ORG_ID: " user_org_id

    if [[ -z "$user_org_id" ]]; then
        echo "⚠️ Skipping org ID setup. You can add it later to $MEMORY_FILE manually."
        exit 0
    fi

    echo "$user_org_id" > "$ORG_ID_FILE"
    echo "✅ Organization ID saved: $user_org_id"

    # Try to verify with /org/{orgId}
    local org_detail
    org_detail=$(api_call "org/$user_org_id")
    if [[ "$org_detail" == *"success"* ]]; then
        local org_name
        org_name=$(echo "$org_detail" | grep -oP '"name":"\K[^"]+' | head -1)
        echo "✅ Verified org name: $org_name"
    else
        echo "⚠️ Could not verify org (403/404 is expected for some keys)"
    fi
}

# Get stored org ID
get_org_id() {
    if [[ -f "$ORG_ID_FILE" ]]; then
        cat "$ORG_ID_FILE"
    else
        echo "❌ No org ID stored. Run 'setup' first."
        exit 1
    fi
}

# List resources for current org
list_resources() {
    local org_id
    org_id=$(get_org_id)
    api_call "org/$org_id/resources"
}

# List sites for current org
list_sites() {
    local org_id
    org_id=$(get_org_id)
    api_call "org/$org_id/sites"
}

# Get site by nice ID
get_site_by_nice_id() {
    local nice_id="$1"
    local org_id
    org_id=$(get_org_id)
    api_call "org/$org_id/site/$nice_id"
}

# List IDPs
list_idps() {
    api_call "idp"
}

# Get resource by nice name (filters list-resources output)
get_resource_by_name() {
    local name="$1"
    local org_id
    org_id=$(get_org_id)
    local resources
    resources=$(api_call "org/$org_id/resources")
    python3 -c "
import sys, json
data = json.loads('''$resources''')
for r in data.get('data', {}).get('resources', []):
    if r.get('name') == '''$name''':
        print(json.dumps(r, indent=2))
        break
"
}

# Command dispatcher
case "${1:-}" in
    setup)
        setup
        ;;
    get-org-id)
        get_org_id
        ;;
    call)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 call <endpoint>"
            exit 1
        fi
        api_call "$2"
        ;;
    list-resources)
        list_resources
        ;;
    list-sites)
        list_sites
        ;;
    get-site-by-nice-id)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 get-site-by-nice-id <niceId>"
            exit 1
        fi
        get_site_by_nice_id "$2"
        ;;
    list-idps)
        list_idps
        ;;
    get-resource-by-name)
        if [[ -z "${2:-}" ]]; then
            echo "Usage: $0 get-resource-by-name <name>"
            exit 1
        fi
        get_resource_by_name "$2"
        ;;
    *)
        echo "Usage: $0 {setup|get-org-id|call|list-resources|list-sites|get-site-by-nice-id|list-idps|get-resource-by-name}"
        exit 1
        ;;
esac
