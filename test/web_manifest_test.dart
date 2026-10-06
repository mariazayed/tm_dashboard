import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// "Installable" is a checklist browsers apply to the web manifest; this runs the
/// parts of it we control, so a careless edit cannot silently make the app
/// un-installable on a phone.
void main() {
  late Map<String, dynamic> manifest;
  late String html;

  setUpAll(() {
    manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    html = File('web/index.html').readAsStringSync();
  });

  (int, int) pngSize(String path) {
    final bytes = File(path).readAsBytesSync();
    expect(bytes.sublist(0, 8), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ], reason: '$path is not a PNG');
    final data = ByteData.sublistView(bytes, 16, 24);
    return (data.getUint32(0), data.getUint32(4));
  }

  test('has the fields browsers require to offer an install', () {
    expect((manifest['name'] as String).trim(), isNotEmpty);
    expect((manifest['short_name'] as String).trim(), isNotEmpty);
    expect(manifest['start_url'], isNotNull);
    expect([
      'standalone',
      'fullscreen',
      'minimal-ui',
    ], contains(manifest['display']));
    expect(manifest['prefer_related_applications'], isNot(true));
  });

  test('does not keep the template placeholders', () {
    expect(manifest['name'], isNot('tm_dashboard'));
    expect(manifest['description'], isNot('A new Flutter project.'));
    expect(html, isNot(contains('A new Flutter project.')));
    expect(html, contains('<title>${manifest['name']}</title>'));
  });

  test('is not locked to portrait, since the dashboard is a wide layout', () {
    expect(manifest['orientation'], anyOf(isNull, 'any'));
  });

  test('ships 192 and 512 icons whose real size matches what is declared', () {
    final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    for (final icon in icons) {
      final path = 'web/${icon['src']}';
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      final (w, h) = pngSize(path);
      expect(
        icon['sizes'],
        '${w}x$h',
        reason: '${icon['src']} declares the wrong size',
      );
      expect(icon['type'], 'image/png');
    }
    for (final size in ['192x192', '512x512']) {
      expect(
        icons.any(
          (i) => i['sizes'] == size && (i['purpose'] ?? 'any') == 'any',
        ),
        isTrue,
        reason: 'no plain $size icon',
      );
    }
  });

  test('has maskable icons so Android does not crop the logo badly', () {
    final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    expect(icons.where((i) => i['purpose'] == 'maskable'), isNotEmpty);
  });

  test(
    'index.html links the manifest and the iOS icon, and the theme colours agree',
    () {
      expect(html, contains('<link rel="manifest" href="manifest.json">'));
      expect(html, contains('rel="apple-touch-icon"'));
      expect(File('web/icons/Icon-192.png').existsSync(), isTrue);
      final theme = RegExp(
        'name="theme-color" content="([^"]+)"',
      ).firstMatch(html)?.group(1);
      expect(theme, isNotNull, reason: 'index.html has no theme-color');
      expect(
        theme!.toLowerCase(),
        (manifest['theme_color'] as String).toLowerCase(),
      );
    },
  );

  test('background colour is set so the splash screen is not white', () {
    expect(manifest['background_color'], matches(RegExp(r'^#[0-9a-fA-F]{6}$')));
  });
}
