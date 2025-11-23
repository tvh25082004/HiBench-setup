# Makefile for HiBench Hadoop & Spark Setup
# Usage: make <command>

.PHONY: help setup start stop restart status logs clean check build shell-spark shell-hadoop test \
	wordcount sort terasort repartition dfsioe-read dfsioe-write \
	kmeans bayes lr svm als rf gbt linear gmm lda pca xgboost svd \
	scan join aggregation \
	pagerank nutchindexing \
	nweight \
	identity repartition-streaming wordcount-streaming \
	check-job

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
	@echo "🔍 KIỂM TRA JOB WORDCOUNT"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1️⃣  Kiểm tra file _SUCCESS:"
	@if docker exec namenode hdfs dfs -test -e /HiBench/Wordcount/Output/_SUCCESS 2>/dev/null; then \
		echo "   ✅ JOB ĐÃ THÀNH CÔNG!"; \
	else \
		echo "   ❌ Job chưa hoàn thành hoặc thất bại"; \
	fi
	@echo ""
	@echo "2️⃣  Danh sách output files:"
	@docker exec namenode hdfs dfs -ls -h /HiBench/Wordcount/Output/ 2>/dev/null | head -10 || echo "   (Không tìm thấy output)"
	@echo ""
	@echo "3️⃣  Spark Event Log (đã tạo):"
	@docker exec namenode hdfs dfs -ls -h /spark-logs/ 2>/dev/null | tail -5 || echo "   (Không tìm thấy event logs)"
	@echo ""
	@echo "4️⃣  Sample kết quả (5 dòng đầu):"
	@docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-* 2>/dev/null | head -5 || echo "   (Không thể đọc kết quả)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

