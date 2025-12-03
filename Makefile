# Makefile for HiBench Hadoop & Spark Setup
# Usage: make <command>

.PHONY: help setup start stop restart status logs clean check build shell-spark shell-hadoop test \
	wordcount sort terasort repartition dfsioe-read dfsioe-write \
	kmeans bayes lr svm als rf gbt linear gmm lda pca xgboost svd \
	scan join aggregation \
	pagerank nutchindexing \
	nweight micro-all micro-prepare-all micro-run-all-parallel \
	identity repartition-streaming wordcount-streaming \
	check-job logs-list logs-latest logs-view logs-clean

# Default target
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  HiBench Hadoop & Spark Docker Setup"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📦 Setup Commands:"
	@echo "  make setup        - Initialize and start everything (first time)"
	@echo "  make start        - Start containers"
	@echo "  make stop         - Stop containers"
	@echo "  make restart      - Restart all"
	@echo "  make clean        - Stop and remove everything (including volumes)"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status       - View container status"
	@echo "  make logs         - View logs of all services"
	@echo "  make check        - Check health of services"
	@echo "  make check-job    - Check WordCount job status"
	@echo ""
	@echo "📝 Benchmark Logs:"
	@echo "  make logs-list    - List all benchmark log files"
	@echo "  make logs-latest  - View latest benchmark log"
	@echo "  make logs-view    - View a specific log file"
	@echo "  make logs-clean   - Clean old log files"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make shell-spark  - Enter Spark Master shell"
	@echo "  make shell-hadoop - Enter Hadoop NameNode shell"
	@echo "  make test         - Run benchmark test (WordCount)"
	@echo ""
	@echo "📊 MICRO Benchmarks:"
	@echo "  make wordcount    - WordCount benchmark"
	@echo "  make sort         - Sort benchmark"
	@echo "  make terasort     - TeraSort benchmark"
	@echo "  make repartition  - Repartition benchmark"
	@echo "  make dfsioe-read  - DFSIOE Read benchmark"
	@echo "  make dfsioe-write - DFSIOE Write benchmark"
	@echo ""
	@echo "🧠 MACHINE LEARNING Benchmarks:"
	@echo "  make kmeans       - K-Means clustering"
	@echo "  make bayes        - Naive Bayes"
	@echo "  make lr           - Logistic Regression"
	@echo "  make svm          - Support Vector Machine"
	@echo "  make als          - Alternating Least Squares"
	@echo "  make rf           - Random Forest"
	@echo "  make gbt          - Gradient Boosted Trees"
	@echo "  make linear       - Linear Regression"
	@echo "  make gmm          - Gaussian Mixture Model"
	@echo "  make lda          - Latent Dirichlet Allocation"
	@echo "  make pca          - Principal Component Analysis"
	@echo "  make xgboost      - XGBoost"
	@echo "  make svd          - Singular Value Decomposition"
	@echo ""
	@echo "📊 SQL Benchmarks:"
	@echo "  make scan         - Scan benchmark"
	@echo "  make join         - Join benchmark"
	@echo "  make aggregation  - Aggregation benchmark"
	@echo ""
	@echo "🌐 WEB SEARCH Benchmarks:"
	@echo "  make pagerank     - PageRank algorithm"
	@echo "  make nutchindexing - Nutch Indexing"
	@echo ""
	@echo "🕸️  GRAPH Benchmarks:"
	@echo "  make nweight      - N-Weight graph algorithm"
	@echo ""
	@echo "⚡ STREAMING Benchmarks:"
	@echo "  make identity              - Identity streaming"
	@echo "  make repartition-streaming - Repartition streaming"
	@echo "  make wordcount-streaming   - WordCount streaming"
	@echo ""
	@echo "🌐 Web UIs:"
	@echo "  - Hadoop:  http://localhost:9870"
	@echo "  - Spark:   http://localhost:8080"
	@echo "  - Worker:  http://localhost:8081"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Docker is running
check:
	@echo "🔍 Checking Docker..."
	@docker info > /dev/null 2>&1 || (echo "❌ Docker is not running!" && exit 1)
	@echo "✅ Docker OK"
	@echo ""
	@echo "🔍 Checking Docker Compose..."
	@which docker-compose > /dev/null || (echo "❌ Docker Compose is not installed!" && exit 1)
	@echo "✅ Docker Compose OK"

# Initial setup (build + start + init)
setup: check
	@echo "🚀 Starting HiBench environment setup..."
	@./scripts/setup.sh

# Build images (if needed)
build:
	@echo "🔨 Building Docker images..."
	docker-compose build

# Start containers
start: check
	@echo "▶️  Starting containers..."
	docker-compose up -d
	@echo "✅ Containers started!"
	@echo ""
	@make status

# Stop containers
stop:
	@echo "⏹️  Stopping containers..."
	@./scripts/stop.sh

# Restart all
restart:
	@echo "🔄 Restarting all services..."
	docker-compose restart
	@echo "✅ Services restarted!"

# View status
status:
	@./scripts/status.sh

# View logs
logs:
	docker-compose logs -f

