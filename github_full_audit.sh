#!/usr/bin/env bash
set -euo pipefail

USER="BoozeLee"
ORG="Bakery-street-project"
MONETIZATION_URL="https://bakery-street-project.github.io/#monetization"

ENABLE_SECRET_SCANNING="true"
ENABLE_SECRET_PUSH_PROTECTION="true"
ENABLE_CODE_SCANNING_DEFAULT_SETUP="true"  # flip off if plan doesn’t support CodeQL default setup

AUDIT_REPORT="${HOME}/github-org/github_audit_report.txt"

echo "[*] Intelligent GitHub audit & hardening agent for ${ORG} (user=${USER})"
echo "[*] Writing audit report to: ${AUDIT_REPORT}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}
require_cmd gh
require_cmd git
mkdir -p "$(dirname "${AUDIT_REPORT}")"
: > "${AUDIT_REPORT}"

###############################################################################
### 1) Discover all repos (public + private) ##################################
###############################################################################

echo "[*] Discovering all repos for ${ORG} via gh repo list..."
MAPFILE -t ALL_REPOS < <(gh repo list "${ORG}" -L 200 --json name,visibility,isPrivate,isArchived --jq '.[] | select(.isArchived==false) | .name')
echo "[*] Found ${#ALL_REPOS[@]} active repos."

###############################################################################
### 2) Ensure profile/org .github defaults as before ##########################
###############################################################################

# You can reuse the earlier github_security_agent.sh for profile/org;
# here we focus on per-repo “intelligent” work.

###############################################################################
### 3) Per-repo inspection + hardening ########################################
###############################################################################

for REPO in "${ALL_REPOS[@]}"; do
  FULL="${ORG}/${REPO}"
  echo
  echo "===== ${FULL} =====" | tee -a "${AUDIT_REPORT}"

  mkdir -p "${HOME}/github-org" && cd "${HOME}/github-org"

  if [ ! -d "${REPO}/.git" ]; then
    echo "[*] Cloning ${FULL}"
    gh repo clone "${FULL}" "${REPO}"
  fi

  cd "${REPO}"
  git fetch origin >/dev/null 2>&1 || true
  DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
  git checkout "${DEFAULT_BRANCH}" >/dev/null 2>&1 || git checkout -b main

  mkdir -p .github

  ### 3.1 FUNDING & MONETIZATION ##############################################
  FUNDING_STATUS="present"
  if [ ! -f ".github/FUNDING.yml" ]; then
    FUNDING_STATUS="missing -> created"
    cat > .github/FUNDING.yml <<EOF
github: ${USER}
custom:
  - "${MONETIZATION_URL}"
EOF
    git add .github/FUNDING.yml
  fi

  ### 3.2 SECURITY & CODEOWNERS ###############################################
  SECURITY_STATUS="present"
  if [ ! -f "SECURITY.md" ]; then
    SECURITY_STATUS="missing -> created"
    cat > SECURITY.md <<'EOF'
# Security

If you discover a security issue, please report it privately via
GitHub Security Advisories or the contact listed in the organization profile.
Avoid posting sensitive details in public issues or discussions.
EOF
    git add SECURITY.md
  fi

  CODEOWNERS_STATUS="present"
  if [ ! -f ".github/CODEOWNERS" ]; then
    CODEOWNERS_STATUS="missing -> created"
    cat > .github/CODEOWNERS <<EOF
