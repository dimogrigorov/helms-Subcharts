#!/usr/bin/env python
# import os
import logging
import pika
import ssl
import time
import sys
# import base64
import json
from random import randint
RBMQ_USER = 'guest'
RBMQ_PASS = 'guest'
RBMQ_HOST = 'localhost'
RBMQ_PORT = '5671'
RBMQ_VHOST = '/'
RBMQ_QUEUE = 'ccbd_queue'
RUN_INTERVAL = 5
PREFETCH_COUNT = 1
credentials = pika.PlainCredentials(RBMQ_USER, RBMQ_PASS)
def random_with_N_digits(n):
    range_start = 10**(n-1)
    range_end = (10**n)-1
    return randint(range_start, range_end)
def error_message():
    print('    Available commands are:')
    print('                   - send')
    print('                   - receive')
    print('')
    quit()
def callback(channel, method_frame, header_frame, body):
    print(" [-] Messages received %d" %(method_frame.delivery_tag))
    channel.basic_ack(delivery_tag=method_frame.delivery_tag)
    time.sleep(float(RUN_INTERVAL))
    return
#if len(sys.argv) != 2:
#    error_message()
command = sys.argv[1]
runIntervalParam = sys.argv[2]
logging.basicConfig(level=logging.INFO)
context = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
context.verify_mode = ssl.CERT_REQUIRED
#local certificate
context.load_verify_locations('rmqlocal.crt')

connection  = pika.BlockingConnection(
            pika.ConnectionParameters(host=RBMQ_HOST,port=RBMQ_PORT,virtual_host=RBMQ_VHOST,
                                        credentials=credentials,ssl_options=pika.SSLOptions(context)))
channel = connection.channel()
channel.basic_qos(prefetch_count=int(PREFETCH_COUNT))
channel.queue_declare(queue=RBMQ_QUEUE, durable=True, arguments={ 'x-queue-mode': 'lazy', 'x-max-priority': 10})
if command == 'send':

    listJSONFile =[]
    for num in range(1, 6):
        fileName = "Air_OW_local_"+str(num)+".json"
        bFile = open(fileName, 'r')
        json_data =json.load(bFile)
        bFile.close()
        listJSONFile.append(json_data)

    message_number = 0
    while message_number<50:
        print("----------------------------------")
        randFileIdx = randint(1,5)
        print("randFileIdx is : "+str(randFileIdx))
        fileName = "Air_OW_local_"+str(randFileIdx)+".json"
        print("File name: "+fileName)
        json_data = listJSONFile[randFileIdx-1]
        print(json_data)
        print("----------------------------------")
        newtripId = random_with_N_digits(10)
        neweventId = random_with_N_digits(10)
        print(">> New trip id:", newtripId, ";new event id:", neweventId)
        json_data['trip']['tripId']= newtripId
        json_data['eventId']= neweventId
        message_body= json.dumps(json_data)
       # Publish
        channel.basic_publish(exchange='', routing_key=RBMQ_QUEUE, body=message_body)
        message_number += 1
        print(" [+] Messages sent, count:", message_number )
        time.sleep(float(runIntervalParam if len(runIntervalParam) > 0 else RUN_INTERVAL))
    channel.close()
    connection.close()
elif command == 'receive':
    channel.basic_consume(RBMQ_QUEUE, callback)
    print(' [*] Waiting for messages. To exit press CTRL+C')
    channel.start_consuming()
else:
    error_message()

