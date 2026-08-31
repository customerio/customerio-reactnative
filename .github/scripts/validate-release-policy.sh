#!/usr/bin/env bash
set -euo pipefail

: "${PR_TITLE:?PR_TITLE is required}"
: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
: "${HEAD_REPOSITORY:?HEAD_REPOSITORY is required}"
: "${TARGET_REPOSITORY:?TARGET_REPOSITORY is required}"
: "${PR_AUTHOR:?PR_AUTHOR is required}"

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

pr_message="$PR_TITLE"$'\n\n'"${PR_BODY:-}"
pr_release=false
commit_release=false

if is_release_message "$pr_message"; then
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
requires_full_label=false

if [[ "$pr_release" == 'true' || "$commit_release" == 'true' || "${CI_FULL:-false}" == 'true' ]]; then
  full_validation=true
fi

if [[ "$commit_release" == 'true' && "$pr_release" != 'true' && "${CI_FULL:-false}" != 'true' ]]; then
  requires_full_label=true
fi

if [[ ("$pr_release" == 'true' || "$commit_release" == 'true') && ("$HEAD_REPOSITORY" != "$TARGET_REPOSITORY" || "$PR_AUTHOR" == 'dependabot[bot]') ]]; then
  echo "::error::Release-bearing PRs require secret-dependent validation from a trusted repository branch. Recreate or update this change on an internal branch before merge."
  exit 1
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "pr_release=$pr_release"
    echo "commit_release=$commit_release"
    echo "full_validation=$full_validation"
    echo "requires_full_label=$requires_full_label"
  } >> "$GITHUB_OUTPUT"
fi

if [[ "$requires_full_label" == 'true' ]]; then
  echo "::notice::A release-bearing commit was detected behind a non-release PR title. The semantic PR helper will apply ci:full automatically."
fi

echo "Release validation policy satisfied (pr_release=$pr_release, commit_release=$commit_release, full_validation=$full_validation)."
