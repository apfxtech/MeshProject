// lib/widgets/appbar.dart
import 'package:flutter/material.dart';
import 'avatars.dart';

class AegisAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AegisAppBar({
    super.key,
    this.longName,
    this.shortName,
    this.loadingIcon,
    this.isLoading = false,
  });

  final String? longName;
  final String? shortName;
  final IconData? loadingIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          AvatarWidget(
            icon: isLoading ? (loadingIcon ?? Icons.bluetooth_disabled) : Icons.public,
            //text: shortName?.isNotEmpty == true ? shortName!.substring(0, 1).toUpperCase() : "A",
            size: 40.0,
          ),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              longName ?? 'Aegis',
              style: const TextStyle(fontSize: 20.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}