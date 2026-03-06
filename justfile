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
pkg-release-notes:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "| Package | Version |"
    echo "|---|---|"
    grep -E '^\s{2}\w' manifest.yml | sed 's/://' | while read pkg; do
        version=$(grep -A2 "^  ${pkg}:" manifest.yml | grep 'version:' | sed 's/.*"\(.*\)"/\1/')
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
    tag="${{ if version != "" { version } else { "$(just next-version)" } }}"
    branch="release/$tag"
    notes=$(just pkg-release-notes)
    echo ""
    echo "=== PR for $tag ==="
    echo ""
    echo "$notes"
    echo ""
    git checkout -b "$branch"
    git add -A
    printf '%s vendored package bundle\n\n%s\n' "$tag" "$notes" | git commit -F -
    git push -u origin "$branch"
    gh pr create --title "$tag" --body "$notes"
    echo ""
    echo "PR created. After merge, run: just pkg-release-tag $tag"

# Tag and release after PR merge (usage: just pkg-release-tag [version])
pkg-release-tag version="":
    #!/usr/bin/env bash
    set -euo pipefail
    tag="${{ if version != "" { version } else { "$(just next-version)" } }}"
    if git rev-parse "$tag" >/dev/null 2>&1; then
        echo "Tag $tag already exists."
        exit 1
    fi
    notes=$(just pkg-release-notes)
    git checkout main
    git pull origin main
    git tag "$tag"
    git push origin "$tag"
    gh release create "$tag" --title "$tag" --notes "$notes"
    echo ""
    echo "Done. Consumer repos should use: revision: $tag"

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
