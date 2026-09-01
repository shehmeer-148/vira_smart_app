import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

import '../../Core/app_colors.dart';

Widget pairingCard({
  required BuildContext context,
  required String image,
  required String title,
  required String subtitle,
  double iconSize = 40,
  bool glow = true,
}) {
  final text = Theme.of(context).textTheme;

  return Card(
    elevation: 3,
    clipBehavior: Clip.none,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          glow
              ? Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: AvatarGlow(
              glowColor: AppColors.primaryLight.withOpacity(.20),
              glowRadiusFactor: 1,
              glowCount: 3,
              curve: Curves.easeInOut,
              animate: true,
              duration: const Duration(milliseconds: 3000),
              repeat: true,
              child: Center(
                child: Image.asset(
                  image,
                  width: iconSize,
                ),
              ),
            ),
          )

              : Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                image,
                width: iconSize,
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.labelLarge?.copyWith(color: AppColors.primary,fontWeight: FontWeight.bold,),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
Widget deviceTile({
  required BuildContext context,
  required String name,
  required String status,
  bool selected = false,
  VoidCallback? onTap,
}) {
  final text = Theme.of(context).textTheme;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      elevation: selected ? 4 : 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: AppColors.primary,
                size: 22,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      status,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}