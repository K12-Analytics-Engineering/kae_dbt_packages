# kae_dbt_packages justfile

set shell := ["bash", "-euo", "pipefail", "-c"]

# Update a vendored package (usage: just pkg-update dbt_utils dbt-labs/dbt-utils 1.2.0)
pkg-update name repo tag:
    @./scripts/update_package.sh "{{name}}" "{{repo}}" "{{tag}}"
    @echo ""
    @echo "REMINDER: update manifest.yml with the new version for {{name}}"

# Re-pull all packages at versions listed in manifest.yml
pkg-update-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Updating all packages from manifest.yml..."
    echo ""
    grep -E '^\s{2}\w' manifest.yml | sed 's/://' | while read pkg; do
        upstream=$(grep -A1 "^  ${pkg}:" manifest.yml | grep 'upstream:' | awk '{print $2}')
        version=$(grep -A2 "^  ${pkg}:" manifest.yml | grep 'version:' | sed 's/.*"\(.*\)"/\1/')
        echo ""
        ./scripts/update_package.sh "$pkg" "$upstream" "$version"
    done
    echo ""
    echo "All packages updated."

# Verify no Python manifest files exist in any package
pkg-verify:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking for Python manifest files..."
    found=$(find . -not -path './.git/*' \( \
        -name "setup.py" -o -name "setup.cfg" -o -name "pyproject.toml" \
        -o -name "requirements.txt" -o -name "dev-requirements.txt" \
        -o -name "poetry.lock" -o -name "uv.lock" \
        -o -name "Pipfile" -o -name "Pipfile.lock" \
    \) -type f || true)
    if [ -n "$found" ]; then
        echo "FAIL: Python manifest files found:" && echo "$found" && exit 1
    else
        echo "PASS: No Python manifest files found."
    fi

# Generate release notes from manifest.yml
pkg-release-notes manifest="manifest.yml":
    #!/usr/bin/env bash
    set -euo pipefail
    manifest="{{manifest}}"
    echo "| Package | Version |"
    echo "|---|---|"
    grep -E '^\s{2}\w' "$manifest" | sed 's/://' | while read pkg; do
        version=$(grep -A2 "^  ${pkg}:" "$manifest" | grep 'version:' | sed 's/.*"\(.*\)"/\1/')
        echo "| $pkg | $version |"
    done
    echo ""
    echo "Python manifest files stripped to prevent Dependabot CVE alerts."

