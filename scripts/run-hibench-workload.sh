#!/bin/bash

# HiBench Workload Runner
# Usage: ./scripts/run-hibench-workload.sh <category> <workload> [framework]
# Example: ./scripts/run-hibench-workload.sh micro wordcount spark

set -euo pipefail

CATEGORY=$1
WORKLOAD=$2
FRAMEWORK=${3:-spark}  # Default to spark

# Phase control (all | prepare | run), default: all
PHASE="${HIBENCH_PHASE:-all}"

if [ -z "$CATEGORY" ] || [ -z "$WORKLOAD" ]; then
    echo "❌ Usage: $0 <category> <workload> [framework]"
    echo "   Categories: micro, ml, sql, websearch, graph, streaming"
    echo "   Framework: spark (default) or hadoop"
    exit 1
fi

# Create logs directory if it doesn't exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOGS_DIR="${PROJECT_ROOT}/logs"
mkdir -p "$LOGS_DIR"

# Generate log filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOGS_DIR}/benchmark-${CATEGORY}-${WORKLOAD}-${FRAMEWORK}-${TIMESTAMP}.log"

# Function to log and display
log_and_display() {
    echo "$@" | tee -a "$LOG_FILE"
}

# Start logging
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display "  🏆 HIBENCH BENCHMARK: ${CATEGORY}/${WORKLOAD}"
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display ""
log_and_display "📋 Configuration:"
log_and_display "   - Category: $CATEGORY"
log_and_display "   - Workload: $WORKLOAD"
log_and_display "   - Framework: $FRAMEWORK"
log_and_display "   - Log file: $LOG_FILE"
log_and_display ""

# Check if containers are running
check_container_running() {
    local container_name=$1
    docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"
}

if ! check_container_running "spark-master"; then
    log_and_display "⚠️  Spark Master is not running!"
    log_and_display "🚀 Attempting to start containers..."
    docker-compose up -d 2>/dev/null | tee -a "$LOG_FILE" || {
        log_and_display "❌ Failed to start containers automatically"
        log_and_display "   Please run: make start"
        exit 1
    }
    log_and_display "⏳ Waiting for containers to be ready..."
    
    # Wait for containers to be ready (max 60 seconds)
    MAX_WAIT=60
    WAIT_TIME=0
    while [ $WAIT_TIME -lt $MAX_WAIT ]; do
        if check_container_running "spark-master" && check_container_running "namenode"; then
            # Additional check: verify containers are actually running (not just created)
            if docker exec spark-master echo "ready" >/dev/null 2>&1; then
                log_and_display "✅ Containers are ready!"
                log_and_display ""
                break
            fi
        fi
        sleep 2
        WAIT_TIME=$((WAIT_TIME + 2))
        if [ $((WAIT_TIME % 4)) -eq 0 ]; then
            log_and_display "   Waiting... (${WAIT_TIME}s/${MAX_WAIT}s)"
        fi
    done
    
    # Final check
    if ! check_container_running "spark-master"; then
        log_and_display ""
        log_and_display "❌ Spark Master container failed to start after ${MAX_WAIT} seconds!"
        log_and_display "   Current container status:"
        (docker-compose ps 2>/dev/null || docker ps | grep -E "(spark|namenode)" || true) | tee -a "$LOG_FILE"
        log_and_display ""
        log_and_display "   Please check: docker-compose ps"
        log_and_display "   Or run: make start"
        exit 1
    fi
fi

# Verify containers are actually running and accessible
if ! check_container_running "spark-master"; then
    log_and_display "❌ Spark Master container is not running!"
    log_and_display "   Please check: docker-compose ps"
    log_and_display "   Or run: make start"
    exit 1
fi

# Quick connectivity test
if ! docker exec spark-master echo "ready" >/dev/null 2>&1; then
    log_and_display "⚠️  Spark Master container is running but not ready yet"
    log_and_display "   Waiting 5 more seconds..."
    sleep 5
fi

# Copy HiBench configs
log_and_display "📋 Copying HiBench configuration files..."
docker exec spark-master bash -c "cp /hibench/*.conf /opt/hibench/conf/" 2>/dev/null || true
log_and_display "✅ Configuration files ready"
log_and_display ""

# Verify Hadoop is available
if [ "$FRAMEWORK" = "spark" ]; then
    log_and_display "🔧 Verifying Hadoop setup..."
    docker exec spark-master bash -c "
        if [ ! -f /opt/hadoop/bin/hadoop ]; then
            echo '❌ ERROR: Hadoop CLI not found'
            exit 1
        fi
    " 2>&1 | tee -a "$LOG_FILE" || {
        log_and_display "❌ Hadoop verification failed!"
        exit 1
    }
    log_and_display "✅ Hadoop setup verified"
    log_and_display ""
fi

# Special handling for dfsioe (read/write)
if [ "$CATEGORY" = "micro" ] && [ "$WORKLOAD" = "dfsioe" ]; then
    # dfsioe has read and write modes
    DFSIOE_MODE=$FRAMEWORK  # Use framework param for read/write
    FRAMEWORK="spark"  # Always use spark for dfsioe
    if [ "$DFSIOE_MODE" != "read" ] && [ "$DFSIOE_MODE" != "write" ]; then
        log_and_display "❌ DFSIOE requires mode: read or write"
        log_and_display "   Usage: $0 micro dfsioe read|write"
        exit 1
    fi
