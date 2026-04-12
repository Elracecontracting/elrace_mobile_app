import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:el_race/core/biometric/pin_auth_service.dart';
import 'package:el_race/resources/app_colors.dart';

/// Full-screen page that asks the user to create a 4-digit PIN.
///
/// Pops with `true` on success.  Cannot be dismissed without setting the PIN.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _error;
  bool _step2 = false; // true → confirm step
  bool _obscure = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _onSubmitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'يجب أن يكون الرمز من 4 إلى 6 أرقام');
      return;
    }
    setState(() {
      _error = null;
      _step2 = true;
    });
    _confirmFocus.requestFocus();
  }

  Future<void> _onConfirmPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin != confirm) {
      setState(() => _error = 'الرمز غير متطابق، حاول مرة أخرى');
      _confirmController.clear();
      _confirmFocus.requestFocus();
      return;
    }
    await PinAuthService.instance.setPin(pin);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: Text(
            'إعداد رمز الأمان',
            style: TextStyle(color: Colors.white, fontSize: 18.sp),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                Icon(Icons.lock_outline_rounded,
                    size: 72.sp, color: AppColors.primaryColor),
                SizedBox(height: 24.h),
                Text(
                  _step2 ? 'تأكيد رمز الأمان' : 'أدخل رمز أمان جديد',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _step2
                      ? 'أعد إدخال الرمز للتأكيد'
                      : 'سيُستخدم هذا الرمز للتحقق من هويتك عند تسجيل الحضور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 32.h),
                if (!_step2)
                  _PinField(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    label: 'رمز الأمان',
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    onSubmitted: (_) => _onSubmitPin(),
                  ),
                if (_step2)
                  _PinField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    label: 'تأكيد رمز الأمان',
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    onSubmitted: (_) => _onConfirmPin(),
                  ),
                if (_error != null) ...[
                  SizedBox(height: 12.h),
                  Text(_error!,
                      style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                ],
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _step2 ? _onConfirmPin : _onSubmitPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      _step2 ? 'تأكيد' : 'التالي',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_step2) ...[
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () => setState(() {
                      _step2 = false;
                      _error = null;
                      _pinController.clear();
                      _confirmController.clear();
                      _pinFocus.requestFocus();
                    }),
                    child: Text(
                      'رجوع',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  const _PinField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(fontSize: 28.sp, letterSpacing: 12),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleObscure,
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
