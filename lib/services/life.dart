// ./services/life.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class AppLifeService {
  static AppLifeService? _instance;
  factory AppLifeService() => _instance ??= AppLifeService._();
  AppLifeService._() : _currentState = WidgetsBinding.instance.lifecycleState;

  late final AppLifecycleListener _listener;
  AppLifecycleState? _currentState;

  // Optional callbacks for state changes
  void Function()? _onResume;
  void Function()? _onPause;
  void Function()? _onInactive;
  void Function()? _onDetached;

  late final GlobalKey<NavigatorState> _navigatorKey;

  bool get isActive => _currentState == AppLifecycleState.resumed;

  void init({
    required GlobalKey<NavigatorState> navigatorKey,
    void Function()? onResume,
    void Function()? onPause,
    void Function()? onInactive,
    void Function()? onDetached,
  }) {
    _navigatorKey = navigatorKey;
    _onResume = onResume;
    _onPause = onPause;
    _onInactive = onInactive;
    _onDetached = onDetached;

    // Activate callback for current status upon initialization
    if (_currentState != null) {
      _handleStateChange(_currentState!);
    }

    _listener = AppLifecycleListener(
      onStateChange: (state) {
        _currentState = state;
        _handleStateChange(state);
      },
      onExitRequested: _onExitRequested,
    );
  }

  void _handleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResume?.call();
        break;
      case AppLifecycleState.inactive:
        _onInactive?.call();
        break;
      case AppLifecycleState.hidden:
        _onInactive?.call();
        break;
      case AppLifecycleState.paused:
        _onPause?.call();
        break;
      case AppLifecycleState.detached:
        _onDetached?.call();
        break;
    }
  }

  Future<AppExitResponse> _onExitRequested() async {
    final context = _navigatorKey.currentContext;
    if (context == null) return AppExitResponse.exit;

    final response = await showDialog<AppExitResponse>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Are you sure you want to quit this app?'),
        content: const Text('All unsaved progress will be lost.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(AppExitResponse.cancel);
            },
          ),
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop(AppExitResponse.exit);
            },
          ),
        ],
      ),
    );

    return response ?? AppExitResponse.exit;
  }

  void dispose() {
    _listener.dispose();
  }
}