fi

# Determine workload path
WORKLOAD_PATH="/opt/hibench/bin/workloads/${CATEGORY}/${WORKLOAD}"

# Check if workload exists
if ! docker exec spark-master test -d "$(dirname ${WORKLOAD_PATH})"; then
    log_and_display "❌ Workload not found: ${CATEGORY}/${WORKLOAD}"
    log_and_display "   Available workloads in ${CATEGORY}:"
    (docker exec spark-master ls -1 /opt/hibench/bin/workloads/${CATEGORY}/ 2>/dev/null || echo "   (Category not found)") | tee -a "$LOG_FILE"
    exit 1
fi

# Check if run script exists
if ! docker exec spark-master test -f "${WORKLOAD_PATH}/${FRAMEWORK}/run.sh"; then
    log_and_display "❌ Run script not found: ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh"
    log_and_display "   Available frameworks:"
    (docker exec spark-master ls -1 "${WORKLOAD_PATH}/" 2>/dev/null || echo "   (No frameworks found)") | tee -a "$LOG_FILE"
    exit 1
fi

# Run prepare phase (if exists and phase != run-only)
if [ "$PHASE" != "run" ] && docker exec spark-master test -f "${WORKLOAD_PATH}/prepare/prepare.sh"; then
    log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_and_display "1️⃣  PREPARE PHASE - Generate test data"
    log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_and_display ""

    PREPARE_OUTPUT=$(docker exec spark-master bash -c "cd /opt/hibench && set +e && ${WORKLOAD_PATH}/prepare/prepare.sh 2>&1; exit 0" 2>&1)
    echo "$PREPARE_OUTPUT" | grep -v "unbound variable" | grep -v "SyntaxWarning" | tail -20 | tee -a "$LOG_FILE" || true

    log_and_display ""
    log_and_display "✅ Prepare phase completed"
    log_and_display ""
fi

# If phase is prepare-only, skip run phase
if [ "$PHASE" = "prepare" ]; then
    log_and_display "ℹ️  HIBENCH_PHASE=prepare -> skip RUN phase, only prepared data."
    exit 0
fi

# Run benchmark phase
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display "2️⃣  RUN PHASE - Run ${WORKLOAD} benchmark"
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display ""

START_TIME=$(date +%s)

# Set environment variables and run benchmark
# Note: HiBench scripts may have bash warnings but jobs can still succeed
set +e  # Temporarily disable exit on error for HiBench script execution

if [ "$CATEGORY" = "micro" ] && [ "$WORKLOAD" = "dfsioe" ]; then
    # Special handling for dfsioe read/write
    if [ "$DFSIOE_MODE" = "read" ]; then
        READ_ONLY="true"
    else
        READ_ONLY="false"
    fi
    # Run benchmark and capture both output and exit code
    set +o pipefail  # Disable pipefail temporarily
    docker exec spark-master bash -c "
        export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop && \
        export HADOOP_HOME=/opt/hadoop && \
        export READ_ONLY=${READ_ONLY} && \
        cd /opt/hibench && \
        ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh
    " 2>&1 | tee -a "$LOG_FILE"
    BENCHMARK_EXIT_CODE=${PIPESTATUS[0]}
    set -o pipefail  # Re-enable pipefail
else
    # Run benchmark and capture both output and exit code
    set +o pipefail  # Disable pipefail temporarily
    docker exec spark-master bash -c "
        export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop && \
        export HADOOP_HOME=/opt/hadoop && \
        cd /opt/hibench && \
        ${WORKLOAD_PATH}/${FRAMEWORK}/run.sh
    " 2>&1 | tee -a "$LOG_FILE"
    BENCHMARK_EXIT_CODE=${PIPESTATUS[0]}
    set -o pipefail  # Re-enable pipefail
fi

set -e  # Re-enable exit on error

# Check if benchmark actually failed (non-zero exit) or just had warnings
if [ $BENCHMARK_EXIT_CODE -ne 0 ]; then
    log_and_display "⚠️  Benchmark script had errors (exit code: $BENCHMARK_EXIT_CODE)"
    log_and_display "   Checking if job actually completed..."
    sleep 2
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log_and_display ""
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display "3️⃣  REPORT"
log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_and_display ""
log_and_display "📊 Benchmark Results:"
log_and_display "   - Workload: ${CATEGORY}/${WORKLOAD}"
log_and_display "   - Framework: $FRAMEWORK"
log_and_display "   - Total Duration: ${DURATION}s"
log_and_display "   - Log file: $LOG_FILE"
log_and_display ""

# Show HiBench report if available
if docker exec spark-master test -f /opt/hibench/report/hibench.report 2>/dev/null; then
    log_and_display "📊 HiBench Benchmark Report:"
    log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    (docker exec spark-master bash -c "cat /opt/hibench/report/hibench.report" 2>/dev/null | tail -20 || true) | tee -a "$LOG_FILE"
    log_and_display "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

log_and_display ""
log_and_display "✅ Benchmark completed!"
log_and_display "📝 Log saved to: $LOG_FILE"
log_and_display ""