# Logs for each service
logs-spark:
	docker-compose logs -f spark-master

logs-hadoop:
	docker-compose logs -f namenode

logs-worker:
	docker-compose logs -f spark-worker

# Enter Spark Master shell
shell-spark:
	@echo "🐚 Connecting to Spark Master shell..."
	@echo "Tip: HiBench directory: /opt/hibench"
	@echo "Tip: Config files: /hibench/"
	docker exec -it spark-master bash

# Enter Hadoop NameNode shell
shell-hadoop:
	@echo "🐚 Connecting to Hadoop NameNode shell..."
	docker exec -it namenode bash

# Clean up (remove everything including volumes)
clean:
	@echo "🧹 Cleaning up everything..."
	@read -p "⚠️  Remove everything including HDFS data? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "✅ Cleaned!"; \
	else \
		echo "❌ Cancelled"; \
	fi

# Test with WordCount benchmark (Official HiBench)
test:
	@echo "🧪 Running Official HiBench WordCount benchmark test..."
	@bash test/hibench-official-wordcount.sh

# Quick test (only check connectivity)
test-quick:
	@echo "⚡ Quick connectivity test..."
	@echo "Testing HDFS..."
	docker exec namenode hdfs dfs -ls /
	@echo ""
	@echo "Testing Spark..."
	docker exec spark-master spark-submit --version

# Init HDFS directories
init-hdfs:
	@echo "📁 Initializing HDFS directories..."
	docker exec namenode bash -c "\
		hdfs dfs -mkdir -p /HiBench && \
		hdfs dfs -mkdir -p /spark-logs && \
		hdfs dfs -mkdir -p /user/root && \
		hdfs dfs -chmod -R 777 /HiBench && \
		hdfs dfs -chmod -R 777 /spark-logs && \
		hdfs dfs -chmod -R 777 /user"
	@echo "✅ HDFS initialized!"

# View HDFS
hdfs-ls:
	docker exec namenode hdfs dfs -ls /

# HDFS report
hdfs-report:
	docker exec namenode hdfs dfsadmin -report

