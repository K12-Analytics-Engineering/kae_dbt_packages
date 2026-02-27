# kae_dbt_packages

Vendored dbt packages for KAE client repos. Python manifest files (lockfiles, requirements.txt, pyproject.toml) and dbt dependency files (packages.yml) are stripped to prevent Dependabot CVE alerts and `dbt deps` source conflicts in downstream repos.

## Usage

In your client repo's `packages.yml`:

```yaml
packages:
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: dbt_utils
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: dbt_external_tables
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: kae_dbt
```

Optional packages (add only if needed):

```yaml
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: dbt_expectations
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: dbt_date
  - git: https://github.com/K12-Analytics-Engineering/kae_dbt_packages.git
    revision: 2026.02
    subdirectory: dbt_project_evaluator
```

Note: `dbt_date` is a dependency of `dbt_expectations` — include both if using expectations.

## Updating a package

```bash
# Check what's new upstream
make check-updates

# Update a package (pulls upstream tag, strips manifests and dev files)
make update-kae-dbt tag=0.6.0

# Update manifest.yml with the new version, then:
make pr              # verify, commit, push, open PR
# (review and merge PR)
make tag v=2026.03   # tag main, create GH release
```

Run `make help` for the full list of targets.

## Current versions

See `manifest.yml` for the full list of vendored packages and their upstream versions.
