import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../Modelo/Datos.dart';


class AutoIOT extends StatefulWidget {
  final BluetoothDevice server; 
  const AutoIOT({required this.server});
  _AutoIOTState createState() => _AutoIOTState();
}

class _AutoIOTState extends State<AutoIOT> {
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
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    return Scaffold(body: panel(context));
  }

Widget stateConexion(){
    final serverName = widget.server.name ?? "Unknown";
    return (isConnecting
              ? Text('Connecting chat to $serverName...', style: TextStyle(color: Colors.white),)
              : isConnected
                  ? Text('Controla a $serverName', style: TextStyle(color: Colors.white))
                  : Text('Maneja a $serverName', style: TextStyle(color: Colors.white)));
  }
  panel(context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
          image: DecorationImage(
        fit: BoxFit.fill,
        image: AssetImage('assets/auto.png'),
      )),

      //color: Colors.white,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            //Container
            Positioned(
                top: 100,
                left: 100,
                child: Container(
                  width: 170,
                  height: 100,
                  child: TextButton(
                      onPressed: isConnected
              ? () => _sendMessage("o") 
              : null,
                      child: Text("Activar", style: TextStyle(color: Colors.white, fontSize: 20))),
                )),
                Positioned(
              top: 20,
              left: 150,
              child: stateConexion(),
            ),
            //Container
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
