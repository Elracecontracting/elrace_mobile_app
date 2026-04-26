import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:el_race/core/biometric/pin_auth_service.dart';
import 'package:el_race/resources/app_colors.dart';

/// Modal bottom-sheet that asks the user to enter their 4-6 digit PIN.
///
/// Returns `true` through `Navigator.pop` when the PIN is verified.
///
/// Usage:
/// ```dart
/// final ok = await showModalBottomSheet<bool>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => const PinVerifySheet(),
/// );
/// ```
class PinVerifySheet extends StatefulWidget {
  final String title;
  final String subtitle;

  const PinVerifySheet({
    super.key,
    this.title = 'أدخل رمز الأمان',
    this.subtitle = 'أدخل الرمز للتحقق من هويتك',
  });

  @override
  State<PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<PinVerifySheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _loading = false;
  bool _obscure = true;
  int _attempts = 0;
  static const _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await PinAuthService.instance.verifyPin(pin);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    _attempts++;
    if (_attempts >= _maxAttempts) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _loading = false;
      _error = 'رمز خاطئ – لديك ${_maxAttempts - _attempts} محاولات متبقية';
      _controller.clear();
      _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Icon(Icons.lock_outline_rounded,
                size: 48.sp, color: AppColors.primaryColor),
            SizedBox(height: 12.h),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              widget.subtitle,
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              obscureText: _obscure,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 28.sp, letterSpacing: 12),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • •',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                suffixIcon: IconButton(
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(_error!,
                  style: TextStyle(color: Colors.red, fontSize: 13.sp)),
            ],
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'تحقق',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
