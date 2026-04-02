// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Completer;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sensitive_content_utils.dart';

void main() {
  const ContentSensitivity defaultContentSensitivitySetting = ContentSensitivity.autoSensitive;
  final SensitiveContentHost sensitiveContentHost = SensitiveContentHost.instance;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.sensitiveContent,
      null,
    );
  });
  testWidgets(
    'while SensitiveContent widget is being registered, SizedBox.shrink is built initially, then child widget is built upon completion',
    (WidgetTester tester) async {
      final setContentSensitivityCompleter = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            return setContentSensitivityCompleter.future;
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return Future<int>.value(defaultContentSensitivitySetting.index);
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return Future<bool>.value(true);
          } else {
            return null;
          }
        },
      );

      final childWidget = Container();

      await tester.pumpWidget(
        SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: childWidget),
      );

      expect(find.byWidget(childWidget), findsNothing);
      final shrinkBox = tester.firstWidget(find.byType(SizedBox)) as SizedBox;
      expect(shrinkBox.width, 0);
      expect(shrinkBox.height, 0);

      setContentSensitivityCompleter.complete();

      // Two pumps to complete registration, then re-build SensitiveContent widget.
      await tester.pump();
      await tester.pump();

      expect(find.byWidget(childWidget), findsOne);
      expect(find.byType(SizedBox), findsNothing);
    },
  );

  testWidgets(
    'when SensitiveContent widget changes sensitivity, SizedBox.shrink is built initially, then child widget is built upon completion',
    (WidgetTester tester) async {
      final setContentSensitivityCompleter = Completer<void>();
      var setContentSensitivityCall = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityCall++;
            // Make second call to update content sensitivity awaits the Future for test.
            if (setContentSensitivityCall == 2 && methodCall.arguments == 'autoSensitive') {
              return setContentSensitivityCompleter.future;
            }
            return Future<void>.value();
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return Future<int>.value(defaultContentSensitivitySetting.index);
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return Future<bool>.value(true);
          } else {
            return null;
          }
        },
      );

      const scKey = Key('scKey');
      final childWidget = Container();

      await tester.pumpWidget(
        ChangeContentSensitivityTester(
          key: scKey,
          initialContentSensitivity: ContentSensitivity.sensitive,
          child: childWidget,
        ),
      );
      await tester.pump();

      final ChangeContentSensitivityTesterState scState = tester
          .firstState<ChangeContentSensitivityTesterState>(find.byKey(scKey));
      scState.changeContentSensitivityTo(ContentSensitivity.autoSensitive);

      await tester.pump();

      expect(find.byWidget(childWidget), findsNothing);
      final shrinkBox = tester.firstWidget(find.byType(SizedBox)) as SizedBox;
      expect(shrinkBox.width, 0);
      expect(shrinkBox.height, 0);

      await tester.pump();

      setContentSensitivityCompleter.complete();

      // Two pumps to complete re-registration, then re-build SensitiveContent widget.
      await tester.pump();
      await tester.pump();

      expect(find.byType(childWidget.runtimeType), findsOne);
      expect(find.byType(SizedBox), findsNothing);

      // Ensure setContentSensitivity was not called more than once upon re-registration.
      expect(setContentSensitivityCall, 2);
    },
  );

  testWidgets(
    'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.register throws FlutterError but still updates calculatedContentSensitivity',
    (WidgetTester tester) async {
      var setContentSensitivityCall = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityCall += 1;
            if (setContentSensitivityCall == 1 &&
                methodCall.arguments == ContentSensitivity.sensitive.index) {
              // In the first call to set content sensitivity, throw platform exception to test
              // SensitiveContentHost.register behavior.
              throw PlatformException(code: 'test exception');
            }
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return ContentSensitivity.autoSensitive.index;
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: Container()),
      );

      expect(tester.takeException(), isA<FlutterError>());
      expect(
        sensitiveContentHost.calculatedContentSensitivity,
        equals(ContentSensitivity.sensitive),
      );
    },
  );

  testWidgets(
    'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.unregister throws FlutterError when no SensitiveContent widgets are left in the tree',
    (WidgetTester tester) async {
      var setContentSensitivityCall = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityCall += 1;
            if (setContentSensitivityCall == 2 &&
                methodCall.arguments == ContentSensitivity.autoSensitive.index) {
              // In the second call to set content sensitivity, throw platform exception to test
              // SensitiveContentHost.unregister behavior.
              throw PlatformException(code: 'test exception');
            }
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return ContentSensitivity.autoSensitive.index;
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        SensitiveContent(sensitivity: ContentSensitivity.sensitive, child: Container()),
      );
      await tester.pumpWidget(Container());

      expect(tester.takeException(), isA<FlutterError>());
      expect(sensitiveContentHost.calculatedContentSensitivity, null);
    },
  );

  testWidgets(
    'when SensitiveContentService.setContentSensitivity fails, SensitiveContentHost.unregister throws FlutterError and still updates calculatedContentSensitivity when there are SensitiveContent widgets left in the tree',
    (WidgetTester tester) async {
      var setContentSensitivityCall = 0;
      const scKey = Key('sc');
      final sc = DisposeTester(
        child: SensitiveContent(
          key: scKey,
          sensitivity: ContentSensitivity.sensitive,
          child: Container(),
        ),
      );
      final asc = SensitiveContent(
        sensitivity: ContentSensitivity.autoSensitive,
        child: Container(),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.sensitiveContent,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SensitiveContent.setContentSensitivity') {
            setContentSensitivityCall += 1;
            if (setContentSensitivityCall == 2 &&
                methodCall.arguments == ContentSensitivity.autoSensitive.index) {
              // In the second call to set content sensitivity, throw platform exception to test
              // SensitiveContentHost.unregister behavior.
              throw PlatformException(code: 'test exception');
            }
          } else if (methodCall.method == 'SensitiveContent.getContentSensitivity') {
            return ContentSensitivity.autoSensitive.index;
          } else if (methodCall.method == 'SensitiveContent.isSupported') {
            return true;
          }
          return null;
        },
      );

      await tester.pumpWidget(Column(children: <Widget>[sc, asc]));

      final DisposeTesterState scDiposeTesterState = tester.firstState<DisposeTesterState>(
        find.byKey(scKey),
      );
      scDiposeTesterState.disposeWidget();
      await tester.pump();

      expect(tester.takeException(), isA<FlutterError>());
      expect(
        sensitiveContentHost.calculatedContentSensitivity,
        equals(ContentSensitivity.autoSensitive),
      );
    },
  );
}
