import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as httpClient;
import 'package:android_notification_listener2/android_notification_listener2.dart';

void main() => runApp(MyApp());

String BASE_URL = "http://testserver.dyndns.biz:12345/?pg=gmsg";

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

List<Map<String, dynamic> > _log = [{
    "packageMessage": "event.packageMessage",
    "packageName": "event.packageName",
    "packageText": "event.packageText",
    "timeStamp": " event.timeStamp"
  }];

class _MyAppState extends State<MyApp> {
  AndroidNotificationListener _notifications;
  StreamSubscription<NotificationEventV2> _subscription;
  Map<String, dynamic> cdata = {
    "id":"2",
    "app":"SMS",
    "msg":"testing SMS"
  };
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  void onData(NotificationEventV2 event) {
    String packageMessage;
    String packageName;
    String packageExtra;
    String packageText;
    DateTime timeStamp;
    print(event);
    print('converting package extra to json');
    Map<String, dynamic> data = {
        "id":"2",
        "app":"SMS",
        "msg": event.packageMessage??"",
    };
    setState(() {
      cdata = data;
      _log.add(cdata);
    });
    Map<String, String> head = {
      "Content-Type": "application/json",
    };

    httpClient
        .post(BASE_URL, body: jsonEncode(data), headers: head)
        .timeout(Duration(seconds: 10));
  }

  void startListening() {
    _notifications = new AndroidNotificationListener();
    try {
      _subscription = _notifications.notificationStream.listen(onData);
    } on NotificationExceptionV2 catch (exception) {
      print(exception);
    }
  }

  void stopListening() {
    _subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications app'),
        ),
        body: Center(
          child: Column(
            children: [
              for (int i = 1; i < _log.length; i++)
                Container(
                  width: 300,
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white,boxShadow: [BoxShadow(color: Colors.grey[300],blurRadius: 100,spreadRadius: 10)] ,),
                    child: Column(
                  children: [
                    Text(_log[i]["packageMessage"]),
                    Text(_log[i]["packageName"]),
                    Text(_log[i]["timeStamp"].toString()),
                  ],
                ))
            ],
          ),
        ),
      ),
    );
  }
}
