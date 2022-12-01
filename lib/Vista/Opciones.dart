import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'Automatic.dart';
import 'Perspectiva.dart';
import 'Voz.dart';

class Opciones extends StatelessWidget {
  final BluetoothDevice server; 
  const Opciones({required this.server});
  
  @override
  Widget build(BuildContext context) {
      return Scaffold(body: menu(context));
  }

  Widget menu(context){
    return Align( alignment:Alignment.center, child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children: [
      TextButton(onPressed: (){
        Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return PersIOT(server: server);
        },
      ),
    );
      }, child: Text("Manejo")),
      TextButton(onPressed: (){
        Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return AutoIOT(server: server);
        },
      ),
    );
      }, child: Text("Auto")),
      TextButton(onPressed: (){
        Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return VozIOT(server: server);
        },
      ),
    );
      }, child: Text("Voz"))
    ],));
  }

}
