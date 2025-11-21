#!/usr/bin/env python3
"""
Script test đơn giản: Đọc file từ HDFS bằng Spark và thực hiện phân tích
Sử dụng DataFrame API để tránh serialization issues
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, length, split, explode, lower, count as sql_count
import sys

def main():
    print("=" * 60)
    print("🚀 SPARK + HDFS TEST")
    print("=" * 60)
    print()
    
    # Tạo Spark Session
    print("📊 Khởi tạo Spark Session...")
    spark = SparkSession.builder \
        .appName("HDFS-Spark-Test") \
        .master("spark://spark-master:7077") \
        .config("spark.driver.memory", "1g") \
        .config("spark.executor.memory", "2g") \
        .getOrCreate()
    
    print("✅ Spark Session đã sẵn sàng!")
    print(f"   - Spark Version: {spark.version}")
    print(f"   - Master: {spark.sparkContext.master}")
    print()
    
    # Đường dẫn file trên HDFS
    hdfs_path = "hdfs://namenode:9000/test/sample-data.txt"
    
    print(f"📁 Đọc file từ HDFS: {hdfs_path}")
    
    try:
        # Đọc file từ HDFS as DataFrame
        df = spark.read.text(hdfs_path)
        
        print("✅ Đọc file thành công!")
        print()
        
        # 1. Đếm số dòng
        line_count = df.count()
        print(f"📝 Tổng số dòng: {line_count}")
        print()
        
        # 2. Hiển thị 5 dòng đầu tiên
        print("📋 5 dòng đầu tiên:")
        print("-" * 60)
        first_lines = df.take(5)
        for i, row in enumerate(first_lines, 1):
            print(f"  {i}. {row.value}")
        print("-" * 60)
        print()
        
        # 3. Word Count với DataFrame API
        print("🔤 Phân tích từ khóa:")
        
        # Split thành words
        words_df = df.select(explode(split(lower(col("value")), "\\s+")).alias("word"))
        
        # Lọc bỏ các string rỗng
        words_df = words_df.filter(col("word") != "")
        
        # Đếm tổng số từ
        total_words = words_df.count()
        print(f"   - Tổng số từ: {total_words}")
        
        # Đếm frequency và lấy top 10
        word_freq = words_df.groupBy("word").agg(sql_count("*").alias("count"))
        top_words = word_freq.orderBy(col("count").desc()).take(10)
        
        print("   - Top 10 từ xuất hiện nhiều nhất:")
        for row in top_words:
            print(f"     • {row.word}: {row['count']} lần")
        print()
        
        # 4. Tìm các dòng chứa từ "Spark"
        spark_lines = df.filter(col("value").contains("Spark") | col("value").contains("spark"))
        spark_count = spark_lines.count()
        print(f"🔍 Tìm thấy {spark_count} dòng chứa từ 'Spark':")
        print("-" * 60)
        for i, row in enumerate(spark_lines.collect(), 1):
            print(f"  {i}. {row.value}")
        print("-" * 60)
        print()
        
        # 5. Statistics
        print("📊 Thống kê:")
        
        # Tính độ dài mỗi dòng
        df_with_length = df.withColumn("line_length", length(col("value")))
        
        # Aggregate statistics
        stats = df_with_length.agg(
            sql_count("*").alias("total_lines"),
            sql_count("line_length").alias("total_chars_sum")
        ).collect()[0]
        
        # Lấy min, max, avg
        length_stats = df_with_length.select("line_length").describe().collect()
        
        # Parse results
        for stat in length_stats:
            if stat['summary'] == 'mean':
                avg_length = float(stat['line_length'])
            elif stat['summary'] == 'max':
                max_length = int(float(stat['line_length']))
            elif stat['summary'] == 'min':
                min_length = int(float(stat['line_length']))
        
        # Tính tổng ký tự
        total_chars = df_with_length.agg({"line_length": "sum"}).collect()[0][0]
        
        print(f"   - Tổng số ký tự: {int(total_chars)}")
        print(f"   - Độ dài trung bình mỗi dòng: {avg_length:.2f} ký tự")
        print(f"   - Dòng dài nhất: {max_length} ký tự")
        print(f"   - Dòng ngắn nhất: {min_length} ký tự")
        print()
        
        print("=" * 60)
        print("✅ TEST HOÀN TẤT THÀNH CÔNG!")
        print("=" * 60)
        print()
        print("💡 Bạn có thể:")
        print("   - Xem Spark UI: http://localhost:4040")
        print("   - Xem HDFS UI: http://localhost:9870")
        print("   - Kiểm tra file trên HDFS:")
        print(f"     docker exec namenode hdfs dfs -ls /test/")
        print()
        
    except Exception as e:
        print(f"❌ LỖI: {str(e)}")
        import traceback
        traceback.print_exc()
        print()
        print("💡 Kiểm tra:")
        print("   1. File đã được upload lên HDFS chưa?")
        print("   2. HDFS NameNode có chạy không?")
        print("   3. Spark cluster có hoạt động không?")
        sys.exit(1)
    
    finally:
        # Dừng Spark Session
        spark.stop()

if __name__ == "__main__":
    main()

