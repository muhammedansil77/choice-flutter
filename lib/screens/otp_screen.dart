import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phoneNumber;
  final String password;

  const OtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _timerSeconds = 30;
  Timer? _timer;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    // Auto-focus first digit field after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 30;
      _errorMessage = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(_otpCode);
  }

  void _handleOtpInput(int index, String value) {
    setState(() => _errorMessage = null);

    // Handle Paste 6 digits
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = digits[i];
        }
        _focusNodes[5].requestFocus();
        setState(() {});
        return;
      }
    }

    if (value.isNotEmpty) {
      _otpControllers[index].text = value.substring(value.length - 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    setState(() {});
  }

  Future<void> _handleVerifyAndRegister() async {
    if (!_isOtpComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<ApiService>().registerWithOtp(
            name: widget.name,
            email: widget.email,
            password: widget.password,
            phoneNumber: widget.phoneNumber,
            otp: _otpCode,
          );

      if (mounted) {
        _showSnackBar('Account registered successfully!', isError: false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _errorMessage = cleanMsg);
        _showSnackBar(cleanMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_timerSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await context.read<ApiService>().sendRegisterOtp(widget.email);
      if (mounted) {
        _showSnackBar('A new verification code has been sent to ${widget.email}');
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _errorMessage = cleanMsg);
        _showSnackBar(cleanMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2026 Choice Electricals Business Palette
    const Color primaryBlue = Color(0xFF087FEF);     // Brand Primary Blue
    const Color darkNavy = Color(0xFF0B3B82);        // Brand Navy Title
    const Color secondaryGray = Color(0xFF6B7280);   // Secondary Text
    const Color lightBlueBg = Color(0xFFEAF5FF);     // Icon Soft Fill
    const Color inputBorder = Color(0xFFE5E7EB);     // Field Neutral Border
    const Color pageBg = Colors.white;                // Page Background

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: darkNavy.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // COMPACT HEADER
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: pageBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: inputBorder),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: darkNavy,
                                  size: 18,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Email Verification',
                              style: TextStyle(
                                color: darkNavy,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 36),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // VERIFICATION ICON
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: lightBlueBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 42,
                            color: primaryBlue,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // MAIN HEADING
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // DESCRIPTION & DYNAMIC EMAIL
                        const Text(
                          'Enter the 6-digit code sent to:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryGray,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // RESPONSIVE 6-DIGIT OTP INPUTS (ZERO OVERFLOW)
                        Row(
                          children: List.generate(6, (index) {
                            final bool isFilled = _otpControllers[index].text.isNotEmpty;
                            final bool isFocused = _focusNodes[index].hasFocus;

                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                                height: 54,
                                child: KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey == LogicalKeyboardKey.backspace &&
                                        _otpControllers[index].text.isEmpty &&
                                        index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isFilled ? darkNavy : primaryBlue,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isFilled ? primaryBlue : inputBorder,
                                          width: isFilled ? 1.5 : 1.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: primaryBlue,
                                          width: 2.0,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFEF4444),
                                          width: 1.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isFocused
                                          ? lightBlueBg.withOpacity(0.5)
                                          : (isFilled ? Colors.white : pageBg),
                                    ),
                                    onChanged: (value) => _handleOtpInput(index, value),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // ERROR MESSAGE BANNER
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // VERIFY & REGISTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isOtpComplete ? primaryBlue : const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: _isOtpComplete ? primaryBlue.withOpacity(0.3) : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (_isOtpComplete && !_isLoading) ? _handleVerifyAndRegister : null,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'VERIFY & REGISTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // RESEND OTP SECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive the code? ",
                              style: TextStyle(
                                color: secondaryGray,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryBlue,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _timerSeconds == 0 ? _handleResendOtp : null,
                                    child: Text(
                                      _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : 'Resend Code',
                                      style: TextStyle(
                                        color: _timerSeconds == 0 ? primaryBlue : secondaryGray,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
