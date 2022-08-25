#!/usr/bin/env python
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters('irnok.net'))
channel = connection.channel()
channel.queue_declare(queue='hello', durable=True)
channel.basic_publish(exchange='',
                      routing_key='hello',
                      body='Hello World!')
print(" [x] Sent 'Hello World!'")
connection.close()
