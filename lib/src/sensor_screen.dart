// lib/src/sensor_screen.dart
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class SensorScreen extends StatefulWidget {
  static const routeName = '/sensors';

  const SensorScreen({super.key});

  @override
  _SensorScreenState createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  // Variables para almacenar los datos de los sensores
  double _accelerometerX = 0, _accelerometerY = 0, _accelerometerZ = 0;
  double _gyroscopeX = 0, _gyroscopeY = 0, _gyroscopeZ = 0;
  double _magnetometerX = 0, _magnetometerY = 0, _magnetometerZ = 0;

  // Controladores de streams
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;

  @override
  void initState() {
    super.initState();

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;
      });
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeX = event.x;
        _gyroscopeY = event.y;
        _gyroscopeZ = event.z;
      });
    });

    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        _magnetometerX = event.x;
        _magnetometerY = event.y;
        _magnetometerZ = event.z;
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _magnetometerSubscription.cancel();
    super.dispose();
  }

  Widget _buildSensorCard(String title, List<double> values, IconData icon) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, size: 40),
        title: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        children: [
          ListTile(
            title: Text(
              'X: ${values[0].toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ListTile(
            title: Text(
              'Y: ${values[1].toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ListTile(
            title: Text(
              'Z: ${values[2].toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGauge(String title, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Datos de Sensores'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSensorCard('Acelerómetro', [
                _accelerometerX,
                _accelerometerY,
                _accelerometerZ
              ], Icons.directions_run),
              _buildSensorCard('Giroscopio', [
                _gyroscopeX,
                _gyroscopeY,
                _gyroscopeZ
              ], Icons.screen_rotation),
              _buildSensorCard('Magnetómetro', [
                _magnetometerX,
                _magnetometerY,
                _magnetometerZ
              ], Icons.explore),
            ],
          ),
        ));
  }
}