# Default code owners for ${FULL}
*       @${USER}
EOF
    git add .github/CODEOWNERS
  fi

  ### 3.3 ISSUE/PR TEMPLATES (optional, best-effort) ##########################
  ISSUE_TEMPLATE_STATUS="present"
  if [ ! -f ".github/ISSUE_TEMPLATE.md" ]; then
    ISSUE_TEMPLATE_STATUS="missing"
  fi

  PR_TEMPLATE_STATUS="present"
  if [ ! -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
    PR_TEMPLATE_STATUS="missing"
  fi

  if git status --porcelain | grep -q .; then
    git commit -m "chore: add funding/security/CODEOWNERS metadata" || true
    git push origin "${DEFAULT_BRANCH}" || true
  fi

  ### 3.4 Branch protection (soft-fail) #######################################
  PROTECTION_STATUS="attempted"
  if gh api \
      --method PUT \
      -H "Accept: application/vnd.github+json" \
      "/repos/${ORG}/${REPO}/branches/${DEFAULT_BRANCH}/protection" \
      -f required_status_checks='null' \
      -f enforce_admins=true \
      -f required_pull_request_reviews.required_approving_review_count=1 \
      -f restrictions='null' >/dev/null 2>&1; then
    PROTECTION_STATUS="enabled"
  else
    PROTECTION_STATUS="failed (token/plan/permissions)"
  fi

  ### 3.5 Secret scanning & push protection (soft-fail) #######################
  SECRET_STATUS="skipped"
  if [ "${ENABLE_SECRET_SCANNING}" = "true" ]; then
    SECRET_STATUS="attempted"
    SCAN_CFG='{"secret_scanning":{"status":"enabled"}'
    if [ "${ENABLE_SECRET_PUSH_PROTECTION}" = "true" ]; then
      SCAN_CFG+=',"secret_scanning_push_protection":{"status":"enabled"}'
    fi
    SCAN_CFG+='}'

    if gh api \
        --method PATCH \
        -H "Accept: application/vnd.github+json" \
        "/repos/${ORG}/${REPO}" \
        -f security_and_analysis="${SCAN_CFG}" >/dev/null 2>&1; then
      SECRET_STATUS="enabled (where supported)"
    else
      SECRET_STATUS="failed (plan/permissions)"
    fi
  fi

  ### 3.6 Code scanning default setup (CodeQL) ################################
  CODEQL_STATUS="skipped"
  if [ "${ENABLE_CODE_SCANNING_DEFAULT_SETUP}" = "true" ]; then
    CODEQL_STATUS="attempted"
    if gh api \
        --method PATCH \
        -H "Accept: application/vnd.github+json" \
        "/repos/${ORG}/${REPO}/code-scanning/default-setup" \
        -f state="configured" >/dev/null 2>&1; then
      CODEQL_STATUS="configured"
    else
      CODEQL_STATUS="failed (plan/permissions/runtime)"
    fi
  fi

  ### 3.7 Minimal “completion” audit for Marco01/Ollama #######################
  # This is where your local agent (Marco01 via Ollama) can read the report
  # and decide how to "finish" each project:
  #
  # - README quality
  # - presence of LICENSE
  # - TODO markers in code
  # - missing tests / CI workflows

  README_STATUS="present"
  [ -f "README.md" ] || README_STATUS="missing"
  LICENSE_STATUS="present"
  [ -f "LICENSE" ] || LICENSE_STATUS="missing"

  {
    echo "repo: ${FULL}"
    echo "  branch: ${DEFAULT_BRANCH}"
    echo "  funding: ${FUNDING_STATUS}"
    echo "  security_md: ${SECURITY_STATUS}"
    echo "  codeowners: ${CODEOWNERS_STATUS}"
    echo "  issue_template: ${ISSUE_TEMPLATE_STATUS}"
    echo "  pr_template: ${PR_TEMPLATE_STATUS}"
    echo "  branch_protection: ${PROTECTION_STATUS}"
    echo "  secret_scanning: ${SECRET_STATUS}"
    echo "  code_scanning_default_setup: ${CODEQL_STATUS}"
    echo "  readme: ${README_STATUS}"
    echo "  license: ${LICENSE_STATUS}"
    echo
  } >> "${AUDIT_REPORT}"

  cd ..
done

echo
echo "[*] Audit & hardening complete. Summary in:"
echo "    ${AUDIT_REPORT}"
echo
echo "[*] Next step for Marco01/Ollama:"
echo "  - Parse ${AUDIT_REPORT}"
echo "  - Identify repos with README=missing, LICENSE=missing, templates=missing"
echo "  - Propose or generate README/LICENSE/CI/test plans per repo"
echo
echo "[✓] Intelligent GitHub audit & hardening agent finished."
