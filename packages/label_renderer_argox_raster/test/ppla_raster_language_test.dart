import 'dart:convert';
import 'dart:typed_data';

import 'package:label_core/label_core.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:label_renderer_argox_raster/label_renderer_argox_raster.dart';
import 'package:test/test.dart';

void main() {
  const document = ResolvedDocument(
    widthDots: 16,
    heightDots: 203,
    dpi: 203,
    elements: [],
  );
  final image = MonochromePixels(
    widthPx: 16,
    heightPx: 2,
    rows: [Uint8List(2), Uint8List(2)],
  );

  String encode(ArgoxRasterRendererOptions options) =>
      latin1.decode(const PplaRasterLanguage().encodeJob(image, document, options));

  test('wraps the BMP in the PPLA image job framing', () {
    final output = encode(const ArgoxRasterRendererOptions());

    expect(output, startsWith('\x02qA\r\x02IDbLBL\rBM'));
    expect(output, contains('\x02L\rD11\r'));
    expect(output, contains('1Y11000' '0000' '0000LBL\r'));
    expect(output, endsWith('Q0001\rE\r'));
  });

  test('uses the gap sensor by default, without a fixed length', () {
    final output = encode(const ArgoxRasterRendererOptions());

    expect(output, contains('\x02e\r'));
    expect(output, isNot(contains('\x02c')));
  });

  test('keeps the continuous length when asked for continuous media', () {
    final output = encode(
      const ArgoxRasterRendererOptions(
        base: ArgoxRendererOptions(mediaSensing: ArgoxMediaSensing.continuous),
      ),
    );

    expect(output, contains('\x02c0100\r'));
  });

  test('rasterizes at the PPLA dot multiplier', () {
    const language = PplaRasterLanguage();
    expect(
      language
          .rasterizeOptions(document, const ArgoxRasterRendererOptions())
          .dotMultiplier,
      1,
    );
    expect(
      language
          .rasterizeOptions(
            document,
            const ArgoxRasterRendererOptions(fullResolution: false),
          )
          .dotMultiplier,
      pplaDotMultiplier(203),
    );
  });
}
