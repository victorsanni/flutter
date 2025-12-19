// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../painting/mocks_for_image_cache.dart';

void main() {
  testWidgets('CircleAvatar with dark background color', (WidgetTester tester) async {
    const backgroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(
          backgroundColor: backgroundColor,
          radius: 50.0,
          child: Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    // final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    //expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgets('CircleAvatar with light background color', (WidgetTester tester) async {
    const backgroundColor = Color(0xff00ff00);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(
          backgroundColor: backgroundColor,
          radius: 50.0,
          child: Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    // final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    // expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorDark));
  });

  testWidgets('CircleAvatar with image background', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawCircleAvatar(
          backgroundImage: MemoryImage(Uint8List.fromList(kTransparentImage)),
          radius: 50.0,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('CircleAvatar with image foreground', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: RawCircleAvatar(
          foregroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
          radius: 50.0,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
  });

  testWidgets('CircleAvatar backgroundImage is used as a fallback for foregroundImage', (
    WidgetTester tester,
  ) async {
    addTearDown(imageCache.clear);
    final errorImage = ErrorImageProvider();
    var caughtForegroundImageError = false;
    await tester.pumpWidget(
      wrap(
        child: RepaintBoundary(
          child: RawCircleAvatar(
            foregroundImage: errorImage,
            backgroundImage: MemoryImage(Uint8List.fromList(kBlueRectPng)),
            radius: 50.0,
            onForegroundImageError: (_, _) => caughtForegroundImageError = true,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(caughtForegroundImageError, true);
    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.image!.fit, equals(BoxFit.cover));
    await expectLater(
      find.byType(RawCircleAvatar),
      matchesGoldenFile('circle_avatar.fallback.png'),
    );
  });

  testWidgets('CircleAvatar with foreground color', (WidgetTester tester) async {
    const foregroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(foregroundColor: foregroundColor, child: Text('Z')),
      ),
    );

    //final fallback = ThemeData.fallback();

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(40.0, 40.0)));
    //final child = box.child! as RenderDecoratedBox;
    // final decoration = child.decoration as BoxDecoration;
    // expect(decoration.color, equals(fallback.primaryColorDark));

    final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    expect(paragraph.text.style!.color, equals(foregroundColor));
  });

  testWidgets('CircleAvatar text does not expand with textScaler', (WidgetTester tester) async {
    const foregroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(foregroundColor: foregroundColor, child: Text('Z')),
      ),
    );

    expect(tester.getSize(find.text('Z')), equals(const Size(16.0, 16.0)));

    await tester.pumpWidget(
      wrap(
        child: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(111.0, 111.0),
            devicePixelRatio: 1.1,
            padding: EdgeInsets.all(11.0),
          ),
          child: RawCircleAvatar(
            child: Builder(
              builder: (BuildContext context) {
                final MediaQueryData data = MediaQuery.of(context);

                // These should not change.
                expect(data.size, equals(const Size(111.0, 111.0)));
                expect(data.devicePixelRatio, equals(1.1));
                expect(data.padding, equals(const EdgeInsets.all(11.0)));

                // This should be overridden to 1.0.
                expect(data.textScaler, TextScaler.noScaling);
                return const Text('Z');
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.text('Z')), equals(const Size(16.0, 16.0)));
  });

  testWidgets('CircleAvatar respects minRadius', (WidgetTester tester) async {
    const backgroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const UnconstrainedBox(
          child: RawCircleAvatar(
            backgroundColor: backgroundColor,
            minRadius: 50.0,
            child: Text('Z'),
          ),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    //final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    //expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgets('CircleAvatar respects maxRadius', (WidgetTester tester) async {
    const backgroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(
          backgroundColor: backgroundColor,
          maxRadius: 50.0,
          child: Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    //final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    //expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgets('CircleAvatar respects setting both minRadius and maxRadius', (
    WidgetTester tester,
  ) async {
    const backgroundColor = Color(0xffff0000);
    await tester.pumpWidget(
      wrap(
        child: const RawCircleAvatar(
          backgroundColor: backgroundColor,
          maxRadius: 50.0,
          minRadius: 50.0,
          child: Text('Z'),
        ),
      ),
    );

    final RenderConstrainedBox box = tester.renderObject(find.byType(RawCircleAvatar));
    expect(box.size, equals(const Size(100.0, 100.0)));
    final child = box.child! as RenderDecoratedBox;
    final decoration = child.decoration as BoxDecoration;
    expect(decoration.color, equals(backgroundColor));

    // final RenderParagraph paragraph = tester.renderObject(find.text('Z'));
    // expect(paragraph.text.style!.color, equals(ThemeData.fallback().primaryColorLight));
  });

  testWidgets('CircleAvatar renders at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        child: const SizedBox.shrink(child: RawCircleAvatar(child: Text('X'))),
      ),
    );
  });
}

Widget wrap({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        builder: (BuildContext context, Widget? child) {
          return Center(child: child);
        },
        home: child,
      ),
    ),
  );
}
