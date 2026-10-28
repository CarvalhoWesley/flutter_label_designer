import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_label_printer/src/core/label_core.dart';
import 'package:flutter_label_printer/src/renderer/label_renderer.dart';
import 'package:flutter_label_printer/src/renderer_raster/label_renderer_raster.dart';

/// A language with no real printer behind it — proves [RasterRenderer]
/// needs nothing vendor-specific.
class _FakeLanguage implements RasterPrinterLanguage {
  _FakeLanguage(this.dotMultiplier);

  final int dotMultiplier;
  MonochromePixels? received;

  @override
  RasterizeOptions rasterizeOptions(
    ResolvedDocument document,
    RendererOptions options,
  ) => RasterizeOptions(dotMultiplier: dotMultiplier, supersample: 1);

  @override
  Uint8List encodeJob(
    MonochromePixels image,
    ResolvedDocument document,
    RendererOptions options,
  ) {
    received = image;
    return Uint8List.fromList([image.widthPx, image.heightPx]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const document = ResolvedDocument(
    widthDots: 80,
    heightDots: 40,
    dpi: 203,
    elements: [],
  );

  test('hands the language one pixel per addressable dot', () async {
    final language = _FakeLanguage(1);
    final bytes = await RasterRenderer(language).render(
      document,
      const RendererOptions(),
    );

    expect(bytes, [80, 40]);
    expect(language.received!.rows, hasLength(40));
  });

  test('shrinks the image by the language dot multiplier', () async {
    final language = _FakeLanguage(2);
    await RasterRenderer(language).render(document, const RendererOptions());

    expect(language.received!.widthPx, 40);
    expect(language.received!.heightPx, 20);
  });
}
