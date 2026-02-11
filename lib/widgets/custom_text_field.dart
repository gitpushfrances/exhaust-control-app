import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool showPasswordToggle;
  final VoidCallback? onTogglePassword;
  final bool enabled;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.showPasswordToggle = false,
    this.onTogglePassword,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
      if (hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
        // Validate on blur
        if (widget.validator != null) {
          _errorText = widget.validator!(widget.controller.text);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Focus(
            onFocusChange: _onFocusChange,
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: _isFocused
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),

                // Prefix Icon
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused ? AppColors.primary : AppColors.gray,
                        size: 20,
                      )
                    : null,

                // Suffix Icon (Password Toggle or Validation)
                suffixIcon: _buildSuffixIcon(),

                // Border Styling
                filled: true,
                fillColor: widget.enabled
                    ? AppColors.surface
                    : AppColors.background,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),

                // Border States
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.grayBorder,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.grayBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.grayBorder.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),

                // Error Text
                errorText: _errorText,
                errorStyle: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // Show password toggle
    if (widget.showPasswordToggle) {
      return IconButton(
        icon: Icon(
          widget.obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.gray,
          size: 20,
        ),
        onPressed: widget.onTogglePassword,
      );
    }

    // Show validation icon
    if (_errorText != null && _errorText!.isNotEmpty) {
      return const Icon(Icons.error_outline, color: AppColors.error, size: 20);
    } else if (widget.controller.text.isNotEmpty &&
        !_isFocused &&
        widget.validator != null) {
      final validationResult = widget.validator!(widget.controller.text);
      if (validationResult == null) {
        return const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 20,
        );
      }
    }

    return null;
  }
}
