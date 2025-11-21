#!/bin/bash

# Script test HDFS + Spark integration
# Không liên quan đến HiBench

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪 TEST HDFS + SPARK INTEGRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Kiểm tra containers
echo "1️⃣  Kiểm tra containers..."
if ! docker ps | grep -q "spark-master"; then
    echo "❌ Spark Master không chạy!"
    echo "   Chạy: make start"
    exit 1
fi

if ! docker ps | grep -q "namenode"; then
    echo "❌ Hadoop NameNode không chạy!"
    echo "   Chạy: make start"
    exit 1
fi

echo "✅ Tất cả containers đang chạy"
echo ""

# Tạo thư mục test trên HDFS
echo "2️⃣  Tạo thư mục /test/ trên HDFS..."
docker exec namenode hdfs dfs -mkdir -p /test 2>/dev/null || true
docker exec namenode hdfs dfs -chmod 777 /test
echo "✅ Thư mục đã sẵn sàng"
echo ""

# Upload file test lên HDFS
echo "3️⃣  Upload file test lên HDFS..."
echo "   - File: sample-data.txt"
echo "   - Destination: hdfs://namenode:9000/test/"

# Copy file vào container trước
docker cp test/sample-data.txt namenode:/tmp/sample-data.txt

# Upload lên HDFS
docker exec namenode hdfs dfs -put -f /tmp/sample-data.txt /test/

# Kiểm tra file đã upload
echo ""
echo "   📁 Kiểm tra file trên HDFS:"
docker exec namenode hdfs dfs -ls /test/
echo ""

FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /test/sample-data.txt | awk '{print $1" "$2}')
echo "   ✅ File đã upload thành công! (Size: $FILE_SIZE)"
echo ""

# Copy Python script vào Spark container
echo "4️⃣  Chuẩn bị Spark job..."
docker cp test/test-hdfs-spark.py spark-master:/tmp/test-hdfs-spark.py
echo "✅ Script đã sẵn sàng"
echo ""

# Chạy Spark job
echo "5️⃣  Chạy Spark job để đọc và phân tích file..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 2g \
    --executor-cores 2 \
    /tmp/test-hdfs-spark.py

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Test hoàn tất!"
echo ""
echo "📊 Bạn có thể xem thêm:"
echo "   - Spark Master UI:  http://localhost:8080"
echo "   - Spark App UI:     http://localhost:4040"
echo "   - Hadoop HDFS UI:   http://localhost:9870"
echo ""
echo "🧹 Để dọn dẹp test data:"
echo "   docker exec namenode hdfs dfs -rm -r /test"
echo ""

