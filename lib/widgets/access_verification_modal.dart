import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccessVerificationModal extends StatefulWidget {
  final String resourceType;
  final dynamic resourceId; // Can be int or String
  final VoidCallback? onSuccess;
  final bool isFirstTimeSetup;

  const AccessVerificationModal({
    super.key,
    required this.resourceType,
    required this.resourceId,
    this.onSuccess,
    this.isFirstTimeSetup = false,
  });

  @override
  State<AccessVerificationModal> createState() => _AccessVerificationModalState();
}

class _AccessVerificationModalState extends State<AccessVerificationModal> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _codeSent = false;
  Timer? _timer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Auto-request code on mount
    _requestVerificationCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _requestVerificationCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiClient.instance.requestAccessVerification(
        resourceType: widget.resourceType,
        resourceId: widget.resourceId.toString(),
      );
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      _startResendTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() {
        _error = "Please enter the 6-digit code";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiClient.instance.verifyAccessCode(
        resourceType: widget.resourceType,
        resourceId: widget.resourceId.toString(),
        code: _codeController.text,
      );

      final sessionToken = result['session_token'];
      // Default to 24 hours (1440 minutes) if backend doesn't specify or returns short duration
      final expiresIn = result['expires_in_minutes'] ?? 1440;

      if (sessionToken != null) {
        await ApiClient.instance.saveSessionToken(
          widget.resourceType,
          widget.resourceId.toString(),
          sessionToken,
          expiresIn is int ? expiresIn : int.parse(expiresIn.toString()),
        );
        
        if (mounted) {
          Navigator.pop(context, true); // Return true on success
          widget.onSuccess?.call();
        }
      } else {
        throw Exception("Invalid response from server");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon header
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF39A4E6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: Color(0xFF39A4E6),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title and Description
          Text(
            widget.isFirstTimeSetup ? "Verify New Profile" : "Security Verification",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isFirstTimeSetup 
                ? "To complete setup and secure this profile, please enter the 6-digit code sent to your email."
                : "To access sensitive medical reports, please enter the 6-digit code sent to your email.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Input Field
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "••••••",
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.3),
                letterSpacing: 8,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFF39A4E6), width: 2),
              ),
              filled: true,
              fillColor: isDark ? Colors.black.withOpacity(0.1) : Colors.grey[50],
            ),
            onChanged: (value) {
              if (value.length == 6) {
                _verifyCode();
              }
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A4E6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Verify Access",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Resend Link
          Center(
            child: TextButton(
              onPressed: (_resendCountdown > 0 || _isLoading) 
                  ? null 
                  : _requestVerificationCode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                _resendCountdown > 0 
                    ? "Resend code in ${_resendCountdown}s" 
                    : "Did not receive code? Resend",
                style: TextStyle(
                  color: (_resendCountdown > 0 || _isLoading)
                      ? Colors.grey
                      : const Color(0xFF39A4E6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ));
  }
}
