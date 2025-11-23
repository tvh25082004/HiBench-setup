#!/bin/bash
# Wrapper script để analyze workflow từ logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOGS_DIR="${PROJECT_ROOT}/logs"
ANALYZER="${SCRIPT_DIR}/analyze-log-workflow.py"

if [ ! -d "$LOGS_DIR" ]; then
    echo "❌ Thư mục logs không tồn tại: $LOGS_DIR"
    echo "   Hãy chạy benchmark trước để tạo logs"
    exit 1
fi

if [ ! -f "$ANALYZER" ]; then
    echo "❌ Analyzer script không tìm thấy: $ANALYZER"
    exit 1
fi

# Nếu có tham số, analyze các file cụ thể
if [ $# -gt 0 ]; then
    python3 "$ANALYZER" "$@"
else
    # Analyze tất cả logs trong thư mục
    if [ -n "$(ls -A "$LOGS_DIR"/*.log 2>/dev/null)" ]; then
        echo "📊 Analyzing all logs in $LOGS_DIR..."
        python3 "$ANALYZER" --dir "$LOGS_DIR"
    else
        echo "❌ Không tìm thấy log files trong $LOGS_DIR"
        echo "   Hãy chạy benchmark trước: make wordcount"
        exit 1
    fi
fi
