#!/usr/bin/env bash
set -euo pipefail

SECURITY_AGENT="./github_security_agent.sh"
COMPLETION_AGENT="./github_completion_agent.sh"

echo "[*] Running security/audit agent..."
"${SECURITY_AGENT}"

echo
echo "[*] Running completion agent..."
"${COMPLETION_AGENT}"

echo
echo "[✓] All GitHub agents completed."
