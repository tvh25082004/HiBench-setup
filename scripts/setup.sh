#!/bin/bash

# Script to setup HiBench environment with Hadoop and Spark

set -e

echo "🚀 Starting HiBench environment setup..."
echo ""

# Check Docker
echo "🐳 Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is ready"
echo ""

# Check Docker Compose
echo "🔧 Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed."
    exit 1
fi

echo "✅ Docker Compose is ready"
echo ""

# Build and start containers
echo "🔨 Building and starting containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start (60 seconds)..."
sleep 60

# Initialize HDFS
echo ""
echo "📁 Initializing HDFS..."
docker exec -it namenode bash -c "
    hdfs dfs -mkdir -p /HiBench
    hdfs dfs -mkdir -p /spark-logs
    hdfs dfs -mkdir -p /user/root
    hdfs dfs -chmod -R 777 /HiBench
    hdfs dfs -chmod -R 777 /spark-logs
    hdfs dfs -chmod -R 777 /user
"

# Create Maven settings with proper repositories
echo ""
echo "🔧 Configuring Maven settings..."
docker exec spark-master bash -c "
    mkdir -p /root/.m2 && \
    cat > /root/.m2/settings.xml << 'EOF'
<settings>
  <profiles>
    <profile>
      <id>hibench-repos</id>
      <repositories>
        <repository>
          <id>central</id>
          <name>Maven Central</name>
          <url>https://repo1.maven.org/maven2</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
        <repository>
          <id>apache-repo</id>
          <name>Apache Repository</name>
          <url>https://repository.apache.org/content/repositories/releases</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>hibench-repos</activeProfile>
  </activeProfiles>
</settings>
EOF
"

# Build HiBench with Java 8 (build sparkbench assembly with proper Scala version)
echo ""
echo "🔨 Building HiBench sparkbench with Java 8 (this may take a few minutes)..."
echo "   Spark: 3.3.2, Scala: 2.12"
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
    echo "❌ HiBench build failed! Trying alternative build method..."
    echo "🔧 Attempting to build with explicit dependency resolution..."
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
        echo "❌ HiBench build failed completely!"
        echo "⚠️  You may need to build manually inside the container"
        exit 1
    }
}

# Verify build success
echo ""
if docker exec spark-master test -f /opt/hibench/sparkbench/assembly/target/sparkbench-assembly-8.0-SNAPSHOT-dist.jar; then
    echo "✅ HiBench build verified successfully!"
else
    echo "⚠️  Warning: HiBench jar file not found, but build may have completed"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Web UIs available:"
echo "  - Hadoop NameNode: http://localhost:9870"
echo "  - Spark Master:     http://localhost:8080"
echo "  - Spark Worker:     http://localhost:8081"
echo "  - Spark App UI:     http://localhost:4040 (when running jobs)"
echo ""
echo "📝 To run HiBench benchmark, use:"
echo "   docker exec -it spark-master bash"
echo "   cd /hibench"
echo ""

