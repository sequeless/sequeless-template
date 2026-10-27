#!/usr/bin/env bash
# Turn a fresh copy of the template into a new Sequeless repo. Run once, from the repo root:
#   scripts/init-repo.sh <repo-name> [--github]
# --github also applies the repo settings that a template does not copy (squash-only merges).
set -euo pipefail

cd "$(dirname "$0")/.."

name="${1:-}"
if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Usage: scripts/init-repo.sh <repo-name> [--github]   (lowercase letters, digits, dashes)" >&2
  exit 1
fi
apply_github="${2:-}"
pkgtail="${name//-/}"
repo="sequeless-$name"

# 1. Rename the placeholders in every tracked file except this script.
git ls-files -z | grep -zv '^scripts/init-repo\.sh$' | xargs -0 sed -i.bak \
  -e "s/org\.sequeless\.template/org.sequeless.$pkgtail/g" \
  -e "s#org/sequeless/template#org/sequeless/$pkgtail#g" \
  -e "s/template-core/$name-core/g" \
  -e "s/sequeless-template/$repo/g"
find . -name '*.bak' -not -path './.git/*' -delete

# 2. Rename the module directory and the Java package directories to match.
mv template-core "$name-core"
for side in main test; do
  src="$name-core/src/$side/java/org/sequeless/template"
  if [[ -d "$src" ]]; then mv "$src" "$name-core/src/$side/java/org/sequeless/$pkgtail"; fi
done

# 3. Replace the template's provenance and drop the template-only files.
cat > PROVENANCE.md <<PROV
# Provenance

- Created from: sequeless/sequeless-template@$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
- Source repo, source SHA, source paths, the move: fill in when code is moved in (#23)
- Date: $(date +%F)
PROV
rm -f docs/specs/stage-0-sequeless-template.md .github/workflows/template-smoke.yml
sed -i.bak '/^\.PHONY: init/,$d' Makefile && rm -f Makefile.bak

# 4. Optional: the repo settings a template does not copy.
if [[ "$apply_github" == "--github" ]]; then
  gh repo edit "sequeless/$repo" --enable-squash-merge --enable-merge-commit=false \
    --enable-rebase-merge=false --delete-branch-on-merge
  gh api -X PATCH "repos/sequeless/$repo" \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY >/dev/null
fi

rm -- "$0"
echo "Initialised $repo. Commit the result, then fill in PROVENANCE.md when code moves in."
