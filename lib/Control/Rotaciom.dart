import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AccelerometerEvent? event;
  StreamSubscription? accel;


  startTimer() {
    if (accel == null) {
      accel = accelerometerEvents.listen((AccelerometerEvent eve) {
        setState(() {
          event = eve;
        });
      });
    } else {
      accel!.resume();
    }
  }

  pauseTimer() {
    accel!.pause();
  }

  @override
  void dispose() {
    accel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    startTimer();
    return Container(child: comparar(),);
  }
  Widget comparar(){
    String x1=(event?.x ?? 0).toStringAsFixed(3);
    double n=double.parse(x1);
    
    String y1=(event?.y ?? 0).toStringAsFixed(3);
    double n2=double.parse(y1);
    if(n>0 && n2 <0 && n2>-10){
      return Text("data1");
    }else if(n>0 && n2 < 10 && n2>0){
      return Text("data2");
    }else{
      return Text("");
    }
  }
}

