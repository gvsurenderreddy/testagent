# testagent
Traffic agent for icmp,tcp,udp,voice,video,http traffic. 
Intenrally it uses, ping,iperf tools for triggering the traffic.
It exposes REST API for start the test, get the status.
By default, REST server is running on Port 5051

iperf must be installed on the system.

Example:

Executes the  PING TEST
---
Workflow: 
1. Post the new Test with type "ping" , refer ping man page for the configuration.
2. Get the Test Id to retrive the status/result
Test status will have the current status of the test also, timestamps will be updated in the test result

A. post the ping test
POST /Test

Request Data :
{
    "name":"pingtest",
    "destination":"localhost",
    "type":"ping",
    "duration":"60",
    "config":
    {
        "flood":"no",
        "adaptive":"yes",
        "count":60,
        "packetsize":100
    }
}


Response Data :
{
  "id": "fe770b56-1a31-4df3-831e-86a216d80c21",
  "data": {
    "name": "pingtest",
    "destination": "localhost",
    "type": "ping",
    "duration": "60",
    "config": {
      "flood": "no",
      "adaptive": "yes",
      "count": 60,
      "packetsize": 100
    }
  },
  "saved": false
}

B. Get the status of the PingTest

Get /Test/fe770b56-1a31-4df3-831e-86a216d80c21
http://localhost:5051/Test/fe770b56-1a31-4df3-831e-86a216d80c21

Response Data :
{
  "config": {
    "flood": "no",
    "adaptive": "yes",
    "count": 60,
    "packetsize": 100
  },
  "duration": "60",
  "type": "ping",
  "destination": "localhost",
  "name": "pingtest",
  "createdTime": "2015-09-01T08:58:37.588Z",
  "startedTime": "2015-09-01T08:58:37.589Z",
  "status": "completed",
  "testResult": {
    "transmitted": "60 packets transmitted",
    "received": " 60 received",
    "packetloss": " 0% packet loss",
    "totaltime": " time 11818ms",
    "rtt_min": "rtt min/avg/max/mdev = 0.044/0.063/0.101/0.010 ms",
    "rtt_max": "rtt min/avg/max/mdev = 0.044/0.063/0.101/0.010 ms",
    "rtt_avg": "rtt min/avg/max/mdev = 0.044/0.063/0.101/0.010 ms",
    "rtt_mdev": "rtt min/avg/max/mdev = 0.044/0.063/0.101/0.010 ms",
    "ipg": " ipg/ewma 200.321/0.066 ms",
    "ewma": " ipg/ewma 200.321/0.066 ms"
  },
  "completedTime": "2015-09-01T08:58:49.427Z"
}



Executes the UDP Test
--

1.
POST UDP

{
    "name":"udptest",
    "destination":"localhost",
    "type":"udp",
    "duration":"300",
    "config":
    {
        "bandwidth":"10Mb",
        "packetsize":1000
    }
}

Response:

{
  "id": "e720612f-406b-45ee-8248-2ca93a0d92ef",
  "data": {
    "name": "udptest",
    "destination": "localhost",
    "type": "udp",
    "duration": "300",
    "config": {
      "bandwidth": "10Mb",
      "packetsize": 1000
    }
  },
  "saved": false
}

2. Get Test Status

Response Data:

{
  "config": {
    "bandwidth": "10Mb",
    "packetsize": 1000
  },
  "duration": "300",
  "type": "udp",
  "destination": "localhost",
  "name": "udptest",
  "createdTime": "2015-09-01T09:03:42.057Z",
  "startedTime": "2015-09-01T09:03:42.057Z",
  "status": "completed",
  "testResult": {
    "sender_date": "20150901143842",
    "sender_senderip": "127.0.0.1",
    "sender_senderport": "32856",
    "sender_receiverip": "127.0.0.1",
    "sender_receiverport": "5001",
    "sender_iperf_test_id": "3",
    "sender_interval": "0.0-300.0",
    "sender_transfer": "39325000",
    "sender_bandwidth": "1048629",
    "reported_date": "20150901143842",
    "reported_senderip": "127.0.0.1",
    "reported_senderport": "5001",
    "reported_receivedip": "127.0.0.1",
    "reported_receiverport": "32856",
    "reported_iperf_test_id": "3",
    "reported_interval": "0.0-300.0",
    "reported_transfer": "39325000",
    "reported_bandwidth": "1048629",
    "reported_jitter": "0.015",
    "reported_lostdatagrams": "0",
    "reported_totaldatagrams": "39325",
    "reported_unknown1": "0.000",
    "reported_unknown2": "0"
  },
  "completedTime": "2015-09-01T09:08:42.100Z"
}

2.Get Test status

Get http://localhost:5051/Test/58645f45-7a5a-40ba-a2ea-3254bb19d571
{
  "config": {
    "windowsize": 100,
    "packetsize": 100,
    "port": 5001
  },
  "duration": "30",
  "type": "tcp",
  "destination": "localhost",
  "name": "tcptest",
  "createdTime": "2015-09-01T09:08:13.404Z",
  "startedTime": "2015-09-01T09:08:13.405Z",
  "status": "completed",
  "testResult": {
    "date": "20150901143843",
    "senderip": "127.0.0.1",
    "senderport": "53454",
    "receiverip": "127.0.0.1",
    "receiverport": "5001",
    "iperf_test_id": "3",
    "interval": "0.0-30.0",
    "transfer": "206460800",
    "bandwidth": "55046022\n"
  },
  "completedTime": "2015-09-01T09:08:43.451Z"
}