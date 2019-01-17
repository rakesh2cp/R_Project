package com.myproject.spark.consumer.OraWriteBack
import org.slf4j.LoggerFactory
import org.apache.spark.sql.{ SparkSession, DataFrame }
import org.apache.spark.sql.functions.{from_json, col }
import java.text.SimpleDateFormat;
import java.util.{ TimeZone, Date, Calendar, Properties }
import java.sql.DriverManager
import org.apache.spark.sql.types.{ StructField, StructType }
import org.apache.spark.sql.types.{ DecimalType, StringType, LongType }
import org.apache.spark.sql.types.DataType._
import scala.collection.Seq
//import java.sql._
import java.sql.{Array=>SQLArray, _}
import org.apache.spark.sql.ForeachWriter
import org.slf4j.LoggerFactory
import org.apache.spark.sql
import org.apache.spark.sql.{SparkSession, SaveMode, Row}
//Custom classes
import com.myproject.spark.model.Schemas
import com.myproject.spark.utils.Configurations

object OraWriteBack {
  
  val conf = new Configurations
  val connectionProperties = new Properties()
  val log = LoggerFactory.getLogger(ClaimOraWriteBack.getClass)
  val dateFormat = new SimpleDateFormat("yyyyMMdd")
  val schemas = new Schemas
  
  var connection:Connection = _
  var statement:Statement = _
 
def main(args: Array[String]): Unit = {

    
    val spark = SparkSession.builder().appName("OracleWrite").master("local[4]").getOrCreate()
    
    val streamDS = spark.readStream.format("kafka")
                            .option("kafka.bootstrap.servers", conf.bootstrapServer)
                            .option("value.deserializer","KafkaJSONDeserilizer")
                            .option("zookeeper.connect", conf.zookeeper_connect_server)
                            .option("subscribe", "test")
                            .option("startingOffsets", "earliest")
                            .option("max.poll.records", 10)
                            .option("failOnDataLoss", false).load()
    
     
     import spark.implicits._ 
     
     val dataFrm = streamDS.selectExpr("cast (value as string) as json")
                                      .select(from_json($"json", schema = schemas.Schema)
                                      .as("JsonData"))

     val finalDF = dataFrm.select(col("JsonData.*")) 
      
     class  JDBCSink(url:String, user:String, pwd:String, tablename: String) extends ForeachWriter[Row] {
      val driver = "oracle.jdbc.driver.OracleDriver"
      var connection:Connection = _
      var statement:Statement = _
      
    def open(partitionId: Long,version: Long): Boolean = {
        Class.forName(driver)
        connection = DriverManager.getConnection(url, user, pwd)
        statement = connection.createStatement
        true
      }

      def process(value: Row): Unit = {
        statement.executeUpdate("INSERT INTO " +  tablename  + 
                " VALUES ('" + value.get(0)+ "','" +value.get(1)+ "','" + value.get(2) + "','" + value.get(3)+ "','" 
                + value.get(4)+ "','" + value.get(5)+ "','" + value.get(6)+ "','" + value.get(7)+"')")
      }

      def close(errorOrNull: Throwable): Unit = {
        connection.close
      }
   }
      val writer = new JDBCSink(conf.jdbcUrl, conf.jdbcUsername, conf.jdbcPassword,conf.tablename)

      finalDF.writeStream.foreach(new JDBCSink(conf.jdbcUrl, conf.jdbcUsername, conf.jdbcPassword,conf.tablename))
                  .format("foreach")
                  .outputMode("append")
                  .start()

      spark.streams.awaitAnyTermination()
      
      spark.stop()
  }
  

}
