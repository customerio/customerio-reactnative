#!/usr/bin/env bash
set -euo pipefail

: "${PR_TITLE:?PR_TITLE is required}"
: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
is_release_message() {
  local message="$1"
  local header
  header=$(sed -n '/[^[:space:]]/{p;q;}' <<< "$message")

  case "$header" in
    fix:*|fix\(*|feat:*|feat\(*|perf:*|perf\(*|revert:*|revert\(*|Revert\ \"*)
      return 0
      ;;
  esac

  if grep -Eq '^[[:alpha:]]+(\([^)]*\))?!:' <<< "$header"; then
    return 0
  fi

  if grep -Eq '(^|[[:space:]])(BREAKING CHANGES?:|BREAKING-CHANGE:)' <<< "$message"; then
    return 0
  fi

  if grep -Eq '(^|[[:space:]])This reverts commit[[:space:]]' <<< "$message"; then
    return 0
  fi

  return 1
}

pr_release=false
commit_release=false

if is_release_message "$PR_TITLE"; then
  pr_release=true
fi

git cat-file -e "$BASE_SHA^{commit}"
git cat-file -e "$HEAD_SHA^{commit}"
commit_messages_file=$(mktemp)
trap 'rm -f "$commit_messages_file"' EXIT
git log --format='%B%x00' "$BASE_SHA..$HEAD_SHA" > "$commit_messages_file"

while IFS= read -r -d '' commit_message; do
  if is_release_message "$commit_message"; then
    commit_release=true
    break
  fi
done < "$commit_messages_file"

full_validation=false

if [[ "$pr_release" == 'true' || "$commit_release" == 'true' || "${CI_FULL:-false}" == 'true' ]]; then
  full_validation=true
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "pr_release=$pr_release"
    echo "commit_release=$commit_release"
    echo "full_validation=$full_validation"
  } >> "$GITHUB_OUTPUT"
fi

echo "Distribution policy classified (pr_release=$pr_release, commit_release=$commit_release, full_validation=$full_validation)."
