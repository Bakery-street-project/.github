#!/usr/bin/env bash
set -euo pipefail
TARGET="$1"
OUTDIR="runs/$(date +%Y%m%d)-$TARGET"
mkdir -p "$OUTDIR"
amass enum -d "$TARGET" -o "$OUTDIR/subdomains.txt"
httpx -l "$OUTDIR/subdomains.txt" -o "$OUTDIR/httpx.txt"