# Clean HDFS data (keep containers)
hdfs-clean:
	@echo "🗑️  Cleaning HiBench data on HDFS..."
	docker exec namenode hdfs dfs -rm -r -f /HiBench/* || true
	@echo "✅ HDFS cleaned!"

# ============================================================================
# MICRO Benchmarks
# ============================================================================

wordcount:
	@bash scripts/run-hibench-workload.sh micro wordcount spark

sort:
	@bash scripts/run-hibench-workload.sh micro sort spark

terasort:
	@bash scripts/run-hibench-workload.sh micro terasort spark

repartition:
	@bash scripts/run-hibench-workload.sh micro repartition spark

dfsioe-read:
	@bash scripts/run-hibench-workload.sh micro dfsioe read

dfsioe-write:
	@bash scripts/run-hibench-workload.sh micro dfsioe write

# Prepare data for all MICRO benchmarks (run all PREPARE sequentially)
micro-prepare-all:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📦 PREPARE ALL MICRO workloads (sequential)"
	@echo "   (wordcount, sort, terasort, repartition, dfsioe-read, dfsioe-write)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro wordcount spark
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro sort spark
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro terasort spark
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro repartition spark
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro dfsioe read
	@HIBENCH_PHASE=prepare bash scripts/run-hibench-workload.sh micro dfsioe write
	@echo "✅ PREPARE for all MICRO workloads completed."

# Run all MICRO benchmarks in parallel (RUN ONLY, assume prepared in advance)
micro-run-all-parallel:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "⚡ RUN PHASE for ALL MICRO workloads IN PARALLEL"
	@echo "   (wordcount, sort, terasort, repartition, dfsioe-read, dfsioe-write)"
	@echo "   Lưu ý: cần đủ tài nguyên CPU/RAM trong cluster Spark."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@set -e; \
	for cfg in "wordcount spark" "sort spark" "terasort spark" "repartition spark" "dfsioe read" "dfsioe write"; do \
		set -- $$cfg; \
		w=$$1; \
		f=$$2; \
		echo "▶️  Start $$w (run-only) ..."; \
		HIBENCH_PHASE=run bash scripts/run-hibench-workload.sh micro $$w $$f & \
	done; \
	wait; \
	echo "✅ All MICRO workloads RUN phase (parallel) finished."

# Orchestrator: Prepare all first, then Run in parallel
micro-all:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🏃 micro-all = PREPARE all (sequential) + RUN all (parallel)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@$(MAKE) micro-prepare-all
	@$(MAKE) micro-run-all-parallel

# ============================================================================
# MACHINE LEARNING Benchmarks
# ============================================================================

kmeans:
	@bash scripts/run-hibench-workload.sh ml kmeans spark

bayes:
	@bash scripts/run-hibench-workload.sh ml bayes spark

lr:
	@bash scripts/run-hibench-workload.sh ml lr spark

svm:
	@bash scripts/run-hibench-workload.sh ml svm spark

als:
	@bash scripts/run-hibench-workload.sh ml als spark

rf:
	@bash scripts/run-hibench-workload.sh ml rf spark

gbt:
	@bash scripts/run-hibench-workload.sh ml gbt spark

linear:
	@bash scripts/run-hibench-workload.sh ml linear spark

gmm:
	@bash scripts/run-hibench-workload.sh ml gmm spark

lda:
	@bash scripts/run-hibench-workload.sh ml lda spark

pca:
	@bash scripts/run-hibench-workload.sh ml pca spark

xgboost:
	@bash scripts/run-hibench-workload.sh ml xgboost spark

svd:
	@bash scripts/run-hibench-workload.sh ml svd spark

# ============================================================================
# SQL Benchmarks
# ============================================================================

scan:
	@bash scripts/run-hibench-workload.sh sql scan spark

join:
	@bash scripts/run-hibench-workload.sh sql join spark

aggregation:
	@bash scripts/run-hibench-workload.sh sql aggregation spark

# ============================================================================
# WEB SEARCH Benchmarks
# ============================================================================

pagerank:
	@bash scripts/run-hibench-workload.sh websearch pagerank spark

nutchindexing:
	@bash scripts/run-hibench-workload.sh websearch nutchindexing spark

# ============================================================================
# GRAPH Benchmarks
# ============================================================================

nweight:
	@bash scripts/run-hibench-workload.sh graph nweight spark

# ============================================================================
# STREAMING Benchmarks
# ============================================================================

identity:
	@bash scripts/run-hibench-workload.sh streaming identity spark

repartition-streaming:
	@bash scripts/run-hibench-workload.sh streaming repartition spark

wordcount-streaming:
	@bash scripts/run-hibench-workload.sh streaming wordcount spark

# ============================================================================
# Job Status Check
# ============================================================================

# Check job status
check-job:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔍 CHECK WORDCOUNT JOB"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1️⃣  Check _SUCCESS file:"
	@if docker exec namenode hdfs dfs -test -e /HiBench/Wordcount/Output/_SUCCESS 2>/dev/null; then \
		echo "   ✅ JOB SUCCEEDED!"; \
	else \
		echo "   ❌ Job not completed or failed"; \
	fi
	@echo ""
	@echo "2️⃣  Output files list:"
	@docker exec namenode hdfs dfs -ls -h /HiBench/Wordcount/Output/ 2>/dev/null | head -10 || echo "   (No output found)"
	@echo ""
	@echo "3️⃣  Spark Event Log (created):"
	@docker exec namenode hdfs dfs -ls -h /spark-logs/ 2>/dev/null | tail -5 || echo "   (No event logs found)"
	@echo ""
	@echo "4️⃣  Sample results (first 5 lines):"
	@docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-* 2>/dev/null | head -5 || echo "   (Cannot read results)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# Benchmark Logs Management
# ============================================================================

# List all benchmark log files
logs-list:
	@echo "📝 Benchmark logs list:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ -d "logs" ] && [ -n "$$(ls -A logs 2>/dev/null)" ]; then \
		ls -lh logs/*.log 2>/dev/null | awk '{print "   " $$9 " (" $$5 ")"}'; \
		echo ""; \
		echo "   Total: $$(ls -1 logs/*.log 2>/dev/null | wc -l) file(s)"; \
	else \
		echo "   (No log files yet)"; \
	fi
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# View latest benchmark log
logs-latest:
	@echo "📖 View latest log:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ -d "logs" ] && [ -n "$$(ls -A logs/*.log 2>/dev/null)" ]; then \
		LATEST_LOG=$$(ls -t logs/*.log 2>/dev/null | head -1); \
		echo "   File: $$LATEST_LOG"; \
		echo ""; \
		tail -50 "$$LATEST_LOG" || echo "   (Cannot read file)"; \
	else \
		echo "   (No log files yet)"; \
	fi
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# View a specific log file
logs-view:
	@if [ -z "$$FILE" ]; then \
		echo "❌ Usage: make logs-view FILE=logs/benchmark-xxx.log"; \
		echo ""; \
		echo "📝 Available logs list:"; \
		ls -1 logs/*.log 2>/dev/null | head -10 || echo "   (No log files yet)"; \
		exit 1; \
	fi
	@if [ -f "$$FILE" ]; then \
		echo "📖 View log file: $$FILE"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		cat "$$FILE"; \
	else \
		echo "❌ File does not exist: $$FILE"; \
		exit 1; \
	fi

# Clean old log files (older than 7 days)
logs-clean:
	@echo "🧹 Cleaning old log files (older than 7 days)..."
	@if [ -d "logs" ]; then \
		find logs -name "*.log" -type f -mtime +7 -delete 2>/dev/null; \
		DELETED=$$(find logs -name "*.log" -type f -mtime +7 2>/dev/null | wc -l); \
		if [ "$$DELETED" -gt 0 ]; then \
			echo "✅ Deleted $$DELETED file(s)"; \
		else \
			echo "✅ No files to delete"; \
		fi; \
	else \
		echo "✅ Logs directory does not exist"; \
	fi

