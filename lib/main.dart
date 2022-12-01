import 'package:flutter/material.dart';
import 'Vista/Conexion.dart';


void main() => runApp(ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage(),
    debugShowCheckedModeBanner: false,
    );
  }
}
