import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:el_race/ui/presentation/qr_code/data/qr_login_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final QrLoginService _qrLoginService = QrLoginService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQrScan(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    print('\n🔵 ========== QR SCANNER DEBUG ==========');
    print('📱 QR Code Scanned: $qrCode');
    print('📏 QR Code Length: ${qrCode.length} characters');
    print('🔤 QR Code Type: ${qrCode.runtimeType}');
    print('📊 QR Code Bytes: ${qrCode.codeUnits}');

    // Show loading toast
    Fluttertoast.showToast(
      msg: "جاري تسجيل الدخول...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    try {
      print('⏳ Calling API with QR code...');
      final result = await _qrLoginService.loginWithQrCode(qrCode);
      print('✅ API Response Received:');
      print('   - Success: ${result['success']}');
      print('   - Message: ${result['message']}');
      print('   - Full Response: $result');
      print('🔵 ========================================\n');

      if (mounted) {
        if (result['success'] == true) {
          Fluttertoast.showToast(
            msg: "✅ تم تسجيل الدخول بنجاح!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Close scanner and go back
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
            msg: "❌ ${result['message'] ?? 'فشل تسجيل الدخول'}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error handling QR scan: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: "❌ حدث خطأ: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'مسح QR Code',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && !_isProcessing) {
                  _handleQrScan(code);
                  break;
                }
              }
            },
          ),

          // Scanning Frame Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ضع الكود داخل الإطار',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تسجيل الدخول للموقع عبر QR Code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isProcessing) ...[
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Flash Toggle Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : Colors.white,
                    size: 32,
                  ),
                  onPressed: () async {
                    await cameraController.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => cameraController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
