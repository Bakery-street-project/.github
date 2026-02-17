#!/usr/bin/env bash
set -euo pipefail

ORG="Bakery-street-project"
REPO="go-ai-coder"
REPO_DIR="${HOME}/github-org/${REPO}"
QUESTIONS_FILE="research/questions.md"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}

require_cmd gh
require_cmd git
require_cmd date

if [ ! -d "${REPO_DIR}" ]; then
  echo "[*] Cloning ${ORG}/${REPO}..."
  mkdir -p "${HOME}/github-org"
  gh repo clone "${ORG}/${REPO}" "${REPO_DIR}"
fi

cd "${REPO_DIR}"

mkdir -p research

if [ ! -f "${QUESTIONS_FILE}" ]; then
  cat > "${QUESTIONS_FILE}" <<'EOF_MD'
# Research Questions Log

Each entry tracks one research question, context, and evolving answers.

EOF_MD
fi

QUESTION="${1:-}"

if [ -z "${QUESTION}" ]; then
  echo "Usage: $0 \"Your research question here\"" >&2
  exit 1
fi

DATE_STR="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
QID="Q$(date -u +'%Y%m%d%H%M%S')"

cat >> "${QUESTIONS_FILE}" <<EOF_MD

---

## ${QID} — ${QUESTION}

- Opened: ${DATE_STR}
- Status: open
- Tags: TODO

### Context

- TODO: add context, links, code pointers.

### Notes / Partial Answers

- TODO: first notes.

### Final Answer (when ready)

- TODO
EOF_MD

git add "${QUESTIONS_FILE}"

if git status --porcelain | grep -q .; then
  git commit -m "research: add question ${QID}"
  git push -u origin main

  gh issue create \
    --title "Research: ${QUESTION}" \
    --body "See ${QUESTIONS_FILE} entry ${QID} for context and evolving answers." \
    --label "research" || true
fi

echo "[✓] Recorded research question ${QID}: ${QUESTION}"
