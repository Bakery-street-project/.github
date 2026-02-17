#!/usr/bin/env bash
set -euo pipefail

### CONFIG #####################################################################

USER="BoozeLee"
ORG="Bakery-street-project"
MONETIZATION_URL="https://bakery-street-project.github.io/#monetization"

# Key public repos to professionalize (extend as needed)
REPOS=(
  "Bakery-street-project/go-ai-coder"
  "Bakery-street-project/bakery-street-project.github.io"
)

# Enable secret scanning via API (requires appropriate plan/permissions)
ENABLE_SECRET_SCANNING="false"  # set to "true" when ready

###############################################################################
echo "[*] GitHub agent starting for user=${USER}, org=${ORG}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}
require_cmd gh
require_cmd git

###############################################################################
### 1) PROFILE .github REPO (USER-LEVEL) ######################################
###############################################################################

echo "[*] Ensuring user-level .github repo exists: ${USER}/.github"

if ! gh repo view "${USER}/.github" >/dev/null 2>&1; then
  gh repo create "${USER}/.github" \
    --private \
    --description ".github meta repo for ${USER} (funding, templates, etc.)" \
    --confirm
fi

mkdir -p "${HOME}/github-meta" && cd "${HOME}/github-meta"
if [ ! -d "${USER}-dot-github/.git" ]; then
  gh repo clone "${USER}/.github" "${USER}-dot-github"
fi

cd "${USER}-dot-github"

git fetch origin
DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
git checkout "${DEFAULT_BRANCH}" || git checkout -b main

mkdir -p .github

cat > .github/FUNDING.yml <<EOF
github: ${USER}
custom:
  - "${MONETIZATION_URL}"
EOF

cat > .github/CODE_OF_CONDUCT.md <<'EOF'
# Code of Conduct

This project follows a standard open source Code of Conduct.
Be respectful, constructive, and professional in all interactions.
EOF

cat > .github/CONTRIBUTING.md <<'EOF'
# Contributing

- Use feature branches and pull requests.
- Write clear commit messages.
- Add or update tests where relevant.
EOF

git add .github/FUNDING.yml .github/CODE_OF_CONDUCT.md .github/CONTRIBUTING.md
git commit -m "chore: add funding and community health files (user-level)" || true
git push origin "${DEFAULT_BRANCH}" || true

echo "[✓] User-level .github repo configured."

###############################################################################
### 2) ORG-LEVEL .github REPO #################################################
###############################################################################

echo "[*] Ensuring org-level .github repo exists: ${ORG}/.github"

if ! gh repo view "${ORG}/.github" >/dev/null 2>&1; then
  gh repo create "${ORG}/.github" \
    --public \
    --description ".github meta repo for ${ORG} (defaults, funding, templates, etc.)" \
    --confirm
fi

cd "${HOME}/github-meta"
if [ ! -d "${ORG}-dot-github/.git" ]; then
  gh repo clone "${ORG}/.github" "${ORG}-dot-github"
fi

cd "${ORG}-dot-github"
git fetch origin
DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
git checkout "${DEFAULT_BRANCH}" || git checkout -b main

mkdir -p .github

cat > .github/FUNDING.yml <<EOF
github: ${USER}
custom:
  - "${MONETIZATION_URL}"
EOF

cat > .github/SECURITY.md <<'EOF'
# Security Policy

- Report vulnerabilities privately via GitHub Security Advisories or email.
- Do not open public issues for undisclosed security problems.
EOF

cat > .github/ISSUE_TEMPLATE.md <<'EOF'
# Issue

- What happened?
- Expected behavior?
- Steps to reproduce?
EOF

cat > .github/PULL_REQUEST_TEMPLATE.md <<'EOF'
# Summary

- What does this PR do?

# Checklist

- [ ] Tests added/updated
- [ ] Docs updated if needed
EOF

git add .github/FUNDING.yml .github/SECURITY.md .github/ISSUE_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE.md
git commit -m "chore: add org-wide funding and community health files" || true
git push origin "${DEFAULT_BRANCH}" || true

echo "[✓] Org-level .github repo configured."

###############################################################################
### 3) PER-REPO SETUP (FUNDING + SECURITY + PROTECTION + SCANNING) ###########
###############################################################################

for FULL in "${REPOS[@]}"; do
  OWNER="${FULL%%/*}"
  REPO="${FULL##*/}"
  echo "[*] Processing repo: ${OWNER}/${REPO}"

  mkdir -p "${HOME}/github-org" && cd "${HOME}/github-org"

  if [ ! -d "${REPO}/.git" ]; then
    gh repo clone "${OWNER}/${REPO}"
  fi

  cd "${REPO}"

  git fetch origin
  DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
  git checkout "${DEFAULT_BRANCH}" || git checkout -b main

  mkdir -p .github

  # FUNDING (explicit)
  cat > .github/FUNDING.yml <<EOF
github: ${USER}
custom:
  - "${MONETIZATION_URL}"
EOF

  # SECURITY.md (per repo)
  cat > SECURITY.md <<'EOF'
# Security

If you discover a security issue, please report it privately via
GitHub Security Advisories or the contact listed in the organization profile.
EOF

  # Optional: CODEOWNERS skeleton to prepare for stricter protection
  cat > .github/CODEOWNERS <<EOF
# Default code owners for ${OWNER}/${REPO}
*       @${USER}
EOF

  git add .github/FUNDING.yml SECURITY.md .github/CODEOWNERS
  git commit -m "chore: add funding, security, and CODEOWNERS metadata" || true
  git push origin "${DEFAULT_BRANCH}" || true

  # Branch protection via API (soft-fail)
  echo "[*] Applying basic branch protection on ${OWNER}/${REPO}@${DEFAULT_BRANCH}"
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/${OWNER}/${REPO}/branches/${DEFAULT_BRANCH}/protection" \
    -f required_status_checks='null' \
    -f enforce_admins=true \
    -f required_pull_request_reviews.required_approving_review_count=1 \
    -f restrictions='null' >/dev/null 2>&1 || \
    echo "[!] Branch protection not applied – token/plan may lack 'Edit repository rules' or admin rights for ${OWNER}/${REPO}."

  # Optional: enable secret scanning if configured
  if [ "${ENABLE_SECRET_SCANNING}" = "true" ]; then
    echo "[*] Trying to enable secret scanning on ${OWNER}/${REPO}"
    gh api \
      --method PATCH \
      -H "Accept: application/vnd.github+json" \
      "/repos/${OWNER}/${REPO}" \
      -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}' \
      >/dev/null 2>&1 || \
      echo "[!] Could not enable secret scanning for ${OWNER}/${REPO} (plan/permissions may not support it)."
  fi

  cd ..
done

echo "[✓] Repo-level funding, security metadata, and baseline protection applied."

###############################################################################
### 4) PROFILE + ORG CHECKS ###################################################
###############################################################################

echo "[*] Verifying .github repos and funding files..."

gh repo view "${USER}/.github" --json name,defaultBranchRef || true
gh repo view "${ORG}/.github" --json name,defaultBranchRef || true

echo "[*] Check these in a browser once:"
echo "  - https://github.com/${USER}"
echo "  - https://github.com/orgs/${ORG}"
echo "  - https://github.com/${ORG}/go-ai-coder"
echo "  - https://github.com/${ORG}/bakery-street-project.github.io"
echo "Look for the Sponsor button on profile + repos and confirm metadata."

echo "[✓] GitHub agent run complete."
