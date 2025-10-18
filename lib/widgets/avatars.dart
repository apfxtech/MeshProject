import 'package:flutter/material.dart';
import 'dart:math';

class AvatarWidget extends StatelessWidget {
  final String? imagePath;
  final String? text;
  final IconData? icon;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool border;

  const AvatarWidget({
    super.key,
    this.imagePath,
    this.text,
    this.icon,
    this.size = 45.0,
    this.backgroundColor,
    this.foregroundColor,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarBackgroundColor = backgroundColor ?? colorScheme.primaryContainer;
    final avatarForegroundColor = foregroundColor ?? colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarBackgroundColor,
          border: border
              ? Border.all(
                  color: avatarForegroundColor,
                  width: size * 0.08,
                )
              : null,
        ),
        child: Center(
          child: _getAvatarContent(avatarForegroundColor),
        ),
      ),
    );
  }

  Widget? _getAvatarContent(Color foregroundColor) {
    if (imagePath != null) {
      return SizedBox(
        width: size * 0.6,
        height: size * 0.6,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            foregroundColor,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            imagePath!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              if (text != null && text!.isNotEmpty) {
                return _buildText(foregroundColor);
              } else if (icon != null) {
                return _buildIcon(foregroundColor, iconData: icon!);
              } else {
                return _buildIcon(foregroundColor);
              }
            },
          ),
        ),
      );
    } else if (text != null && text!.isNotEmpty) {
      return _buildText(foregroundColor);
    } else if (icon != null) {
      return _buildIcon(foregroundColor, iconData: icon!);
    } else {
      return null;
    }
  }

  Widget _buildText(Color foregroundColor) {
    final displayText = text!.toUpperCase().substring(0, min(2, text!.length));
    return Text(
      displayText,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: foregroundColor,
        fontSize: size * 0.4,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
    );
  }

  Widget _buildIcon(Color foregroundColor, {IconData iconData = Icons.model_training}) {
    return Icon(
      iconData,
      color: foregroundColor,
      size: size * 0.6,
    );
  }
}