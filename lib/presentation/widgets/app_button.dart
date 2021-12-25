import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData? icon;
  final Color color;

  const AppButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.icon,
    this.color = AppColors.fuchsia,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(Icons.add, color: color),
              const SizedBox(width: 8),
              Text(text.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
