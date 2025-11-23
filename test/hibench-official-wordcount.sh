#!/bin/bash

# Script to run official HiBench WordCount
# Uses Spark instead of Hadoop MapReduce for Docker setup compatibility

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏆 OFFICIAL HIBENCH - WORDCOUNT BENCHMARK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HDFS_INPUT="hdfs://namenode:9000/HiBench/Wordcount/Input"
HDFS_OUTPUT="hdfs://namenode:9000/HiBench/Wordcount/Output"
DATA_SIZE_MB=500
NUM_PAGES=50000

echo "📋 Configuration:"
echo "   - Data size: ${DATA_SIZE_MB}MB"
echo "   - Pages: ${NUM_PAGES}"
echo "   - Input: $HDFS_INPUT"
echo "   - Output: $HDFS_OUTPUT"
echo ""

# Check if HiBench has been built, if not, build it
if ! docker exec spark-master test -f /opt/hibench/sparkbench/assembly/target/sparkbench-assembly-8.0-SNAPSHOT-dist.jar; then
    echo "⚠️  HiBench has not been built yet!"
    echo "🔨 Building HiBench now (this may take a few minutes)..."
    echo "   Spark: 3.3.2, Scala: 2.12"
    echo ""
    
    docker exec spark-master bash -c "
        export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 && \
        export PATH=\$JAVA_HOME/bin:\$PATH && \
        cd /opt/hibench && \
        mvn -Psparkbench,scala2.12 \
            -Dspark.version=3.3.2 \
            -Dmaven.compiler.source=8 \
            -Dmaven.compiler.target=8 \
            -DskipTests \
            -U \
            clean package -pl sparkbench/assembly -am
    " || {
        echo "❌ HiBench build failed!"
        echo "   Please run 'make setup' to build HiBench manually"
        exit 1
    }
    
    # Verify build
    if ! docker exec spark-master test -f /opt/hibench/sparkbench/assembly/target/sparkbench-assembly-8.0-SNAPSHOT-dist.jar; then
        echo "❌ HiBench build verification failed!"
        exit 1
    fi
    echo "✅ HiBench build completed successfully!"
else
    echo "✅ HiBench has been built"
fi
echo ""

# Prepare Phase - Use official HiBench data generator
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  PREPARE PHASE - Generate test data using HiBench"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Copy HiBench configs
echo "📋 Copying HiBench configuration files..."
docker exec spark-master bash -c "cp /hibench/*.conf /opt/hibench/conf/" 2>/dev/null || true
echo "✅ Configuration files ready"
echo ""

# Verify Hadoop is available in spark-master container
echo "🔧 Verifying Hadoop setup in spark-master container..."
docker exec spark-master bash -c "
    if [ ! -f /opt/hadoop/bin/hadoop ]; then
        echo '❌ ERROR: Hadoop CLI not found at /opt/hadoop/bin/hadoop'
        echo '   Please rebuild the container: docker-compose build spark-master'
        exit 1
    fi
    echo '✅ Hadoop CLI found at /opt/hadoop/bin/hadoop'
    /opt/hadoop/bin/hadoop version | head -1
    echo ''
    echo '✅ Hadoop configuration:'
    echo '   HDFS NameNode: hdfs://namenode:9000'
" || {
    echo "❌ Hadoop verification failed!"
    exit 1
}
echo ""

# Remove old data
echo "🗑️  Removing old data (if any)..."
docker exec namenode hdfs dfs -rm -r -f /HiBench/Wordcount 2>/dev/null || true
echo ""

# Use official HiBench prepare script (uses RandomTextWriter)
echo "🔧 Generating data using HiBench's official RandomTextWriter..."
echo "   (This uses HiBench's built-in data generator from GitHub)"
echo "   (Data size: ${DATA_SIZE_MB}MB, Pages: ${NUM_PAGES})"
echo ""

