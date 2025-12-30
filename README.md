# mail-support-scripts

Support scripts for IETF mail infrastructure, packaged as a container for use in Kubernetes CronJobs.

## Usage

Scripts are available at `/usr/local/bin/` in the container image.

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
