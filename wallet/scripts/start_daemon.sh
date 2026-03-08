#!/usr/bin/env bash
set -euo pipefail
DATADIR="${HOME}/.electrum-main"
mkdir -p "$DATADIR"
electrum setconfig rpcport 7000
electrum setconfig rpchost "127.0.0.1"
electrum daemon -d -D "$DATADIR"
