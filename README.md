# mail-support-scripts

Support scripts for IETF mail infrastructure, deployed as Kubernetes CronJobs via Helm.

## Architecture

Each CronJob uses an init container to clone this repo then run the script with
`uv run --script` against the local checkout.

## Helm Chart

```bash
helm repo add mail-support-scripts https://ietf-tools.github.io/mail-support-scripts
helm install mail-support-scripts mail-support-scripts/mail-support-scripts -n mail -f values.yaml
```

Example `values.yaml`:

```yaml
commonEnv:
  DATATRACKER_URL: https://datatracker.example.org

dtAliasSync:
  env:
    MAIL_HOST: example.org
    DB_HOST: db-rw
    DB_PORT: "5432"
    DB_NAME: postfix
  secrets:
    - name: DATATRACKER_TOKEN
      secretName: mail-support-scripts-env
      key: DATATRACKER_TOKEN
    - name: DB_USER
      secretName: mail-support-scripts-env
      key: POSTFIX_DB_USER
    - name: DB_PASS
      secretName: mail-support-scripts-env
      key: DB_PASS

globalAllowlistSync:
  env:
    GLOBAL_ALLOWLIST_FQDN: mailman-allowlist@example.org
    MAILMAN_API_URL: http://mailman:8001/3.1
    POSTCONFIRM_DB_HOST: db-rw
    POSTCONFIRM_DB_PORT: "5432"
    POSTCONFIRM_DB_NAME: postconfirm
  secrets:
    - name: DATATRACKER_TOKEN
      secretName: mail-support-scripts-env
      key: DATATRACKER_API_TOKEN
    - name: MAILMAN_API_USER
      secretName: mail-support-scripts-env
      key: MAILMAN_API_USER
    - name: MAILMAN_API_PASSWORD
      secretName: mail-support-scripts-env
      key: MAILMAN_API_PASSWORD
    - name: POSTCONFIRM_DB_USER
      secretName: mail-support-scripts-env
      key: POSTCONFIRM_DB_USER
    - name: POSTCONFIRM_DB_PASS
      secretName: mail-support-scripts-env
      key: POSTCONFIRM_DB_PASS
```

## Scripts

### dt-alias-sync

Syncs datatracker aliases (drafts and groups) to the postfix virtual table.

```bash
dt-alias-sync --diff                              # show what would change
dt-alias-sync --apply                             # apply changes to DB
dt-alias-sync --diff --apply                      # show diff, then apply
dt-alias-sync --force --apply                     # apply, skip safety checks
dt-alias-sync --drafts-file d.json --diff         # use local JSON instead of API
dt-alias-sync --groups-file g.json --diff         # use local JSON instead of API
```

**Environment variables:**

- `DATATRACKER_URL` - Datatracker API base URL (default: `https://datatracker.ietf.org`)
- `DATATRACKER_TOKEN` - API token for authentication
- `CF_ACCESS_CLIENT_ID`, `CF_ACCESS_CLIENT_SECRET` - Cloudflare Access service token (optional)
- `MAIL_HOST` - Target mail host for aliases
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` - Postfix database connection
- `TEST_OVERRIDE_ADDRESSES` - Comma-separated addresses to substitute for all alias destinations (testing only)

### global-allowlist-sync

Syncs known-good senders from Datatracker and Mailman to both the Mailman global allowlist and the postconfirm senders table.

```bash
global-allowlist-sync                    # dry-run, show what would change
global-allowlist-sync --apply            # apply changes
global-allowlist-sync --apply --verbose  # apply with detailed output
global-allowlist-sync --skip-mailman     # skip Mailman sync
global-allowlist-sync --skip-postconfirm # skip Postconfirm sync
global-allowlist-sync --skip-datatracker # use Mailman only
```

**Environment variables:**

- `DATATRACKER_URL` - Datatracker API base URL
- `DATATRACKER_TOKEN` - API token for authentication
- `CF_ACCESS_CLIENT_ID`, `CF_ACCESS_CLIENT_SECRET` - Cloudflare Access service token (optional)
- `MAILMAN_API_URL` - Mailman REST API URL
- `MAILMAN_API_USER` - Mailman API username
- `MAILMAN_API_PASSWORD` - Mailman API password
- `GLOBAL_ALLOWLIST_FQDN` - Mailman list for global allowlist
- `POSTCONFIRM_DB_HOST`, `POSTCONFIRM_DB_PORT`, `POSTCONFIRM_DB_NAME`, `POSTCONFIRM_DB_USER`, `POSTCONFIRM_DB_PASS` - Postconfirm database connection
