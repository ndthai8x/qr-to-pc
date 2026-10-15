import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const QrPcApp());
}

class QrPcApp extends StatelessWidget {
  const QrPcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR to PC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.');
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isSending = false;
  String _lastScanned = '';
  String _statusMessage = 'Sẵn sàng quét mã';

  Future<void> _sendCodeToPc(String code) async {
    if (_isSending || code == _lastScanned) return;

    setState(() {
      _isSending = true;
      _lastScanned = code;
      _statusMessage = 'Đang gửi mã sang PC: $code';
    });

    String pcIp = _ipController.text.trim();
    String url = 'http://$pcIp:5000/scan';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Đã dán vào PC thành công!';
        });
      } else {
        setState(() {
          _statusMessage = 'Lỗi máy tính: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Không kết nối được tới $pcIp:5000';
      });
    } finally {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _isSending = false;
          _lastScanned = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR Bắn Sang Máy Tính', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E2638),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF182030),
            child: Row(
              children: [
                const Text('IP Máy Tính: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      hintText: 'VD: 192.168.1.15',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _sendCodeToPc(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFF182030),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _statusMessage.contains('thành công') ? Colors.greenAccent : Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
