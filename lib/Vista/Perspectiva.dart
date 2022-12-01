import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../Modelo/Datos.dart';


class PersIOT extends StatefulWidget {
  final BluetoothDevice server; 
  const PersIOT({required this.server});
  _PersIOTState createState() => _PersIOTState();
}

class _PersIOTState extends State<PersIOT> {
   String? dataString2;
  static const clientID = 0;
  BluetoothConnection? connection;
  List<Datos> messages = List<Datos>.empty(growable: true);
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;
  AccelerometerEvent? event;
  Timer? timer;
  StreamSubscription? accel;
  Color fderecha=Colors.black;
  Color fizquierda=Colors.black;


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
    if (timer == null || !timer!.isActive) {
      timer = Timer.periodic(Duration(milliseconds: 900), (_) {
        cambioColor();
      });
    }
  }

  pauseTimer() {
    timer!.cancel();
    accel!.pause();
  }

  @override
  void dispose() {
    accel?.cancel();
    timer?.cancel();
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }
    super.dispose();
  }

 @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    startTimer();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    return Scaffold(body: panel(context));
  }

Widget stateConexion(){
    final serverName = widget.server.name ?? "Unknown";
    return (isConnecting
              ? Text('Connecting chat to $serverName...')
              : isConnected
                  ? Text('Controla a $serverName')
                  : Text('Maneja a $serverName'));
  }
  panel(context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
          image: DecorationImage(
        fit: BoxFit.fill,
        image: AssetImage('assets/fondo.png'),
      )),

      //color: Colors.white,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            //Container
            Positioned(
                top: 200,
                right: 100,
                child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                      onPressed: isConnected
              ? () => _sendMessage("a") 
              : null,
                      icon: Image(image: AssetImage('assets/acelerar.png'))),
                )),
                Positioned(
              top: 10,
              left: 100,
              child: stateConexion(),
            ),
            //Container
            Positioned(
              top: 200,
              left: 100,
              child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                      onPressed: isConnected
              ? () => _sendMessage("p")
              : null,
                      icon: Image(image: AssetImage('assets/frenar.png')))),
            ),

            Positioned(
              top: 100,
              left: 10,
              child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                      onPressed: (){pauseTimer();},
                      icon: Icon(Icons.pause))),
            ),
            Positioned(
              top: 200,
              left: 400,
              child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                      onPressed: isConnected
              ? () => _sendMessage("r")
              : null,
                      icon: Image(image: AssetImage('assets/frenar.png')))),
            ),
            Positioned(
              top: 60,
              left: 400,
              child: Container(
                  width: 180,
                  height: 210,
                  child: IconButton(
                      onPressed: () {},
                      icon: Image(image: AssetImage('assets/barricada.png'), fit: BoxFit.fill,))),
            ),
            Positioned(
              top: 30,
              right: 100,
              child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                     onPressed: isConnected
              ? () => _sendMessage("d")
              : null,
                      icon: Icon(Icons.turn_right_rounded, color: fderecha,size: 80,))),
            ),
            Positioned(
              top: 30,
              left: 100,
              child: Container(
                  width: 70,
                  height: 100,
                  child: IconButton(
                      onPressed: isConnected
              ? () => _sendMessage("i")
              : null,
                      icon: Icon(Icons.turn_left_rounded, color: fizquierda,size: 80,))),
            ),
            Positioned(
              top: 30,
              left: 400,
              child: Container(
                  width: 70,
                  height: 100,
                  child: Text("cm: $dataString2")),
            ),
              //Container
          ], //<Widget>[]
        ), //Stack
      ), //Center
    ); //SizedBox
  }

   Widget lbTexto(context) {
    return Container(
        padding: const EdgeInsets.only(),
        width: 150,
        child: Text("Distancia: $dataString2 cm"));
  }

  /*Widget ss(){
    return ElevatedButton.icon(onPressed: (){}, icon: icon, label: label,onLongPress: () {
      
    },);
  }*/

  cambioColor(){
    Color dcambio=Colors.black;
    Color icambio=Colors.black;
    String x1=(event?.x ?? 0).toStringAsFixed(3);
    double n=double.parse(x1);
    String y1=(event?.y ?? 0).toStringAsFixed(3);
    double n2=double.parse(y1);
    if(n>0 && n2 <-1 && n2>-10){
      icambio=Colors.white;
_sendMessage("i");
print("i");
    }else if(n>0 && n2 < 10 && n2>1){
      dcambio =Colors.white;
_sendMessage("d");
print("d");
    }else{
      dcambio =Colors.black;
      icambio=Colors.black;
      
    }
    setState(() {
        fderecha=dcambio;
        fizquierda=icambio;
      });
      
  }



  /*Widget Voz() {
    return Container(
        padding: const EdgeInsets.only(), width: 150, child: SpeechScreen());
  }*/

  void _onDataReceived(Uint8List data) {
    // Asignar búfer para datos analizados
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Aplicar carácter de control de retroceso
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
      setState(() {
        dataString2=dataString;
      });
    
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(Datos(clientID, text));
        });


      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
