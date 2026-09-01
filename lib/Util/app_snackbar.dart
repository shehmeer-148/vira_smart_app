import 'package:flutter/material.dart';
import 'package:vira_planter_app/Core/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(
      BuildContext context,
      String message,
      ) {
    _show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  static void error(
      BuildContext context,
      String message,
      ) {
    _show(
      context,
      message,
      icon: Icons.error_rounded,
      color: Colors.redAccent,
    );
  }

  static void warning(
      BuildContext context,
      String message,
      ) {
    _show(
      context,
      message,
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  }

  static void info(
      BuildContext context,
      String message,
      ) {
    _show(
      context,
      message,
      icon: Icons.info_rounded,
      color: AppColors.primary,
    );
  }

  static void _show(
      BuildContext context,
      String message, {
        required IconData icon,
        required Color color,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 4),
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withOpacity(.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(.15),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
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