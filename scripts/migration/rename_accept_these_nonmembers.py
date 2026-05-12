#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "psycopg[binary]>=3.1",
#     "sqlalchemy>=2.0",
# ]
# ///
"""Rewrite one string in every mailman list's accept_these_nonmembers field.

The column is a SQLAlchemy PickleType wrapping a MutableList[str]. We load
the pickle, replace any list entry equal to OLD with NEW, and re-pickle.
Dry-run by default; pass --apply to write.

Examples:
  ./rename_accept_these_nonmembers.py @global-whitelist.ietf.org @global-whitelist@ietf.org
  ./rename_accept_these_nonmembers.py global-whitelist global-allowlist
"""

import argparse
import os
import pickle

import psycopg
from sqlalchemy.ext.mutable import MutableList

DEFAULT_DSN = os.environ.get(
    "MAILMAN_DSN",
    "postgresql://mailman:mailman@127.0.0.1:5433/mailman",
)


def rewrite(values: list[str], old: str, new: str) -> list[str]:
    """Return values with every literal `old` replaced by `new`."""
    return [v.replace(old, new) for v in values]


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("old", help="String to replace")
    p.add_argument("new", help="Replacement string")
    p.add_argument("--dsn", default=DEFAULT_DSN, help=f"default: {DEFAULT_DSN}")
    p.add_argument("--apply", action="store_true", help="Write changes (otherwise dry run)")
    args = p.parse_args()

    changes: list[tuple[int, str, list[str], list[str]]] = []

    with psycopg.connect(args.dsn) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, list_id, accept_these_nonmembers FROM mailinglist "
                "WHERE accept_these_nonmembers IS NOT NULL ORDER BY list_id"
            )
            for row_id, list_id, blob in cur.fetchall():
                old_values = pickle.loads(bytes(blob))
                new_values = rewrite(old_values, args.old, args.new)
                if new_values != old_values:
                    changes.append((row_id, list_id, old_values, new_values))

        for _, list_id, before, after in changes:
            print(f"{list_id}:\n {before} -> {after}")
        print(f"\n{len(changes)} list(s) affected.")

        if not args.apply:
            print("Dry run. Re-run with --apply to write.")
            return 0

        with conn.cursor() as cur:
            for row_id, _, _, new_values in changes:
                blob = pickle.dumps(MutableList(new_values))
                cur.execute(
                    "UPDATE mailinglist SET accept_these_nonmembers = %s WHERE id = %s",
                    (psycopg.Binary(blob), row_id),
                )
        conn.commit()
        print(f"Applied {len(changes)} update(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
