# HiBench Setup cho Hadoop & Spark trên Docker (MacBook M3)

## 📋 Tổng Quan

Setup đơn giản để chạy **Hadoop** và **Spark** với **HiBench benchmarking** trên Docker, tối ưu cho MacBook M3 (ARM64).

---

## 🎯 Yêu Cầu

- **MacBook M3** (hoặc chip Apple Silicon khác)
- **Docker Desktop** cho Mac (đã cài đặt và đang chạy)
- **8GB RAM** trở lên (khuyến nghị)
- **20GB** dung lượng trống

---

## 🚀 Setup Nhanh (5 phút)

### Bước 1: Clone Repository và Khởi Động

```bash
cd /Users/tranvanhuy/Desktop/Set-up

# Cấp quyền thực thi cho scripts
chmod +x scripts/*.sh

# Chạy setup (tự động build + start)
./scripts/setup.sh
```

### Bước 2: Kiểm Tra Trạng Thái

```bash
# Xem trạng thái containers
./scripts/status.sh

# Hoặc xem nhanh
docker-compose ps
```

### Bước 3: Truy Cập Web UI

- **Hadoop NameNode**: http://localhost:9870
- **Spark Master**: http://localhost:8080
- **Spark Worker**: http://localhost:8081
- **Spark App UI**: http://localhost:4040 (khi job đang chạy)

---

## 📊 Chạy HiBench Benchmark

### Vào Container Spark Master

```bash
docker exec -it spark-master bash
```

### Chạy WordCount Benchmark

```bash
cd /opt/hibench

# Copy file cấu hình
cp /hibench/hibench.conf conf/
cp /hibench/spark.conf conf/
cp /hibench/hadoop.conf conf/

# Chuẩn bị dữ liệu
bin/workloads/micro/wordcount/prepare/prepare.sh

# Chạy benchmark
bin/workloads/micro/wordcount/spark/run.sh

# Xem kết quả
cat report/hibench.report
```

### Các Benchmark Khác

```bash
# TeraSort
bin/workloads/micro/terasort/prepare/prepare.sh
bin/workloads/micro/terasort/spark/run.sh

# Sort
bin/workloads/micro/sort/prepare/prepare.sh
bin/workloads/micro/sort/spark/run.sh

# PageRank
bin/workloads/websearch/pagerank/prepare/prepare.sh
bin/workloads/websearch/pagerank/spark/run.sh

# K-Means
bin/workloads/ml/kmeans/prepare/prepare.sh
bin/workloads/ml/kmeans/spark/run.sh
```

---

## 🛠️ Các Lệnh Hữu Ích

### Quản Lý Docker

```bash
# Khởi động lại tất cả
docker-compose restart

# Dừng tất cả containers
./scripts/stop.sh
# hoặc: docker-compose down

# Xem logs
docker-compose logs -f spark-master
docker-compose logs -f namenode

# Xóa hoàn toàn (bao gồm dữ liệu)
docker-compose down -v
```

### Thao Tác HDFS

```bash
# Vào container namenode
docker exec -it namenode bash

# Các lệnh HDFS cơ bản
hdfs dfs -ls /
hdfs dfs -ls /HiBench
hdfs dfs -mkdir -p /test
hdfs dfs -put localfile.txt /test/
hdfs dfs -cat /test/localfile.txt
hdfs dfs -rm -r /HiBench/Wordcount  # Xóa dữ liệu benchmark cũ

# Kiểm tra HDFS health
hdfs dfsadmin -report
```

### Debug & Monitoring

```bash
# Kiểm tra resource usage
docker stats

# Xem log chi tiết của container
docker logs spark-master
docker logs namenode

# Vào shell của bất kỳ container nào
docker exec -it <container_name> bash
```

---

## 📁 Cấu Trúc Thư Mục

```
Set-up/
├── docker-compose.yml          # Docker orchestration
├── Dockerfile                  # Custom image (nếu cần)
├── README.md                   # File này
├── .dockerignore              # Ignore files cho Docker
│
├── config/                    # Các file cấu hình
│   ├── hadoop/
│   │   ├── core-site.xml
│   │   └── hdfs-site.xml
│   └── spark/
│       ├── spark-defaults.conf
│       └── spark-env.sh
│
├── scripts/                   # Automation scripts
│   ├── setup.sh              # Setup ban đầu
│   ├── stop.sh               # Dừng services
│   ├── status.sh             # Kiểm tra status
│   └── init-hdfs.sh          # Khởi tạo HDFS
│
├── hibench-workspace/         # HiBench configs
│   ├── hibench.conf
│   ├── spark.conf
│   └── hadoop.conf
│
└── data/                      # Dữ liệu local (nếu cần)
```

---

## ⚙️ Tùy Chỉnh Cấu Hình

### Điều Chỉnh Resource (RAM/CPU)

Chỉnh sửa `docker-compose.yml`:

```yaml
spark-worker:
  environment:
    - SPARK_WORKER_CORES=4      # Tăng CPU cores
    - SPARK_WORKER_MEMORY=4g    # Tăng RAM
```

### Thay Đổi Scale Profile

Chỉnh sửa `hibench-workspace/hibench.conf`:

```properties
# Options: tiny, small, large, huge, gigantic, bigdata
hibench.scale.profile   large
```

---

## 🐛 Troubleshooting

### Container không khởi động

```bash
# Kiểm tra logs
docker-compose logs

# Restart Docker Desktop và thử lại
./scripts/stop.sh
./scripts/setup.sh
```

### HDFS không accessible

```bash
# Kiểm tra NameNode
docker exec namenode hdfs dfsadmin -report

# Format lại NameNode (XÓA TẤT CẢ DỮ LIỆU)
docker exec namenode hdfs namenode -format
docker-compose restart namenode datanode
```

### Spark job bị lỗi

```bash
# Kiểm tra Spark Master logs
docker logs spark-master

# Kiểm tra executor logs
docker logs spark-worker

# Xem UI để debug: http://localhost:8080
```

### Port đã được sử dụng

Chỉnh sửa ports trong `docker-compose.yml`:

```yaml
ports:
  - "9871:9870"  # Thay đổi port ngoài (9871)
```

---

## 📝 Notes

### Lưu Ý Quan Trọng

1. **MacBook M3 (ARM64)**: Images sử dụng đã tối ưu cho kiến trúc ARM
2. **Resource**: Khuyến nghị cấp ít nhất 4GB RAM cho Docker Desktop
3. **Dữ liệu**: HDFS data được lưu trong Docker volumes, sẽ mất khi chạy `docker-compose down -v`
4. **Performance**: Benchmark results phụ thuộc vào resource allocated

### Best Practices

- Luôn chạy `./scripts/status.sh` trước khi chạy benchmark
- Xóa dữ liệu cũ trên HDFS trước khi chạy benchmark mới
- Monitor resource usage bằng `docker stats`
- Backup kết quả benchmark từ `/opt/hibench/report/`

---

## 🔗 Tài Liệu Tham Khảo

- **HiBench GitHub**: https://github.com/Intel-bigdata/HiBench
- **Hadoop Documentation**: https://hadoop.apache.org/docs/stable/
- **Spark Documentation**: https://spark.apache.org/docs/latest/
- **Docker Compose**: https://docs.docker.com/compose/

---

## 📄 License

Setup này dựa trên HiBench (Apache License 2.0)

---

**Tạo bởi**: Setup Script for MacBook M3  
**Phiên bản**: 1.0  
**Ngày**: 2025-11-21

# HiBench-setup
