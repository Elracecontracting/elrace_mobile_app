import 'package:flutter/material.dart';
import 'package:el_race/core/services/auth_verification_service.dart';

class SetupPinScreen extends StatefulWidget {
  final VoidCallback? onPinSet;

  const SetupPinScreen({super.key, this.onPinSet});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final AuthVerificationService _authService = AuthVerificationService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.isEmpty || confirmPin.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال رمز PIN');
      return;
    }

    if (pin.length < 4) {
      setState(() => _errorMessage = 'رمز PIN يجب أن يكون 4 أرقام على الأقل');
      return;
    }

    if (pin != confirmPin) {
      setState(() => _errorMessage = 'رمز PIN غير متطابق');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.setUserPin(pin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ رمز PIN بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPinSet?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ أثناء حفظ رمز PIN');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد رمز PIN'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF1A1A53),
              ),
              const SizedBox(height: 24),
              const Text(
                'إنشاء رمز PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A53),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أنشئ رمز PIN للاستخدام كبديل للتحقق بالوجه أو البصمة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'رمز PIN',
                  hintText: 'أدخل 4-6 أرقام',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'تأكيد رمز PIN',
                  hintText: 'أعد إدخال رمز PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A53),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
