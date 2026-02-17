#!/usr/bin/env bash
set -euo pipefail

USER="BoozeLee"
ORG="Bakery-street-project"

REPOS=(
  "Bakery-street-project/go-ai-coder"
  "Bakery-street-project/bakery-street-project.github.io"
)

echo "[*] Verifying GitHub metadata for user=${USER}, org=${ORG}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}
require_cmd gh
require_cmd git

###############################################################################
### 1) Verify .github repos exist and have FUNDING.yml ########################
###############################################################################

echo "[*] Checking ${USER}/.github"
gh repo view "${USER}/.github" --json name,defaultBranchRef || {
  echo "[!] ${USER}/.github not accessible"
}
USER_DIR="${HOME}/github-meta/${USER}-dot-github"
if [ -f "${USER_DIR}/.github/FUNDING.yml" ]; then
  echo "[✓] User FUNDING.yml present: ${USER_DIR}/.github/FUNDING.yml"
else
  echo "[!] Missing user FUNDING.yml at ${USER_DIR}/.github/FUNDING.yml"
fi

echo "[*] Checking ${ORG}/.github"
gh repo view "${ORG}/.github" --json name,defaultBranchRef || {
  echo "[!] ${ORG}/.github not accessible"
}
ORG_DIR="${HOME}/github-meta/${ORG}-dot-github"
if [ -f "${ORG_DIR}/.github/FUNDING.yml" ]; then
  echo "[✓] Org FUNDING.yml present: ${ORG_DIR}/.github/FUNDING.yml"
else
  echo "[!] Missing org FUNDING.yml at ${ORG_DIR}/.github/FUNDING.yml"
fi

###############################################################################
### 2) Verify repo-level files (FUNDING, SECURITY, CODEOWNERS, templates) #####
###############################################################################

for FULL in "${REPOS[@]}"; do
  OWNER="${FULL%%/*}"
  REPO="${FULL##*/}"
  echo "[*] Verifying repo: ${OWNER}/${REPO}"

  BASE="${HOME}/github-org/${REPO}"
  if [ ! -d "${BASE}/.git" ]; then
    echo "    - Local clone missing, cloning now..."
    mkdir -p "${HOME}/github-org"
    cd "${HOME}/github-org"
    gh repo clone "${OWNER}/${REPO}"
  fi

  cd "${HOME}/github-org/${REPO}"

  for f in ".github/FUNDING.yml" "SECURITY.md" ".github/CODEOWNERS"; do
    if [ -f "$f" ]; then
      echo "    [✓] $f present"
    else
      echo "    [!] $f missing"
    fi
  done

  # Optional: templates check
  for t in ".github/ISSUE_TEMPLATE.md" ".github/PULL_REQUEST_TEMPLATE.md"; do
    if [ -f "$t" ]; then
      echo "    [✓] $t present"
    fi
  done
done

###############################################################################
### 3) Print browser URLs for manual Sponsor button check #####################
###############################################################################

echo
echo "[*] Now open these URLs in your browser to confirm Sponsor and UI:"
echo "  - https://github.com/${USER}"
echo "  - https://github.com/orgs/${ORG}"
echo "  - https://github.com/${ORG}/go-ai-coder"
echo "  - https://github.com/${ORG}/bakery-street-project.github.io"
echo "Check that:"
echo "  - The Sponsor button is visible where expected."
echo "  - It points to your GitHub Sponsors / monetization URLs."
echo "  - Repo headers look professional (security, templates present)."

echo "[✓] Verification script finished."
