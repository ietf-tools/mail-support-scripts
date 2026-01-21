# mail-support-scripts

Support scripts for IETF mail infrastructure, designed to run as Kubernetes CronJobs.

## Usage

Deploy using the Helm chart:

```bash
helm install mail-support-scripts ./charts/mail-support-scripts \
  --set dtAliasSync.enabled=true \
  --set globalAllowlistSync.enabled=true
```

Scripts are fetched directly from GitHub at runtime using `uv run`, so no container build is required.

See `charts/mail-support-scripts/values.yaml` for all configuration options.

## Scripts

### dt-alias-sync

Syncs datatracker aliases (drafts and groups) to the postfix virtual table.

```bash
dt-alias-sync --diff           # show what would change
dt-alias-sync --apply          # apply changes to DB
dt-alias-sync --diff --apply   # show diff, then apply
```

**Environment variables:**

- `DATATRACKER_URL` - Datatracker API base URL (default: `https://datatracker.ietf.org`)
- `DATATRACKER_TOKEN` - API token for authentication
- `MAIL_HOST` - Target mail host for aliases
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` - Postfix database connection

### global-allowlist-sync

Syncs known-good senders from Datatracker and Mailman to the postconfirm senders table.

```bash
global-allowlist-sync                    # dry-run, show what would change
global-allowlist-sync --apply            # apply changes
global-allowlist-sync --apply --verbose  # apply with detailed output
global-allowlist-sync --skip-mailman     # skip Mailman sync
global-allowlist-sync --skip-postconfirm # skip Postconfirm sync
global-allowlist-sync --skip-datatracker # use Mailman only
```

**Environment variables:**

- `DATATRACKER_URL` - Datatracker API base URL (default: `https://datatracker.ietf.org`)
- `DATATRACKER_TOKEN` - API token for authentication
- `MAILMAN_API_URL` - Mailman REST API URL
- `MAILMAN_API_USER` - Mailman API username
- `MAILMAN_API_PASSWORD` - Mailman API password
- `GLOBAL_ALLOWLIST_FQDN` - Mailman list for global allowlist (default: `global-whitelist@ietf.org`)
- `POSTCONFIRM_DB_HOST`, `POSTCONFIRM_DB_PORT`, `POSTCONFIRM_DB_NAME`, `POSTCONFIRM_DB_USER`, `POSTCONFIRM_DB_PASS` - Postconfirm database connection
