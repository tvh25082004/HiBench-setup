# HiBench Setup - Hadoop & Spark

## Setup

```bash
cd /Users/tranvanhuy/Desktop/Set-up
make setup
```

## Lệnh

```bash
make start              # Khởi động
make stop               # Dừng
make status             # Xem trạng thái
make shell-spark        # Vào Spark container
make shell-hadoop       # Vào Hadoop container
make test               # Test WordCount
make logs               # Xem logs
make clean              # Xóa hết
```

## Web UI

- Hadoop: http://localhost:9870
- Spark Master: http://localhost:8080
- Spark Worker: http://localhost:8081

## Chạy Benchmark

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

# Xem kết quả
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
# Xem logs
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
