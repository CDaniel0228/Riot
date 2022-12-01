import 'dart:async';
import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../Control/Palabras.dart';
import '../Modelo/Datos.dart';

class VozIOT extends StatefulWidget {
  final BluetoothDevice server;
  const VozIOT({required this.server});
  _VozIOTState createState() => _VozIOTState();
}

class _VozIOTState extends State<VozIOT> {
    final Map<String, HighlightedWord> _highlights =Palabras().getPalabra();
    late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;   
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
  Color fderecha = Colors.black;
  Color fizquierda = Colors.black;



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
  _speech = stt.SpeechToText();
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
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    return Scaffold(body: panel(context));
  }

  Widget stateConexion() {
    final serverName = widget.server.name ?? "Unknown";
    return (isConnecting
        ? Text('Connecting chat to $serverName...')
        : isConnected
            ? Text('Controla a $serverName')
            : Text('Maneja a $serverName'));
  }

  panel(context) {
    return Container(
        padding: const EdgeInsets.only(),
        child: Column(
          children: [
            SizedBox(height: 50),
            stateConexion(),
            btnSpeech(), lbText(),
          ],
        ));
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
      dataString2 = dataString;
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

   
  Widget btnSpeech(){
    return AvatarGlow(animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ));
  }

  Widget lbText(){
    return Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: TextHighlight(
            text: _text,
            words: _highlights,
            textStyle: const TextStyle(
              fontSize: 32.0,
              color: Colors.amber,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            print(_text);
            _sendMessage(_text);
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
