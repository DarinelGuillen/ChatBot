// lib/src/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  static const routeName = '/qr_scanner';

  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? _qrCode;
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) {
        debugPrint('No se pudo leer el código.');
      } else {
        final String code = barcode.rawValue!;
        setState(() {
          _qrCode = code;
          _isScanning = false;
        });
        // Detener el escaneo después de encontrar un código
        controller.stop();
        break; // Para evitar múltiples lecturas
      }
    }
  }

  void _restartScan() {
    setState(() {
      _qrCode = null;
      _isScanning = true;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear Matrícula'),
      ),
      body: Stack(
        children: [
          if (_isScanning)
            MobileScanner(
              controller: controller,
              onDetect: _foundBarcode,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.qr_code, size: 40),
                    title: Text(
                      'Matrícula Escaneada:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _qrCode ?? '',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _restartScan,
                    ),
                  ),
                ),
              ),
            ),
          if (_isScanning)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Apunte la cámara hacia el código QR de su matrícula.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
