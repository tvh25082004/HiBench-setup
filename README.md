# HiBench Setup - Hadoop & Spark

## Setup

```bash
cd /Users/tranvanhuy/Desktop/Set-up
make setup
```

## Commands

```bash
make start              # Start containers
make stop               # Stop containers
make status             # Check status
make shell-spark        # Enter Spark container
make shell-hadoop       # Enter Hadoop container
make test               # Test WordCount
make logs               # View logs
make clean              # Clean all
```

## Web UI

- Hadoop: http://localhost:9870
- Spark Master: http://localhost:8080
- Spark Worker: http://localhost:8081

## Run Benchmarks

```bash
make shell-spark

cd /opt/hibench
cp /hibench/*.conf conf/

# WordCount
bin/workloads/micro/wordcount/prepare/prepare.sh
bin/workloads/micro/wordcount/spark/run.sh

# TeraSort
bin/workloads/micro/terasort/prepare/prepare.sh
bin/workloads/micro/terasort/spark/run.sh

# PageRank
bin/workloads/websearch/pagerank/prepare/prepare.sh
bin/workloads/websearch/pagerank/spark/run.sh

# View results
cat report/hibench.report
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network                        │
│                                                          │
│  ┌─────────────┐      ┌──────────────┐                 │
│  │  NameNode   │◄────►│  DataNode    │                 │
│  │  (Hadoop)   │      │  (Hadoop)    │                 │
│  │  :9000      │      │              │                 │
│  │  :9870      │      │              │                 │
│  └─────────────┘      └──────────────┘                 │
│         ▲                                                │
│         │ HDFS                                           │
│         ▼                                                │
│  ┌─────────────┐      ┌──────────────┐                 │
│  │Spark Master │◄────►│Spark Worker  │                 │
│  │:7077        │      │:8081         │                 │
│  │:8080        │      │              │                 │
│  └─────────────┘      └──────────────┘                 │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Data Flow

```
Prepare Data → Upload to HDFS → Spark Process → Write to HDFS → Generate Report
```

## Config

- `docker-compose.yml` - Container definitions
- `config/hadoop/` - Hadoop configs
- `config/spark/` - Spark configs  
- `hibench-workspace/` - HiBench configs

## Troubleshooting

```bash
# View logs
make logs

# Restart
docker-compose restart

# Reset
make clean
make setup

# Check HDFS
docker exec namenode hdfs dfsadmin -report

# Check containers
docker ps
```

## Fixed Issues

**Java Not Found Error on macOS:**
- Error: `/usr/lib/jvm/java-8-openjdk-amd64/bin/java: No such file or directory`
- Cause: Spark images not compatible with macOS
- Solution: Build custom Spark image with Java 11 (eclipse-temurin)
- Files: `Dockerfile.spark` + `config/spark/spark-env.sh`
