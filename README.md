# kae_dbt_packages

Vendored dbt packages for KAE client repos. Python manifest files (lockfiles, requirements.txt, pyproject.toml) and dbt dependency files (packages.yml) are stripped to prevent Dependabot CVE alerts and `dbt deps` source conflicts in downstream repos.

## Usage

In your client repo's `packages.yml`, set `revision` to the latest
[release](https://github.com/K12-Analytics-Engineering/kae_dbt_packages/releases) tag (calver, `YYYY.MM.MICRO`):

```yaml
packages:
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: dbt_utils
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: dbt_external_tables
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: kae_dbt
```

Optional packages (add only if needed):

```yaml
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: dbt_expectations
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: dbt_date
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.11.1
    subdirectory: dbt_project_evaluator
```

Note: `dbt_date` is a dependency of `dbt_expectations` — include both if using expectations.

## Updating a package

Recipes live in the `justfile` (run `just --list` for all of them). They work the same from a regular checkout or a git worktree, on macOS or Linux.

```bash
# Check what's new upstream
just pkg-check-updates

# Update a package (pulls the upstream tag, strips manifests and dev files)
just pkg-update dbt_utils dbt-labs/dbt-utils 1.4.1

# Update manifest.yml with the new version, then verify
just pkg-verify                         # no Python manifest files left behind
just pkg-parse-check 1.12.7 1.12.3      # dbt-core, dbt-bigquery [, python=3.13] to install + parse against

# Release
just pkg-release-pr                     # verify, commit, push, open PR
# (review and merge PR)
just pkg-release-tag                    # tag main, create GH release
```

`pkg-update-all` re-pulls every package at the versions in `manifest.yml`.

## Current versions

See `manifest.yml` for the full list of vendored packages and their upstream versions.
