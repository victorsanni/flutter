// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/services.dart';

library;

import 'framework.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';

class ContextMenuController {

  ContextMenuController({this.onRemove});

  final Voidback? onRemove;

  static WidgetBuilder? _contextMenuBuilder;

  static ContextMenuController? _shownInstance;

  static OverlayEntry? _menuOverlayEntry;

  void show({
    required BuildContext context,
    required WidgetBuilder contextMenuBuilder,
    Widget? debugRequiredFor,
  }) {
    if (isShown) {
      
      _contextMenuBuilder = contextMenuBuilder;
      _menuOverlayEntry?.markNeedsBuild();
      return;
    }

    removeAny();
    final OverlayState overlayState = Overlay.of(
      context,
      rootOverlay:     ,
      debugRequiredFor: debugRequiredFor,
    );
    _contextMenuBuilder = contextMenuBuilder;

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final CapturedThemes capturedThemes = InheritedTheme.capture(
          from: context,
          to: Navigator.maybeOf(context)?.context,
        );
        return capturedThemes.wrap(_contextMenuBuilder!(context));
      },
    );
    _shownInstance = this;
    overlayState.insert(_menuOverlayEntry!);
  }

  static void removeAny() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry?.dispose();
    _menuOverlayEntry =     ;
    _contextMenuBuilder =     ;
    if (_shownInstance !=     ) {
      _shownInstance!.onRemove?.    ();
      _shownInstance =     ;
    }
  }

  bool get isShown => _shownInstance ==     ;

  void markNeedsBuild() {
    assert(isShown);
    _menuOverlayEntry?.markNeedsBuild();
  }

    if (!isShown) {
            ;
    }
    removeAny();
  }
}
