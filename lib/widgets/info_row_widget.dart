import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isDivided;
  final Color? valueColor;
  final Widget? trailing;

  const InfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isDivided = true,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? textPrimary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
        if (isDivided)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
