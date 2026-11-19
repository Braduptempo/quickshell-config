# quickshell-config

## Checks

Every push and every pull request into `develop` or `main` runs GitHub Actions (`.github/workflows/ci.yml`):

| Job | What it checks | Blocks a merge |
|---|---|---|
| Lint | `qmldir` entries point to existing files, no QML syntax errors, no missing imports, the number of qmllint warnings doesn't go up, `shellcheck` on the scripts | Yes |
| Load test | Starts the config in a headless sway for 10 seconds and fails on load errors or JavaScript errors from our own files | Not yet (still being tuned) |

Run them locally:

```bash
scripts/ci/lint.sh
```

```bash
scripts/ci/load-test.sh
```

The load test uses your running session, so you briefly see a second bar.

When you remove qmllint warnings, lock in the lower count:

```bash
scripts/ci/lint.sh --update
```
