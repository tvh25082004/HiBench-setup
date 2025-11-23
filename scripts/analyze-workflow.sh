#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOGS_DIR="${PROJECT_ROOT}/logs"
ANALYZER="${SCRIPT_DIR}/analyze-log-workflow.py"

if [ ! -d "$LOGS_DIR" ]; then
    echo "❌ Logs directory does not exist: $LOGS_DIR"
    echo "   Please run benchmark first to create logs"
    exit 1
fi

if [ ! -f "$ANALYZER" ]; then
    echo "❌ Analyzer script not found: $ANALYZER"
    exit 1
fi

if [ $# -gt 0 ]; then
    python3 "$ANALYZER" "$@"
else
  
    if [ -n "$(ls -A "$LOGS_DIR"/*.log 2>/dev/null)" ]; then
        echo "📊 Analyzing all logs in $LOGS_DIR..."
        python3 "$ANALYZER" --dir "$LOGS_DIR"
    else
        echo "❌ No log files found in $LOGS_DIR"
        echo "   Please run benchmark first: make wordcount"
        exit 1
    fi
fi
