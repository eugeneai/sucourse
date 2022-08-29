#!/usr/bin/env python
import pika
import sys
import os


def processing_callback(ch, method, properties, json):
    json = json.decode('utf8')
    print(" [x] Received {}".format(json))

EXHANGE_NAME = 'lib-exchange'


def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='irnok.net'))

    channel = connection.channel()

    channel.exchange_declare(exchange=EXHANGE_NAME, exchange_type='direct')

    lib_q = channel.queue_declare(queue='lib', durable=True)
    lib_q_name = lib_q.method.queue

    channel.queue_bind(exchange=EXHANGE_NAME,
                       routing_key="raw.lib.json",
                       queue=lib_q_name)

    channel.basic_consume(queue=lib_q_name,
                          on_message_callback=processing_callback,
                          # routing_key='raw.lib.json',
                          auto_ack=True)

    print(' [*] Waiting for messages. To exit press CTRL+C')
    channel.start_consuming()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
