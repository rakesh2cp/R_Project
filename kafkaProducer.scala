package com.mypackage.spark.Producer
import java.util.Properties
import org.apache.kafka.clients.producer._
object KafkaProducer extends App {
        def kafkaProduce() {
        val  props = new Properties()
        
        props.put("bootstrap.servers", "server:9092")
        props.put("acks","1")
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
        
        val producer = new KafkaProducer[String, String](props)
        val topic="test_topic"
        val jsonString = """{"key":"value",
                             "key":"value"
                            }""".stripMargin
        
        val record = new ProducerRecord(topic, "key", jsonString)
        producer.send(record)
        println(record)
        producer.close()
}
}
