import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class PageIOT extends StatefulWidget {
  final BluetoothDevice server;

  const PageIOT({required this.server});
  @override
  // ignore: library_private_types_in_public_api
  _PageIOTState createState() => _PageIOTState();
}

class _PageIOTState extends State<PageIOT> {
  String? dataString2;
  static const clientID = 0;
  BluetoothConnection? connection;
  List<_Message> messages = List<_Message>.empty(growable: true);
  final ScrollController listScrollController = ScrollController();
  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

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
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
        appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
                  ? Text('Controla a ' + serverName)
                  : Text('Maneja a ' + serverName)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(child: panel(context)));
  }

  Widget panel(BuildContext context) {
    return Container(
        child: Column(
      children: [lbTexto(context), btnAvanzar(context), btnParar(context)],
    ));
  }
 
  Widget lbTexto(context) {
    return Container(
        padding: const EdgeInsets.only(),
        width: 150,
        child: Text("Distancia: $dataString2 cm"));
  }

  Widget btnAvanzar(context) {
    return Container(
      padding: const EdgeInsets.only(),
      width: 150,
      child: TextButton.icon(
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text("Arrancar"),
          style: TextButton.styleFrom(
            primary: Colors.black,
            shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5))),
          ),
          onPressed: isConnected
              ? () => _sendMessage("a")
              : null),
    );
  }

  Widget btnParar(context) {
    return Container(
      padding: const EdgeInsets.only(),
      width: 150,
      child: TextButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text("Parar"),
          style: TextButton.styleFrom(
            primary: Colors.black,
            shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5))),
          ),
          onPressed: isConnected
              ? () => _sendMessage("p")
              : null),
    );
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
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}
