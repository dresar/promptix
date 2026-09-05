import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = _buildContent(context);
    final padding = _getPadding();

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = _buildGradientButton(context, content, padding);
        break;
      case AppButtonVariant.secondary:
        button = _buildSecondaryButton(context, content, padding, isDark);
        break;
      case AppButtonVariant.outline:
        button = _buildOutlineButton(context, content, padding);
        break;
      case AppButtonVariant.ghost:
        button = _buildGhostButton(context, content, padding);
        break;
      case AppButtonVariant.danger:
        button = _buildDangerButton(context, content, padding);
        break;
    }

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
        ),
      );
    }

    final iconSize = size == AppButtonSize.small ? 16.0 : 18.0;
    final textStyle = _getTextStyle(context);

    if (leadingIcon != null || trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: iconSize),
            const SizedBox(width: 8),
          ],
          Text(label, style: textStyle),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: iconSize),
          ],
        ],
      );
    }

    return Text(label, style: textStyle);
  }

  Widget _buildGradientButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? null
                : AppColors.accentGradient,
            color: onPressed == null
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: padding, child: content),
      ),
    );
  }

  Widget _buildOutlineButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
  ) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: content,
    );
  }

  Widget _buildGhostButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
  ) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: content,
    );
  }

  Widget _buildDangerButton(
    BuildContext context,
    Widget content,
    EdgeInsets padding,
  ) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: content,
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 15);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  TextStyle? _getTextStyle(BuildContext context) {
    final fontSize = size == AppButtonSize.small ? 13.0 : 15.0;
    final color = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => Theme.of(context).colorScheme.onSurface,
      AppButtonVariant.outline => Theme.of(context).colorScheme.primary,
      AppButtonVariant.ghost => Theme.of(context).colorScheme.primary,
      AppButtonVariant.danger => Colors.white,
    };
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: onPressed == null ? color.withValues(alpha: 0.5) : color,
      letterSpacing: 0.1,
    );
  }

  Color _getLoadingColor() {
    return switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.danger => Colors.white,
      _ => AppColors.primary,
    };
  }
}
