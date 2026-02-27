.DEFAULT_GOAL := help

# ──────────────────────────────────────────────
# Package management
# ──────────────────────────────────────────────

.PHONY: update
update: ## Update a package: make update pkg=dbt_utils repo=dbt-labs/dbt-utils tag=1.2.0
	@test -n "$(pkg)" || (echo "Usage: make update pkg=<name> repo=<owner/repo> tag=<version>" && exit 1)
	@test -n "$(repo)" || (echo "Usage: make update pkg=<name> repo=<owner/repo> tag=<version>" && exit 1)
	@test -n "$(tag)" || (echo "Usage: make update pkg=<name> repo=<owner/repo> tag=<version>" && exit 1)
	@./scripts/update_package.sh $(pkg) $(repo) $(tag)
	@echo ""
	@echo "REMINDER: update manifest.yml with the new version for $(pkg)"

.PHONY: verify
verify: ## Verify no Python manifest files exist in any package
	@echo "Checking for Python manifest files..."
	@found=$$(find . -not -path './.git/*' \( \
		-name "setup.py" -o -name "setup.cfg" -o -name "pyproject.toml" \
		-o -name "requirements.txt" -o -name "dev-requirements.txt" \
		-o -name "poetry.lock" -o -name "uv.lock" \
		-o -name "Pipfile" -o -name "Pipfile.lock" \
	\) -type f); \
	if [ -n "$$found" ]; then \
		echo "FAIL: Python manifest files found:" && echo "$$found" && exit 1; \
	else \
		echo "PASS: No Python manifest files found."; \
	fi

# ──────────────────────────────────────────────
# Release workflow
# ──────────────────────────────────────────────

.PHONY: pr
pr: verify ## Create a PR for package updates: make pr [v=2026.03]
	@tag=$${v:-$$(date +%Y.%m)}; \
	branch="release/$$tag"; \
	notes=$$($(MAKE) -s release-notes); \
	echo ""; \
	echo "=== PR for $$tag ==="; \
	echo ""; \
	echo "$$notes"; \
	echo ""; \
	git checkout -b "$$branch" && \
	git add -A && \
	printf '%s vendored package bundle\n\n%s\n' "$$tag" "$$notes" | git commit -F - && \
	git push -u origin "$$branch" && \
	gh pr create --title "$$tag" --body "$$notes" && \
	echo "" && \
	echo "PR created. After merge, run: make tag v=$$tag"

.PHONY: tag
tag: ## Tag and release after PR merge: make tag v=2026.03
	@test -n "$(v)" || (echo "Usage: make tag v=<calver>" && exit 1)
	@tag=$(v); \
	if git rev-parse "$$tag" >/dev/null 2>&1; then \
		echo "Tag $$tag already exists. Use a different version (e.g., $$tag.1)"; \
		exit 1; \
	fi; \
	notes=$$($(MAKE) -s release-notes); \
	git checkout main && \
	git pull origin main && \
	git tag "$$tag" && \
	git push origin "$$tag" && \
	gh release create "$$tag" --title "$$tag" --notes "$$notes" && \
	echo "" && \
	echo "Done. Consumer repos should use: revision: $$tag"

.PHONY: release-notes
release-notes: ## Generate release notes from manifest.yml (used by 'make release')
	@echo "| Package | Version |"; \
	echo "|---|---|"; \
	grep -E '^\s{2}\w' manifest.yml | sed 's/://' | while read pkg; do \
		version=$$(grep -A2 "^  $$pkg:" manifest.yml | grep 'version:' | sed 's/.*"\(.*\)"/\1/'); \
		echo "| $$pkg | $$version |"; \
	done; \
	echo ""; \
	echo "Python manifest files stripped to prevent Dependabot CVE alerts."

# ──────────────────────────────────────────────
# Upstream checks
# ──────────────────────────────────────────────

.PHONY: check-updates
check-updates: ## Check upstream repos for newer versions
	@echo "Checking upstream for newer versions..."; \
	echo ""; \
	grep -E '^\s{2}\w' manifest.yml | sed 's/://' | while read pkg; do \
		upstream=$$(grep -A1 "^  $$pkg:" manifest.yml | grep 'upstream:' | awk '{print $$2}'); \
		current=$$(grep -A2 "^  $$pkg:" manifest.yml | grep 'version:' | sed 's/.*"\(.*\)"/\1/'); \
		latest=$$(gh api "repos/$$upstream/releases/latest" --jq '.tag_name' 2>/dev/null || echo "?"); \
		if [ "$$latest" = "$$current" ] || [ "v$$current" = "$$latest" ]; then \
			printf "  %-25s %s (up to date)\n" "$$pkg" "$$current"; \
		else \
			printf "  %-25s %s -> %s (UPDATE AVAILABLE)\n" "$$pkg" "$$current" "$$latest"; \
		fi; \
	done

# ──────────────────────────────────────────────
# Shortcuts for common updates
# ──────────────────────────────────────────────

.PHONY: update-dbt-utils
update-dbt-utils: ## Update dbt_utils: make update-dbt-utils tag=1.2.0
	@$(MAKE) update pkg=dbt_utils repo=dbt-labs/dbt-utils tag=$(tag)

.PHONY: update-dbt-external-tables
update-dbt-external-tables: ## Update dbt_external_tables: make update-dbt-external-tables tag=0.13.0
	@$(MAKE) update pkg=dbt_external_tables repo=dbt-labs/dbt-external-tables tag=$(tag)

.PHONY: update-kae-dbt
update-kae-dbt: ## Update kae_dbt: make update-kae-dbt tag=0.6.0
	@$(MAKE) update pkg=kae_dbt repo=K12-Analytics-Engineering/kae_dbt tag=$(tag)

.PHONY: update-dbt-expectations
update-dbt-expectations: ## Update dbt_expectations: make update-dbt-expectations tag=0.11.0
	@$(MAKE) update pkg=dbt_expectations repo=calogica/dbt-expectations tag=$(tag)

.PHONY: update-dbt-date
update-dbt-date: ## Update dbt_date: make update-dbt-date tag=0.11.0
	@$(MAKE) update pkg=dbt_date repo=calogica/dbt-date tag=$(tag)

.PHONY: update-dbt-project-evaluator
update-dbt-project-evaluator: ## Update dbt_project_evaluator: make update-dbt-project-evaluator tag=v1.0.3
	@$(MAKE) update pkg=dbt_project_evaluator repo=dbt-labs/dbt-project-evaluator tag=$(tag)

# ──────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────

.PHONY: help
help: ## Show this help
	@echo "kae_dbt_packages"
	@echo ""
	@echo "Usage:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. make check-updates             # see what's new upstream"
	@echo "  2. make update-kae-dbt tag=0.6.0  # pull new version"
	@echo "  3. edit manifest.yml              # update the version"
	@echo "  4. make pr                        # verify, commit, push, open PR"
	@echo "  5. (review and merge PR)"
	@echo "  6. make tag v=2026.03             # tag main, create GH release"
