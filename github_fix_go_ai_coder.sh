#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HOME}/github-org/go-ai-coder"
MODULE_PATH="github.com/Bakery-street-project/go-ai-coder"

echo "[*] Fixing go-ai-coder repo at: ${REPO_DIR}"

if [ ! -d "${REPO_DIR}" ]; then
  echo "[!] Repo not found at ${REPO_DIR}" >&2
  exit 1
fi

cd "${REPO_DIR}"

###############################################################################
# 1) Ensure go.mod module path is correct
###############################################################################

if [ ! -f go.mod ]; then
  echo "[!] go.mod missing. Initializing..."
  go mod init "${MODULE_PATH}"
else
  echo "[*] go.mod exists. Ensuring module path is ${MODULE_PATH}"
  CURRENT_MODULE=$(grep '^module ' go.mod | awk '{print $2}')
  if [ "${CURRENT_MODULE}" != "${MODULE_PATH}" ]; then
    echo "[*] Updating module path from ${CURRENT_MODULE} to ${MODULE_PATH}"
    sed -i "s|^module .*|module ${MODULE_PATH}|" go.mod
  fi
fi

###############################################################################
# 2) Fix read.go first line (expected 'package', found 'reapackage')
###############################################################################

if [ -f read.go ]; then
  FIRST_LINE=$(sed -n '1p' read.go || true)
  if ! echo "${FIRST_LINE}" | grep -q '^package '; then
    echo "[*] Fixing first line of read.go (was: ${FIRST_LINE})"
    # Default to package main; adjust if you want a different package.
    tmpfile=$(mktemp)
    {
      echo "package main"
      sed -n '2,$p' read.go
    } > "${tmpfile}"
    mv "${tmpfile}" read.go
  else
    echo "[*] read.go already has a valid package line: ${FIRST_LINE}"
  fi
else
  echo "[*] read.go not found, skipping package fix."
fi

###############################################################################
# 3) Create internal/cloudai package with NewCloudAIClient
###############################################################################

mkdir -p internal/cloudai

cat > internal/cloudai/client.go <<'EOF_INNER'
package cloudai

import "fmt"

// Client is a placeholder for your Cloud AI client configuration.
type Client struct {
	// TODO: add config fields (API keys, endpoints, etc.)
}

// NewCloudAIClient creates and returns a new Cloud AI client.
func NewCloudAIClient() (*Client, error) {
	fmt.Println("Initializing Cloud AI client...")
	return &Client{}, nil
}
EOF_INNER

###############################################################################
# 4) Create cmd/go-ai-coder/main.go entrypoint
###############################################################################

mkdir -p cmd/go-ai-coder

cat > cmd/go-ai-coder/main.go <<'EOF_INNER'
package main

import (
	"log"

	"github.com/Bakery-street-project/go-ai-coder/internal/cloudai"
)

func main() {
	// Initialize the Cloud AI client from the internal package.
	client, err := cloudai.NewCloudAIClient()
	if err != nil {
		log.Fatalf("failed to initialize Cloud AI client: %v", err)
	}

	// TODO: use client for the rest of your workflow.
	_ = client
}
EOF_INNER

###############################################################################
# 5) Go sanity checks: list + build
###############################################################################

echo "[*] Running go list ./..."
go list ./...

echo "[*] Building cmd/go-ai-coder..."
go build -o go-ai-coder ./cmd/go-ai-coder

echo "[*] Binary built at: ${REPO_DIR}/go-ai-coder"

###############################################################################
# 6) Commit and push with gh-friendly message
###############################################################################

if git status --porcelain | grep -q .; then
  echo "[*] Committing changes..."
  git add go.mod read.go internal/cloudai/client.go cmd/go-ai-coder/main.go || true
  git commit -m "fix: repair Go entrypoint and internal cloudai client"
  git push
else
  echo "[*] No changes to commit."
fi

echo "[✓] go-ai-coder repo fixed and built successfully."
