#!/usr/bin/env python
import pika
import sys
import os
import json
from refinfo import reflistwithcounts

EXCHANGE_NAME = 'lib-exchange'


class Queue(object):

    def __init__(self,
                 name,
                 channel=None,
                 routing_key=None,
                 exchange=EXCHANGE_NAME,
                 callback=None):
        self.name = name
        self.channel = channel
        self.queue = q = channel.queue_declare(queue=name, durable=True)
        self.queue_name = q_name = q.method.queue
        channel.queue_bind(exchange=exchange,
                           routing_key=routing_key,
                           queue=q_name)
        if callable(callback):
            self.consume(callback)

    def consume(self, callback, auto_ack=True):
        self.channel.basic_consume(queue=self.queue_name,
                                   on_message_callback=callback,
                                   auto_ack=auto_ack)


def processing_raw_lib_json(ch, method, properties,
                            JSON):
    js = JSON.decode('utf8')
    print(" [x] Received {}".format(js))
    for ref, dt, labels, comments in reflistwithcounts(js):
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
        ch.basic_publish(exchange=EXCHANGE_NAME,
                         routing_key="lis.process.rec.json",
                         body=json.dumps(dt, ensure_ascii=False),
                         mandatory=True)


def processing_out_lib_ref(ch, method, properties, msg):
    msg = msg.decode('utf8')
    print("Received: ", msg)

def processing_lis_rec_json(ch, method, properties, JSON):
    JSON = JSON.decode('utf8')
    print("Received to process: ", JSON)


def main():
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='irnok.net'))

    channel = connection.channel()

    channel.exchange_declare(exchange=EXCHANGE_NAME, exchange_type='direct')

    lib = Queue(name='lib',
               channel=channel,
               exchange=EXCHANGE_NAME,
               routing_key="raw.lib.json",
               callback=processing_raw_lib_json)

    out_lib = Queue(name='out-lib',
                   exchange=EXCHANGE_NAME,
                   channel=channel,
                   routing_key="out.lib.ref",callback=processing_out_lib_ref)

    lis = Queue(name='lis',
               exchange=EXCHANGE_NAME,
               channel=channel,
               routing_key="lis.process.rec.json",
               callback=processing_lis_rec_json)

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
