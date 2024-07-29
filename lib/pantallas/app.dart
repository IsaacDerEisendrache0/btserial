import 'package:btserial/pantallas/home.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          primaryColor: Colors.purple,
          primarySwatch: Colors.deepPurple),
      home: const Home(),
    );
  }
}
