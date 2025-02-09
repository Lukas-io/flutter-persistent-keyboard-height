import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'i_persistent_keyboard_height_storage_provider.dart';
import 'persistent_keyboard_height.dart';
import 'shared_preferences_persistent_keyboard_height_storage_provider.dart';

class PersistentKeyboardHeightProvider extends StatefulWidget {
  const PersistentKeyboardHeightProvider({
    required this.child,
    this.storageProvider =
    const SharedPreferencesPersistentKeyboardSizeStorageProvider(),
    Key? key,
  }) : super(key: key);

  final Widget child;
  final IPersistentKeyboardHeightStorageProvider storageProvider;

  @override
  _PersistentKeyboardHeightProviderState createState() =>
      _PersistentKeyboardHeightProviderState();
}

class _PersistentKeyboardHeightProviderState
    extends State<PersistentKeyboardHeightProvider> {
  /// The current keyboard height exposed via [PersistentKeyboardHeight.keyboardHeight]
  double _keyboardHeight = 0.0;

  /// Subscription to keyboard visibility changes
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();

    // Load saved keyboard height
    widget.storageProvider.getHeight().then((value) {
      if (value > 0 && _keyboardHeight < 1) {
        _keyboardHeight = value;
        if (mounted) setState(() {});
      }
    });

    // Listen to keyboard visibility changes
    _keyboardSubscription = KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        // Small delay to ensure view insets are updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            final bottomOffset = MediaQuery.of(context).viewInsets.bottom;
            _updateKeyboardHeight(bottomOffset);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  /// Updates the keyboard height if necessary and saves it
  void _updateKeyboardHeight(double bottomOffset) async {
    if (bottomOffset > 0 && bottomOffset != _keyboardHeight) {
      _keyboardHeight = bottomOffset;
      if (mounted) setState(() {});
      await widget.storageProvider.setHeight(bottomOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentKeyboardHeight(
      keyboardHeight: _keyboardHeight,
      child: widget.child,
    );
  }
}