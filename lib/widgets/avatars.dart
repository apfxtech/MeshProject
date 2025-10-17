import 'package:flutter/material.dart';
import 'dart:math'; // For min function

class AvatarWidget extends StatelessWidget {
  final String? imagePath;
  final String? text;
  final IconData? icon;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AvatarWidget({
    super.key,
    this.imagePath,
    this.text,
    this.icon,
    this.size = 45.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarBackgroundColor = backgroundColor ?? colorScheme.primaryContainer;
    final avatarForegroundColor = foregroundColor ?? colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBackgroundColor,
            ),
          ),
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.transparent,
            child: _getAvatarContent(avatarForegroundColor),
          ),
        ],
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
              //debugPrint('Image load error: $error');
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
      style: TextStyle(
        color: foregroundColor,
        fontSize: size * 0.5,
        fontWeight: FontWeight.bold,
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