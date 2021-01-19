import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as httpClient;
import 'package:android_notification_listener2/android_notification_listener2.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

String BASE_URL = "http://8.9.15.19/sms/index.php";

List<String> suggestions = [
  "http://8.9.15.19/sms/index.php"
];

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

List<Map<String, dynamic>> _log = [
  {
    "packageMessage": "event.packageMessage",
    "packageName": "event.packageName",
    "packageText": "event.packageText",
    "timeStamp": " event.timeStamp",
    "packageExtra": " event.packageExtra"
  }
];

class _MyAppState extends State<MyApp> {
  AndroidNotificationListener _notifications;
  StreamSubscription<NotificationEventV2> _subscription;
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
  Map<String, dynamic> cdata = {"id": "2", "app": "SMS", "msg": "testing SMS"};
  SimpleAutoCompleteTextField textField;
  String currentText = "";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  _MyAppState() {
    loaddata().then((value) {
      setState(() {});
    });
    textField = SimpleAutoCompleteTextField(
      clearOnSubmit: false,
      key: key,
      suggestions: suggestions,
      textChanged: (text) => currentText = text,
      textSubmitted: (text) => setState(() {
        int flag = 0;
        for (int i = 0; i < suggestions.length; i++)
          if (suggestions[i] == text) flag = 1;
        if (flag == 0) {
          suggestions.add(text);
          textField.updateSuggestions(suggestions);
        }
        if (text != "") {
          BASE_URL = text;
          savedata();
        }
      }),
    );
  }
  static Future loaddata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    BASE_URL = prefs.getString("URL") ?? "http://8.9.15.19/sms/index.php";
    suggestions = prefs.getStringList("suggestion") ??
        ["http://8.9.15.19/sms/index.php",];
  }

  static Future savedata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("URL", BASE_URL);
    prefs.setStringList("suggestion", suggestions);
  }

  void onData(NotificationEventV2 event) {
    loaddata().then((value) {
      print(event);
      Map<String, dynamic> data = {
        "id": "2",
        "app": "SMS",
        "packageMessage":
            event.packageMessage == Null || event.packageMessage == "null"
                ? "empty"
                : event.packageMessage,
        "packageName": event.packageName == Null || event.packageName == "null"
            ? "empty"
            : event.packageName,
        "packageText": event.packageText == Null || event.packageText == "null"
            ? "empty"
            : event.packageText,
        "timeStamp": event.timeStamp.toString() ?? "empty",
        "packageExtra":
            event.packageExtra == Null || event.packageExtra == "null"
                ? "empty"
                : event.packageExtra,
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
          .timeout(Duration(seconds: 10))
          .then((value) {
        print(value);
      });
    });
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
          body: ListView(children: [
            Column(children: [
              Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Column(children: [
                    new ListTile(
                        title: textField,
                        trailing: new IconButton(
                            icon: new Icon(Icons.add),
                            onPressed: () {
                              textField.triggerSubmitted();
                            })),
                  ])),
              Text(BASE_URL),
              Container(
                height: 600,
                child: ListView(
                  children: [
                    for (int i = 1; i < _log.length; i++)
                      Container(
                          width: 300,
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey[300],
                                  blurRadius: 100,
                                  spreadRadius: 10)
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(_log[i]["packageMessage"]),
                              Text(_log[i]["packageName"]),
                              Text(_log[i]["packageText"]),
                              Text(_log[i]["timeStamp"]),
                              Text(_log[i]["packageExtra"]),
                            ],
                          ))
                  ],
                ),
              ),
            ]),
          ])),
    );
  }
}
