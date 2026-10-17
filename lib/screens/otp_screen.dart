import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? name;
  final String? initialDevOtp;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.name,
    this.initialDevOtp,
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
  String? _currentDevOtp;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Choice Electricals Brand Design System Tokens - Navy Blue + Teal + White
  static const Color darkNavy = AppColors.primaryNavy;         // Deep Navy Blue #183153
  static const Color goldAccent = AppColors.secondaryTeal;     // Secondary Teal #00A6A6
  static const Color goldAccentDark = AppColors.secondaryTeal; // Secondary Teal #00A6A6
  static const Color secondaryGray = AppColors.textSecondary;  // Slate-500 neutral text #64748B
  static const Color inputBorder = AppColors.border;           // Subtle inactive border #E2E8F0
  static const Color pageBg = AppColors.background;            // Soft background #F4F7FB

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.initialDevOtp;
    if (_currentDevOtp != null && _currentDevOtp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = _currentDevOtp![i];
      }
    }
    _startResendTimer();

    // Fast, professional micro-animation (350 ms)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    // Auto-focus first digit field after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_currentDevOtp == null || _currentDevOtp!.length != 6) {
          _focusNodes[0].requestFocus();
        }
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

  String get _formattedPhone {
    final clean = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return '+91 ${widget.phoneNumber}';
  }

  void _handleOtpInput(int index, String value) {
    setState(() => _errorMessage = null);

    // Handle Pasted 6 digits
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = digits[i];
        }
        _focusNodes[5].requestFocus();
        setState(() {});
        _handleVerifyAndLogin();
        return;
      }
    }

    if (value.isNotEmpty) {
      _otpControllers[index].text = value.substring(value.length - 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete) {
          _handleVerifyAndLogin();
        }
      }
    }
    setState(() {});
  }

  void _handleBackspace(int index) {
    setState(() => _errorMessage = null);
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].text = '';
    } else {
      _otpControllers[index].text = '';
    }
    setState(() {});
  }

  Future<void> _handleVerifyAndLogin() async {
    if (!_isOtpComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await context.read<ApiService>().verifyPhoneOtp(
            phoneNumber: widget.phoneNumber,
            otp: _otpCode,
            name: widget.name,
          );

      if (mounted) {
        final isNew = res['isNewUser'] == true;
        if (isNew) {
          _showSnackBar('Welcome to Choice Electricals! Let\'s set up your profile.', isError: false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(phoneNumber: widget.phoneNumber),
            ),
            (route) => false,
          );
        } else {
          _showSnackBar('Logged in successfully!', isError: false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final rawMsg = e.toString().replaceAll('Exception: ', '').trim();
        final lower = rawMsg.toLowerCase();
        String friendlyError;
        if (lower.contains('expired')) {
          friendlyError = 'This code has expired. Request a new code.';
        } else if (lower.contains('invalid') || lower.contains('incorrect') || lower.contains('wrong')) {
          friendlyError = 'The code you entered is incorrect. Please try again.';
        } else {
          friendlyError = "We couldn't verify the code. Check your connection and try again.";
        }
        setState(() => _errorMessage = friendlyError);
        _showSnackBar(friendlyError, isError: true);
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
      final res = await context.read<ApiService>().sendPhoneOtp(
            widget.phoneNumber,
            name: widget.name,
          );

      if (mounted) {
        if (res['devOtp'] != null) {
          _currentDevOtp = res['devOtp'].toString();
          if (_currentDevOtp!.length == 6) {
            for (int i = 0; i < 6; i++) {
              _otpControllers[i].text = _currentDevOtp![i];
            }
          }
        }
        final devCode = res['devOtp'] != null ? ' (Dev OTP: ${res['devOtp']})' : '';
        _showSnackBar('New verification code sent to $_formattedPhone$devCode');
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
        backgroundColor: isError ? const Color(0xFFEF4444) : AppColors.successGreen,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. INDEPENDENT TOP-LEFT BACK BUTTON (No shared row, zero overflow)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: inputBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: darkNavy,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. CHOICE ELECTRICALS LOGO (Centered, ~82 px, exact authentic asset)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: goldAccent.withValues(alpha: 0.22),
                                blurRadius: 22,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 82,
                              height: 82,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. HEADING: Verify your mobile number (Allows natural wrapping)
                      const Text(
                        'Verify your mobile number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkNavy,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 4. SHORT DESCRIPTION
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Text(
                          'Enter the 6-digit code we sent to your phone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: secondaryGray,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. PHONE NUMBER INFORMATION CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: inputBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Code sent to',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formattedPhone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: darkNavy,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: inputBorder),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: goldAccentDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 6. SIX INDIVIDUAL OTP BOXES (Using Expanded to mathematically eliminate overflow)
                      Row(
                        children: List.generate(6, (index) {
                          final isFocused = _focusNodes[index].hasFocus;
                          final isFilled = _otpControllers[index].text.isNotEmpty;
                          final hasError = _errorMessage != null;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.5),
                              child: SizedBox(
                                height: 52,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: isFocused
                                        ? Colors.white
                                        : (isFilled ? AppColors.lightTeal : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: hasError
                                          ? const Color(0xFFEF4444)
                                          : (isFocused
                                              ? goldAccent
                                              : (isFilled ? goldAccent.withValues(alpha: 0.65) : inputBorder)),
                                      width: (isFocused || isFilled) ? 1.8 : 1.2,
                                    ),
                                    boxShadow: isFocused
                                        ? [
                                            BoxShadow(
                                              color: goldAccent.withValues(alpha: 0.24),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: KeyboardListener(
                                      focusNode: FocusNode(),
                                      onKeyEvent: (event) {
                                        if (event is KeyDownEvent &&
                                            event.logicalKey == LogicalKeyboardKey.backspace) {
                                          _handleBackspace(index);
                                        }
                                      },
                                      child: TextFormField(
                                        controller: _otpControllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: hasError ? const Color(0xFFEF4444) : darkNavy,
                                        ),
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                        ),
                                        onChanged: (val) => _handleOtpInput(index, val),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // 7. INLINE ERROR STATE (Subtle pill, non-intrusive)
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 15),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 8. BRANDED FULL-WIDTH CTA BUTTON: Verify & Continue →
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isOtpComplete ? darkNavy : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(15),
                            border: _isOtpComplete
                                ? null
                                : Border.all(color: inputBorder, width: 1.2),
                            boxShadow: _isOtpComplete
                                ? [
                                    BoxShadow(
                                      color: darkNavy.withValues(alpha: 0.28),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: (_isOtpComplete && !_isLoading) ? _handleVerifyAndLogin : null,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Verify & Continue',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                              color: _isOtpComplete
                                                  ? Colors.white
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                            color: _isOtpComplete
                                                ? Colors.white
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 9. RESEND SECTION (Subtle & Elegant)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Didn't receive the code?",
                            style: TextStyle(
                              color: secondaryGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _timerSeconds > 0
                              ? Text(
                                  'Resend in ${_timerSeconds.toString().padLeft(2, '0')}s',
                                  style: const TextStyle(
                                    color: secondaryGray,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                )
                              : InkWell(
                                  onTap: _isResending ? null : _handleResendOtp,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: _isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: goldAccentDark,
                                            ),
                                          )
                                        : const Text(
                                            'Resend code',
                                            style: TextStyle(
                                              color: goldAccentDark,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                  ),
                                ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
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
