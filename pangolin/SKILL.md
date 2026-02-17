# Pangolin API Skill

## Purpose
Interact with the Pangolin API (`$PANGOLIN_ADDRESS/v1/`) to query settings and states (resources, sites, IDs, etc.).

## Requirements
- `PANGOLIN_API_KEY` — API token (required)
- `PANGOLIN_ADDRESS` — Base URL (default: `https://pangolin.example.com`)
- `curl` for HTTP requests

## Auto-Setup
On first command, if required values are missing from `MEMORY.md`:
1. Prompts for missing values
2. Saves them to `MEMORY.md`
3. Proceeds with the requested action

## Usage Examples
- "What is the status of public resource `<name>`?"
- "What site is connected to resource `<name>`?"
- "List all sites"
- "Show me all resources"
- "What IDP is connected?"

## Real-World Examples

### List Resources
```bash
$ pangolin_api.sh list-resources
{
  "resources": [
    {"niceId": "resource1", "name": "Resource One", "enabled": true},
    {"niceId": "resource2", "name": "Resource Two", "enabled": true},
    {"niceId": "resource3", "name": "Resource Three", "enabled": false}
  ]
}
```

### List Sites
```bash
$ pangolin_api.sh list-sites
{
  "sites": [
    {"niceId": "site1", "name": "Site One", "status": "online"},
    {"niceId": "site2", "name": "Site Two", "status": "online"},
    {"niceId": "site3", "name": "Site Three", "status": "offline"}
  ]
}
```

### Get Resource by Name
```bash
$ pangolin_api.sh get-resource-by-name resource1
{
  "niceId": "resource1",
  "name": "Resource One",
  "enabled": true,
  "type": "web",
  "url": "https://example.com"
}
```

### List IDPs
```bash
$ pangolin_api.sh list-idps
{
  "idps": [
    {"id": "idp1", "name": "Identity Provider", "type": "oidc", "enabled": true}
  ]
}
```

## Troubleshooting
- **502 Bad Gateway**: The API endpoint may be temporarily unavailable. Check if the Pangolin service is running and accessible.
- **401 Unauthorized**: Verify `PANGOLIN_API_KEY` is set correctly.
- **404 Not Found**: Check that the org ID and endpoint are correct.

## API Endpoints (GET only)
| Endpoint | Purpose |
|--|--|
| `/orgs` | List organizations |
| `/org/{orgId}` | Get org details |
| `/org/{orgId}/sites` | List sites |
| `/org/{orgId}/site/{niceId}` | Get site by nice ID |
| `/org/{orgId}/resources` | List resources |
| `/org/{orgId}/resource/{niceId}` | Get resource by nice ID |
| `/idp` | List identity providers |
| `/idp/{idpId}` | Get IDP details |
| `/site-resource/{siteResourceId}` | Get site resource |
| `/client/{clientId}` | Get client |
| `/resource/{resourceId}` | Get resource details |

## Bash Functions

The skill provides both Bash functions (for inline use) and a helper script (`pangolin_api.sh`) for command-line usage.

### Helper Script: `pangolin_api.sh`

Located at `/root/.nanobot/workspace/skills/pangolin/scripts/pangolin_api.sh`

#### Commands:
| Command | Description |
|---------|-------------|
| `setup` | Prompt for ORG_ID and save to memory |
| `get-org-id` | Return stored org ID |
| `call <endpoint>` | Make authenticated API call |

#### Usage:
```bash
# Setup (need to provide ORG_ID manually)
/root/.nanobot/workspace/skills/pangolin/scripts/pangolin_api.sh setup

# Get stored org ID
/root/.nanobot/workspace/skills/pangolin/scripts/pangolin_api.sh get-org-id

# Make API call
/root/.nanobot/workspace/skills/pangolin/scripts/pangolin_api.sh call orgs
```

### Bash Functions (for inline use)

These functions assume environment variables are set (`PANGOLIN_API_KEY`, `PANGOLIN_ADDRESS`, `PANGOLIN_ORG_ID`):

#### `pangolin_api(method, endpoint)`
Makes authenticated API calls to the Pangolin API.

```bash
pangolin_api() {
  local method=$1
  local endpoint=$2
  local key="${PANGOLIN_API_KEY}"
  local addr="${PANGOLIN_ADDRESS:-https://pangolin.example.com}"

  curl -s -X "$method" \
    -H "Authorization: Bearer $key" \
    -H "Content-Type: application/json" \
    "$addr/v1$endpoint" 2>&1
}
```

#### `pangolin_list_orgs()`
List all organizations.

```bash
pangolin_list_orgs() {
  pangolin_api GET /orgs
}
```

#### `pangolin_list_resources()`
List all resources for the configured org.

```bash
pangolin_list_resources() {
  pangolin_api GET "/org/$PANGOLIN_ORG_ID/resources"
}
```

#### `pangolin_get_resource_by_name(name)`
Get a specific resource by its nice name.

```bash
pangolin_get_resource_by_name() {
  local name=$1
  pangolin_api GET "/org/$PANGOLIN_ORG_ID/resource/$name"
}
```

#### `pangolin_list_sites()`
List all sites for the configured org.

```bash
pangolin_list_sites() {
  pangolin_api GET "/org/$PANGOLIN_ORG_ID/sites"
}
```

#### `pangolin_get_site_by_nice_id(niceId)`
Get a site by its nice ID.

```bash
pangolin_get_site_by_nice_id() {
  local nice_id=$1
  pangolin_api GET "/org/$PANGOLIN_ORG_ID/site/$nice_id"
}
```

#### `pangolin_list_idps()`
List all identity providers.

```bash
pangolin_list_idps() {
  pangolin_api GET /idp
}
```

## Auth
```bash
curl -H "Authorization: Bearer $PANGOLIN_API_KEY" "$PANGOLIN_ADDRESS/v1/endpoint"
```

## Notes
- Environment variables are required: `PANGOLIN_API_KEY`, `PANGOLIN_ADDRESS`, `PANGOLIN_ORG_ID`
- Use `pangolin_api.sh setup` to configure ORG_ID
- Values are stored in `/root/.nanobot/workspace/memory/.pangolin_org_id`
