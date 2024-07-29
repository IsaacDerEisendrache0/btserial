import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final bluetooth = FlutterBluetoothSerial.instance;
  bool estadoBT = false;
  bool conectado = false;
  BluetoothConnection? conexion; 
  List<BluetoothDevice> dispositivos = [];
  BluetoothDevice? activo;
  String contenido = "";

  @override
  void initState() {
    super.initState();
    _permisos();
    _estadoBT();
  }

  void _permisos() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  void _estadoBT() {
    bluetooth.state.then((value) {
      setState(() {
        estadoBT = value.isEnabled;
      });
    });

    bluetooth.onStateChanged().listen((event) {
      setState(() {
        switch (event) {
          case BluetoothState.STATE_ON:
            estadoBT = true;
            break;
          case BluetoothState.STATE_OFF:
            estadoBT = false;
            break;
          case BluetoothState.STATE_BLE_TURNING_OFF:
            debugPrint("Se está apagando el Bluetooth");
            break;
          case BluetoothState.STATE_BLE_TURNING_ON:
            debugPrint("Se está encendiendo el Bluetooth");
            break;
          default:
            break;
        }
      });
    });
  }

  void encender() async {
    await bluetooth.requestEnable();
  }

  void apagar() async {
    await bluetooth.requestDisable();
  }

  Widget botonBT() {
    return SwitchListTile(
      value: estadoBT,
      title: Text(estadoBT ? "Encendido" : "Apagado"),
      tileColor: estadoBT ? Colors.blue : Colors.grey,
      secondary: estadoBT ? const Icon(Icons.bluetooth) : const Icon(Icons.bluetooth_disabled),
      onChanged: (value) {
        if (value) {
          encender();
        } else {
          apagar();
        }
        setState(() {
          estadoBT = value;
          if (estadoBT) {
            leerDispositivos();
          }
        });
      },
    );
  }

  void leerDispositivos() async {
    dispositivos = await bluetooth.getBondedDevices();
    if (dispositivos.isNotEmpty) {
      debugPrint(dispositivos[0].name);
      debugPrint(dispositivos[0].address);
    }
    setState(() {});
  }

  Widget lista() {
    if (dispositivos.isEmpty) {
      return const Text("No hay dispositivos");
    } else {
      if (conectado) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Text(contenido),
        );
      } else {
        return ListView.builder(
          itemCount: dispositivos.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              leading: IconButton(
                icon: const Icon(Icons.bluetooth),
                onPressed: () async {
                  conexion = await BluetoothConnection.toAddress(dispositivos[index].address);
                  activo = dispositivos[index];
                  recibirDatos();
                  setState(() {
                    conectado = true;
                  });
                },
              ),
              trailing: Text(
                dispositivos[index].name ?? "Desconocido",
                style: const TextStyle(color: Colors.green, fontSize: 15),
              ),
              title: Text(dispositivos[index].address),
            );
          },
        );
      }
    }
  }

  void recibirDatos() {
    conexion?.input?.listen((event) {
      setState(() {
        contenido = String.fromCharCodes(event);
        debugPrint(contenido);
      });
    });
  }

  Widget dispositivo() {
    return ListTile(
      title: activo == null ? const Text("No conectado") : Text(activo?.name ?? "Desconocido"),
      subtitle: activo == null ? const Text("No Mac Address") : Text(activo?.address ?? "Desconocido"),
      leading: activo == null
          ? IconButton(
        onPressed: leerDispositivos,
        icon: const Icon(Icons.search),
      )
          : IconButton(
        onPressed: () {
          activo = null;
          conectado = false;
          dispositivos = [];
          conexion?.finish();
          setState(() {});
        },
        icon: const Icon(Icons.delete),
      ),
    );
  }

  void enviarDatos(String msg) {
    if (conexion?.isConnected == true) {
      conexion?.output.add(ascii.encode(msg));
    }
  }

  Widget botonera() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        CupertinoButton(
          child: const Text("Led on"),
          onPressed: () {
            enviarDatos("led_on");
          },
        ),
        CupertinoButton(
          child: const Text("Led off"),
          onPressed: () {
            enviarDatos("led_off");
          },
        ),
        CupertinoButton(
          child: const Text("Hello"),
          onPressed: () {
            enviarDatos("hello");
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth ESP32"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          botonBT(),
          const Divider(height: 5),
          dispositivo(),
          Expanded(child: lista()),
          const Divider(height: 5),
          botonera(),
        ],
      ),
    );
  }
}