# Run HiBench prepare script (may have bash warnings but job can still succeed)
echo "   Running HiBench prepare script..."
PREPARE_OUTPUT=$(docker exec spark-master bash -c "cd /opt/hibench && set +e && bin/workloads/micro/wordcount/prepare/prepare.sh 2>&1; exit 0" 2>&1)
echo "$PREPARE_OUTPUT" | grep -v "unbound variable" | grep -v "SyntaxWarning" | tail -20 || true

# Check if data was actually generated (ignore script exit code, check HDFS)
echo ""
echo "📊 Verifying data generation..."
if docker exec namenode hdfs dfs -test -e /HiBench/Wordcount/Input/_SUCCESS 2>/dev/null; then
    echo "✅ Data has been generated successfully!"
    echo "   (HiBench prepare job completed, ignoring minor bash script warnings)"
else
    echo "⚠️  HiBench prepare script had issues, trying alternative method..."
    echo "   Using Hadoop RandomTextWriter directly..."
    DATASIZE_BYTES=$((DATA_SIZE_MB * 1024 * 1024))
    docker exec namenode bash -c "
        /opt/hadoop-3.2.1/bin/hadoop --config /opt/hadoop-3.2.1/etc/hadoop jar \
        /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar \
        randomtextwriter \
        -D mapreduce.randomtextwriter.totalbytes=${DATASIZE_BYTES} \
        -D mapreduce.randomtextwriter.bytespermap=$((DATASIZE_BYTES / 2)) \
        -D mapreduce.job.maps=2 \
        -D mapreduce.job.reduces=2 \
        hdfs://namenode:9000/HiBench/Wordcount/Input
    " || {
        echo "❌ All data generation methods failed!"
        exit 1
    }
fi

echo ""

# Verify data
echo "📊 Checking data on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Input/
FILE_SIZE=$(docker exec namenode hdfs dfs -du -h /HiBench/Wordcount/Input/ | awk '{print $1" "$2}')
echo "   📏 Size: $FILE_SIZE"
echo ""

# Run Phase - Run WordCount benchmark using official HiBench
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  RUN PHASE - Run WordCount benchmark using HiBench"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⚙️  Running official HiBench WordCount benchmark..."
START_TIME=$(date +%s)

# Set environment variables for HiBench scripts
docker exec spark-master bash -c "
    export INPUT_HDFS=hdfs://namenode:9000/HiBench/Wordcount/Input && \
    export OUTPUT_HDFS=hdfs://namenode:9000/HiBench/Wordcount/Output && \
    export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop && \
    export HADOOP_HOME=/opt/hadoop && \
    cd /opt/hibench && \
    bin/workloads/micro/wordcount/spark/run.sh
" || {
    # Check if job actually completed (sometimes script has minor errors but job succeeds)
    if docker exec namenode hdfs dfs -test -e /HiBench/Wordcount/Output/_SUCCESS 2>/dev/null; then
        echo "⚠️  HiBench script had minor errors, but job completed successfully"
    else
        echo "❌ HiBench run script failed!"
        exit 1
    fi
}

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 WordCount Benchmark Results:"
echo "   - Workload: WordCount (Micro)"
echo "   - Framework: Spark"
echo "   - Data Size: $FILE_SIZE"
echo "   - Total Duration: ${DURATION}s"
echo "   - Status: SUCCESS"
echo ""

# Verify output
echo "📁 Verifying output on HDFS..."
docker exec namenode hdfs dfs -ls /HiBench/Wordcount/Output/ | head -5
echo ""

# Show HiBench report
echo "📊 HiBench Benchmark Report:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec spark-master bash -c "cat /opt/hibench/report/hibench.report" 2>/dev/null | tail -10 || echo "   (Report file not found)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔝 Sample results (first 10 words):"
docker exec namenode hdfs dfs -cat /HiBench/Wordcount/Output/part-* 2>/dev/null | head -10 || echo "   (Output files not found)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 HIBENCH WORDCOUNT BENCHMARK COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Details:"
echo "   - Spark UI: http://localhost:8080"
echo "   - HDFS UI: http://localhost:9870"
echo "   - Input data: $HDFS_INPUT"
echo "   - Output data: $HDFS_OUTPUT"
echo ""

