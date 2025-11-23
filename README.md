# HiBench - Hadoop & Spark Benchmark Suite

Docker environment for running HiBench benchmarks with Hadoop HDFS and Apache Spark.

## 🚀 Quick Start

```bash
# Initial setup (build containers, init HDFS, build HiBench)
make setup

# Start containers
make start

# Run WordCount benchmark test
make test
```

## 📋 Main Commands

### Container Management
```bash
make start        # Start containers
make stop         # Stop containers
make status       # View status
make logs         # View logs
make clean        # Remove everything (including data)
```

### Development
```bash
make shell-spark   # Enter Spark Master container
make shell-hadoop  # Enter Hadoop NameNode container
make test          # Test WordCount benchmark
```

## 🏆 Run Benchmarks

### MICRO Benchmarks
```bash
make wordcount     # WordCount
make sort          # Sort
make terasort      # TeraSort
make repartition   # Repartition
make dfsioe-read   # DFSIOE Read
make dfsioe-write  # DFSIOE Write
```

### MACHINE LEARNING
```bash
make kmeans        # K-Means
make bayes         # Naive Bayes
make lr            # Logistic Regression
make svm           # SVM
make als           # ALS
make rf            # Random Forest
make gbt           # Gradient Boosted Trees
make linear        # Linear Regression
make gmm           # Gaussian Mixture Model
make lda           # LDA
make pca           # PCA
make xgboost       # XGBoost
make svd           # SVD
```

### SQL
```bash
make scan          # Scan
make join          # Join
make aggregation   # Aggregation
```

### WEB SEARCH
```bash
make pagerank      # PageRank
make nutchindexing # Nutch Indexing
```

### GRAPH
```bash
make nweight       # N-Weight
```

### STREAMING
```bash
make identity              # Identity
make repartition-streaming # Repartition Streaming
make wordcount-streaming   # WordCount Streaming
```

## 🌐 Web UIs

- **Hadoop NameNode**: http://localhost:9870
- **Spark Master**: http://localhost:8080
- **Spark Worker**: http://localhost:8081

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Docker Network                  │
│                                         │
│  ┌──────────┐      ┌──────────┐       │
│  │ NameNode │◄────►│ DataNode │       │
│  │  :9000   │      │  (HDFS)  │       │
│  │  :9870   │      │          │       │
│  └────┬─────┘      └──────────┘       │
│       │                                 │
│       │ HDFS                            │
│       ▼                                 │
│  ┌──────────┐      ┌──────────┐       │
│  │  Spark   │◄────►│  Spark   │       │
│  │  Master  │      │  Worker  │       │
│  │  :7077   │      │  :8081  │       │
│  │  :8080   │      │          │       │
│  └──────────┘      └──────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

## 📁 Project Structure

```
Set-up/
├── docker-compose.yml      # Container definitions
├── Dockerfile.spark        # Spark image with Hadoop client
├── config/
│   ├── hadoop/            # Hadoop configs
│   └── spark/             # Spark configs
├── hibench-workspace/     # HiBench configs
├── scripts/
│   ├── setup.sh          # Setup script
│   └── run-hibench-workload.sh  # Workload runner
└── Makefile              # All commands
```

## 🔧 Troubleshooting

```bash
# View logs
make logs

# Restart containers
make restart

# Full reset
make clean
make setup

# Check HDFS
make hdfs-ls
make hdfs-report
```

## 📝 Notes

- All benchmarks automatically run prepare phase (if available)
- Results are saved in `/opt/hibench/report/` inside container
- HDFS data is stored in Docker volumes
- View all commands: `make help`
