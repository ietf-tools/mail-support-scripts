# mail-support-scripts

Support scripts for IETF mail infrastructure, deployed as Kubernetes CronJobs via Helm.

## Architecture

Each CronJob uses an init container to clone this repo via SSH deploy key, then runs the
script with `uv run` against the local checkout.

## Prerequisites

- A read-only [deploy key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys) for this repo

## Helm Chart

```bash
helm repo add mail-support-scripts https://ietf-tools.github.io/mail-support-scripts
helm install mail-support-scripts mail-support-scripts/mail-support-scripts -n mail -f values.yaml
```

Example `values.yaml`:

```yaml
deployKey:
  secretName: mail-secrets-env
  secretKey: MAIL_SUPPORT_SCRIPTS_DEPLOY_KEY

commonEnv:
  DATATRACKER_URL: https://datatracker.staging.ietf.org
  ## During testing this replaces the destination address for all aliases built by dt-alias-sync
  TEST_OVERRIDE_ADDRESSES: noreply@ietf.org

dtAliasSync:
  env:
    MAIL_HOST: uat.tools-dev.org
    DB_HOST: db-email-staging-rw
    DB_PORT: "5432"
    DB_NAME: postfix
  secrets:
    - name: DATATRACKER_TOKEN
      secretName: mail-secrets-env
      key: DATATRACKER_API_TOKEN
    - name: DB_USER
      secretName: mail-secrets-env
      key: POSTFIX_DB_USER
    - name: DB_PASS
      secretName: mail-secrets-env
      key: POSTFIX_DB_PASS

globalAllowlistSync:
  env:
    GLOBAL_ALLOWLIST_FQDN: global-allowlist@uat.tools-dev.org
    MAILMAN_API_URL: http://mailman:8001/3.1
    POSTCONFIRM_DB_HOST: db-email-staging-rw
    POSTCONFIRM_DB_PORT: "5432"
    POSTCONFIRM_DB_NAME: postconfirm
  secrets:
    - name: DATATRACKER_TOKEN
      secretName: mail-secrets-env
      key: DATATRACKER_API_TOKEN
    - name: MAILMAN_API_USER
      secretName: mail-secrets-env
      key: mailmanApiUser
    - name: MAILMAN_API_PASSWORD
      secretName: mail-secrets-env
      key: mailmanApiPass
    - name: POSTCONFIRM_DB_USER
      secretName: mail-secrets-env
      key: POSTCONFIRM_DB_USER
    - name: POSTCONFIRM_DB_PASS
      secretName: mail-secrets-env
      key: POSTCONFIRM_DB_PASS
```

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