# Compute next YYYY.MM.MICRO calver tag
[private]
next-version:
    #!/usr/bin/env bash
    set -euo pipefail
    prefix=$(date +%Y.%m)
    max=0
    for t in $(git tag --list "$prefix" "$prefix.*" 2>/dev/null); do
        micro=${t##"$prefix"}
        if [ -z "$micro" ]; then
            n=0
        else
            n=${micro#.}
        fi
        if [ "$n" -ge "$max" ] 2>/dev/null; then max=$((n + 1)); fi
    done
    if [ "$max" -eq 0 ]; then max=1; fi
    echo "$prefix.$max"

# Create a PR for package updates (usage: just pkg-release-pr [version])
pkg-release-pr version="":
    #!/usr/bin/env bash
    set -euo pipefail
    just pkg-verify
    git fetch --quiet --tags origin
    tag="{{version}}"
    if [ -z "$tag" ]; then tag=$(just next-version); fi
    branch="release/$tag"
    notes=$(just pkg-release-notes)
    echo ""
    echo "=== PR for $tag ==="
    echo ""
    echo "$notes"
    echo ""
    git checkout -b "$branch"
    git add -A
    # changes may already be committed on the branch; only commit what's left
    if ! git diff --cached --quiet; then
        printf '%s vendored package bundle\n\n%s\n' "$tag" "$notes" | git commit -F -
    fi
    git push -u origin "$branch"
    gh pr create --title "$tag" --body "$notes"
    echo ""
    echo "PR created. After merge, run: just pkg-release-tag $tag"

# Tag and release after PR merge (usage: just pkg-release-tag [version])
pkg-release-tag version="":
    #!/usr/bin/env bash
    set -euo pipefail
    # tag origin/main directly (no checkout), so this works from main, any branch, or a worktree
    git fetch --quiet --tags origin main
    tag="{{version}}"
    if [ -z "$tag" ]; then tag=$(just next-version); fi
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
        echo "Tag $tag already exists."
        exit 1
    fi
    # release notes come from the manifest on origin/main, not the local checkout
    manifest=$(mktemp)
    trap 'rm -f "$manifest"' EXIT
    git show origin/main:manifest.yml > "$manifest"
    notes=$(just pkg-release-notes "$manifest")
    git tag "$tag" origin/main
    git push origin "$tag"
    gh release create "$tag" --title "$tag" --notes "$notes"
    echo ""
    echo "Done. Consumer repos should use: revision: $tag"

# Verify all vendored packages install and parse against a dbt version (usage: just pkg-parse-check 1.12.7 1.12.3 [python])
pkg-parse-check dbt-core-version dbt-bigquery-version python-version="3.13":
    #!/usr/bin/env bash
    set -euo pipefail

    repo=$(pwd)
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    # minimal dbt project
    cat > "$tmpdir/dbt_project.yml" << 'PROJ'
    name: 'verify'
    version: '1.0.0'
    profile: 'verify'
    PROJ

    cat > "$tmpdir/profiles.yml" << 'PROF'
    verify:
      target: dev
      outputs:
        dev:
          type: bigquery
          method: oauth
          project: dummy
          dataset: dummy
    PROF

    # declare every vendored package as a local package; dbt 1.12+ refuses to
    # parse when dbt_packages/ doesn't match packages.yml, so install via dbt deps
    echo "packages:" > "$tmpdir/packages.yml"
    for pkg in */dbt_project.yml; do
        echo "  - local: $repo/$(dirname "$pkg")" >> "$tmpdir/packages.yml"
    done

    # pin Python: uvx otherwise picks the system default, and dbt can crash on
    # an interpreter newer than it supports
    dbt() {
        uvx --python "{{python-version}}" \
            --from "dbt-core=={{dbt-core-version}}" \
            --with "dbt-bigquery=={{dbt-bigquery-version}}" \
            dbt "$@"
    }

    clean() {
        sed 's/\x1b\[[0-9;]*m//g' \
            | grep -v '^Downloading \|^ Downloading \|^ Downloaded \|^Installed \|^ *Built \|^ *Building '
    }

    fail() {
        echo "FAIL: $1"
        echo ""
        echo "$2"
        exit 1
    }

    echo "Parsing vendored packages against dbt-core=={{dbt-core-version}} dbt-bigquery=={{dbt-bigquery-version}} (Python {{python-version}})"
    echo ""

    set +e
    output=$(cd "$tmpdir" && dbt deps --profiles-dir . 2>&1)
    exit_code=$?
    set -e
    if [ $exit_code -ne 0 ]; then
        if echo "$output" | grep -q 'No solution found\|no version of'; then
            fail "Could not resolve dbt-core=={{dbt-core-version}} dbt-bigquery=={{dbt-bigquery-version}} on Python {{python-version}}" "$(echo "$output" | tail -5)"
        fi
        fail "dbt deps exited $exit_code" "$(echo "$output" | clean)"
    fi

    set +e
    output=$(cd "$tmpdir" && dbt parse --profiles-dir . --no-partial-parse --show-all-deprecations 2>&1)
    exit_code=$?
    set -e
    clean=$(echo "$output" | clean)

    # any nonzero exit is a failure, whether or not dbt printed [ERROR]
    # (a crash on import prints only a traceback)
    if [ $exit_code -ne 0 ] || echo "$clean" | grep -q '\[ERROR\]'; then
        fail "dbt parse exited $exit_code" "$clean"
    fi

    warning_count=$(echo "$clean" | grep -c '\[WARNING\]' || true)

    # report
    if [ "$warning_count" -gt 0 ]; then
        echo "PASS with $warning_count warning(s):"
        echo ""
        echo "$clean" | grep -v '^$' | grep -v 'Running with dbt=' | grep -v 'Registered adapter' | grep -v 'Performance info' | grep -v 'partial parsing'
        echo ""
        echo "---"
        echo "These are warnings, not errors. Review before upgrading."
    else
        echo "PASS: All packages parsed cleanly. No warnings."
    fi

# Check upstream repos for newer versions
pkg-check-updates:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking upstream for newer versions..."
    echo ""
    grep -E '^\s{2}\w' manifest.yml | sed 's/://' | while read pkg; do
        upstream=$(grep -A1 "^  ${pkg}:" manifest.yml | grep 'upstream:' | awk '{print $2}')
        current=$(grep -A2 "^  ${pkg}:" manifest.yml | grep 'version:' | sed 's/.*"\(.*\)"/\1/')
        latest=$(gh api "repos/$upstream/releases/latest" --jq '.tag_name' 2>/dev/null || echo "?")
        if [ "$latest" = "$current" ] || [ "v$current" = "$latest" ]; then
            printf "  %-25s %s (up to date)\n" "$pkg" "$current"
        else
            printf "  %-25s %s -> %s (UPDATE AVAILABLE)\n" "$pkg" "$current" "$latest"
        fi
    done
