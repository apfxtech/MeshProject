// lib/widgets/split_or_tabs.dart (updated)
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

class SplitOrTabs extends StatefulWidget {
  const SplitOrTabs({
    required this.tabs,
    required this.children,
    this.controller, // Optional: Accept TabController from parent
    super.key,
  });

  final List<Widget> tabs;
  final List<Widget> children;
  final TabController? controller;

  @override
  State<SplitOrTabs> createState() => _SplitOrTabsState();
}

class _SplitOrTabsState extends State<SplitOrTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _ownsController = false; // Track if we created it locally

  @override
  void initState() {
    super.initState();
    _updateController();
  }

  @override
  void didUpdateWidget(SplitOrTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.tabs.length != oldWidget.tabs.length) {
      _updateController();
    }
  }

  void _updateController() {
    if (_ownsController) {
      _tabController.dispose();
      _ownsController = false;
    }
    if (widget.controller != null) {
      _tabController = widget.controller!;
    } else {
      _tabController = TabController(length: widget.tabs.length, vsync: this);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _tabController.dispose();
    }
    super.dispose();
  }

  List<Widget> _getSafeChildren() {
    final tabCount = widget.tabs.length;
    if (widget.children.length == tabCount) {
      return widget.children;
    } else if (widget.children.length > tabCount) {
      return widget.children.sublist(0, tabCount);
    } else {
      return [
        ...widget.children,
        ...List.generate(
            tabCount - widget.children.length, (_) => const SizedBox.shrink()),
      ];
    }
  }

  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safeChildren = _getSafeChildren();

    // Assuming 3 children for the specific layout: List1 (left), Chat (center), List2 (right)
    if (safeChildren.length == 3) {
      return SplitView(
        controller: SplitViewController(
          weights: [0.25, 0.5, 0.25], // Left 25%, Center 50%, Right 25%
          limits: [
            WeightLimit(min: 0.15), // Min 15% for List1
            WeightLimit(min: 0.4),  // Min 40% for Chat
            WeightLimit(min: 0.15), // Min 15% for List2
          ],
        ),
        viewMode: SplitViewMode.Horizontal,
        gripColor: Colors.transparent, // Remove gray background for passive grip bar
        gripColorActive: colorScheme.surface, // Active grip bar uses theme's surface color
        indicator: SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
          color: colorScheme.primary, // Indicator color for passive state
        ),
        activeIndicator: SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
          isActive: true,
          color: colorScheme.primary,
        ),
        children: [
          // Left pane: List 1
          safeChildren[0],
          // Center pane: Chat
          safeChildren[2],
          // Right pane: List 2
          safeChildren[1],
        ],
      );
    } else {
      // Fallback for other counts: simple split of children
      return SplitView(
        controller: SplitViewController(
          weights: [0.3, 0.7],
          limits: [WeightLimit(min: 0.2), WeightLimit(min: 0.4)],
        ),
        viewMode: SplitViewMode.Horizontal,
        gripColor: Colors.transparent,
        gripColorActive: colorScheme.surface,
        indicator: SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
          color: colorScheme.primary,
        ),
        activeIndicator: SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
          isActive: true,
          color: colorScheme.primary,
        ),
        children: safeChildren,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    final colorScheme = theme.colorScheme;
    return MediaQuery.of(context).size.width > 800
        ? _buildDesktopLayout()
        : Column(
            children: [
              Container(
                color: colorScheme.primaryContainer, // Set background color to primary
                child: TabBar(
                  controller: _tabController,
                  tabs: widget.tabs,
                  labelColor: colorScheme.onPrimaryContainer,
                  unselectedLabelColor:
                      colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                  indicatorColor: colorScheme.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _getSafeChildren(),
                ),
              ),
            ],
          );
  }
}