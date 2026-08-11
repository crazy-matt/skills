#!/usr/bin/env bash
set -eEuo pipefail
shopt -s nullglob inherit_errexit

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! git diff --quiet HEAD -- scripts/generate-plugin-manifests.sh; then
  echo "uncommitted changes: they would be discarded. Commit or stash first." >&2
  git status --short >&2
  exit 1
fi

git checkout main
git fetch upstream
git reset --hard upstream/main
git checkout main@{1} -- scripts/generate-plugin-manifests.sh

bucket_desc() {
  local readme="skills/$1/README.md"
  local desc
  desc=$(awk '/^# / { found=1; next } found && NF { print; exit }' "$readme")
  if [[ -z "$desc" ]]; then
    echo "no description in $readme (expected first paragraph after H1)" >&2
    exit 1
  fi
  printf '[skills bucket] %s' "$desc"
}

skill_desc() {
  local desc
  desc=$(sed -n 's/^description: //p' "$1/SKILL.md" | head -1)
  if [[ -z "$desc" ]]; then
    echo "no description in $1/SKILL.md frontmatter" >&2
    exit 1
  fi
  printf '%s' "$desc"
}

buckets=()
for d in skills/*/; do
  b=$(basename "$d")
  [[ "$b" == "personal" || "$b" == "deprecated" ]] && continue
  buckets+=("$b")
done

skill_dirs=()
for b in "${buckets[@]}"; do
  for s in "skills/$b"/*/; do
    [[ -f "$s/SKILL.md" ]] || continue
    skill_dirs+=("${s%/}")
  done
done

for s in "${skill_dirs[@]}"; do
  mkdir -p "$s/.claude-plugin"
  jq -n \
    --arg name "$(basename "$s")" \
    --arg desc "$(skill_desc "$s")" \
    '{name: $name, description: $desc, skills: ["./"]}' \
    > "$s/.claude-plugin/plugin.json"
done

for b in "${buckets[@]}"; do
  skills_json=$(
    for s in "skills/$b"/*/; do
      [[ -f "$s/SKILL.md" ]] || continue
      printf '%s\n' "./$(basename "$s")"
    done | jq -R . | jq -s .
  )
  mkdir -p "skills/$b/.claude-plugin"
  jq -n \
    --arg name "$b" \
    --arg desc "$(bucket_desc "$b")" \
    --argjson skills "$skills_json" \
    '{name: $name, description: $desc, skills: $skills}' \
    > "skills/$b/.claude-plugin/plugin.json"
done

{
  jq -n --arg desc "[all skills] Matt Pocock's production ready skills" \
    '{name: "mattpocock-skills", source: "./", description: $desc}'
  for b in "${buckets[@]}"; do
    jq -n \
      --arg name "$b" \
      --arg src "./skills/$b" \
      --arg desc "$(bucket_desc "$b")" \
      '{name: $name, source: $src, description: $desc}'
  done
  for s in "${skill_dirs[@]}"; do
    jq -n \
      --arg name "$(basename "$s")" \
      --arg src "./$s" \
      --arg desc "$(skill_desc "$s")" \
      '{name: $name, source: $src, description: $desc}'
  done
} | jq -s \
  --arg market_desc "Matt Pocock's Claude Code skills, packaged as a marketplace by crazy-matt" \
  '{
    name: "crazy-matt-mattpocock-skills",
    description: $market_desc,
    owner: {name: "Matt Pocock", url: "https://github.com/mattpocock"},
    plugins: .
  }' > .claude-plugin/marketplace.json

jq -e '[.plugins[].name] | length == (unique | length)' .claude-plugin/marketplace.json > /dev/null || {
  echo "duplicate plugin names in marketplace.json (a skill collides with a bucket or another skill)" >&2
  exit 1
}

git add -A
git commit -m "Regenerate plugin manifests after upstream sync"
git push origin main --force-with-lease

echo -e "\nSyncing complete."
