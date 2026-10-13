#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🚀 Starting Shark in Hot-Reload Development Mode..."
chmod +x scripts/hot_reload.py
python3 scripts/hot_reload.py
