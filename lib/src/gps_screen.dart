// lib/src/gps_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class GPSScreen extends StatefulWidget {
  static const routeName = '/gps';

  const GPSScreen({super.key});

  @override
  _GPSScreenState createState() => _GPSScreenState();
}

class _GPSScreenState extends State<GPSScreen> {
  String _locationMessage = '';
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Comprueba si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Los servicios de ubicación están desactivados.';
        _isLoading = false;
      });
      return;
    }

    // Comprueba el permiso de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Solicita el permiso
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'El permiso de ubicación ha sido denegado.';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
            'El permiso de ubicación ha sido denegado permanentemente.';
        _isLoading = false;
      });
      return;
    }

    // Obtiene la ubicación actual
    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentPosition = position;
      _locationMessage =
          'Latitud: ${position.latitude}, Longitud: ${position.longitude}';
      _isLoading = false;
    });
  }

  void _openInGoogleMaps() async {
    if (_currentPosition != null) {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final Uri googleMapsUri = Uri.parse(googleMapsUrl);

      try {
        await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('Error al abrir Google Maps: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir Google Maps: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ubicación Actual'),
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : _currentPosition == null
                  ? Text(
                      _locationMessage,
                      style: TextStyle(fontSize: 18),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tu ubicación actual es:',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _locationMessage,
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: Icon(Icons.map),
                          label: Text('Abrir en Google Maps'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
        ));
  }
}
