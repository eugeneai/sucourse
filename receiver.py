#!/usr/bin/env python
import pika
import sys
import os
from refinfo import reflistwithcounts

EXCHANGE_NAME = 'lib-exchange'


def processing_raw_lib_json(ch, method, properties, json):
    json = json.decode('utf8')
    print(" [x] Received {}".format(json))
    for ref, dt, labels, comments in reflistwithcounts(json):
        labels = ''.join([r"\label{{{}}}".format(lab) for lab in labels])
        if comments:
            comments = "% " + comments.strip()
        else:
            comments = ''
        message = r'\item {}{}{}'.format(ref, labels, comments).strip()
        ch.basic_publish(exchange=EXCHANGE_NAME,
                         routing_key='out.lib.ref',
                         body=message,
                         mandatory=True)


def processing_out_lib_ref(ch, method, properties, msg):
    msg = msg.decode('utf8')
    print("Received: ", msg)


def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='irnok.net'))

    channel = connection.channel()

    channel.exchange_declare(exchange=EXCHANGE_NAME, exchange_type='direct')

    lib_q = channel.queue_declare(queue='lib', durable=True)
    lib_q_name = lib_q.method.queue
    channel.queue_bind(exchange=EXCHANGE_NAME,
                       routing_key="raw.lib.json",
                       queue=lib_q_name)
    channel.basic_consume(queue=lib_q_name,
                          on_message_callback=processing_raw_lib_json,
                          auto_ack=True)

    out_lib_q = channel.queue_declare(queue='out-lib', durable=True)
    out_lib_q_name = out_lib_q.method.queue
    channel.queue_bind(exchange=EXCHANGE_NAME,
                       routing_key="out.lib.ref",
                       queue=out_lib_q_name)
    channel.basic_consume(queue=out_lib_q_name,
                          on_message_callback=processing_out_lib_ref,
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
