import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';

class SessionFlowContinueButton extends StatelessWidget {
  const SessionFlowContinueButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            enabled
                ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x59FB2C36),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 12),
                  ),
                ]
                : const <BoxShadow>[],
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient:
                  enabled
                      ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFF6467), AppColors.redStrong],
                      )
                      : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF3C3F44), Color(0xFF2A2C30)],
                      ),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppColors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionFlowBackButton extends StatelessWidget {
  const SessionFlowBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
