import 'dart:convert';
import 'dart:typed_data';

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:label_renderer_raster/label_renderer_raster.dart';

import 'argox_raster_renderer_options.dart';
import 'bmp_encoder.dart';

const _stx = '\x02';
const _cr = '\r';

/// The Argox PPLA half of a raster print job: job-level framing shared with
/// [ArgoxRenderer] (clear memory, media sensing, darkness, copies) around a
/// single monochrome BMP sent via PPLA's `<STX>I` image-download command
/// plus a "5: Images" placement record.
///
/// See this package's README for exactly which parts of the PPLA image
/// protocol below are sourced from the Datamax Class Series 2
/// Programmer's Manual versus still needing validation against real
/// Argox hardware.
class PplaRasterLanguage implements RasterPrinterLanguage {
  const PplaRasterLanguage();

  @override
  RasterizeOptions rasterizeOptions(
    ResolvedDocument document,
    RendererOptions options,
  ) {
    final raster = _optionsOf(options);
    return RasterizeOptions(
      dotMultiplier: _dotMultiplier(document, raster),
      supersample: raster.supersample,
      threshold: raster.threshold,
      mirrorHorizontal: raster.mirrorHorizontal,
    );
  }

  @override
  Uint8List encodeJob(
    MonochromePixels image,
    ResolvedDocument document,
    RendererOptions options,
  ) {
    final raster = _optionsOf(options);
    const argoxRenderer = ArgoxRenderer();
    // Always 'b' — 'B' ("flipped") is the designator tied to a negative
    // biHeight, confirmed to hang real hardware (see encodeMonochromeBmp).
    // Row order is controlled purely by ArgoxRasterRendererOptions.
    // reverseRowOrder, in the BMP bytes themselves, never via this field.
    const format = 'b';

    final builder = BytesBuilder(copy: false);
    builder.add(latin1.encode(argoxRenderer.clearMemoryCommand()));
    // <STX>I{bank}{format}{name}<CR> — data type field (`b` in the
    // manual's own field-letter scheme, unrelated to our `format`
    // variable) is omitted, meaning raw 8-bit binary follows directly;
    // see this package's README for why no terminator is needed after a
    // BMP payload (unlike the unrelated 7-bit-ASCII image format, BMP is
    // self-describing via its own header).
    builder.add(
      latin1.encode(
        '$_stx' 'I${raster.memoryBank}$format${raster.imageName}$_cr',
      ),
    );
    builder.add(
      encodeMonochromeBmp(image, reverseRowOrder: raster.reverseRowOrder),
    );
    builder.add(
      latin1.encode(
        argoxRenderer.labelFormatHeader(
          document,
          raster.base,
          dotMultiplierOverride: _dotMultiplier(document, raster),
        ),
      ),
    );
    // 1Ycd000ffffgggg<name><CR> — rotation 1 (fixed for images), width/
    // height multiplier 1 (no scaling: already rasterized at the exact
    // target dot grid), row/column 0000/0000 (the image *is* the whole
    // label, so it sits at the label's own origin).
    builder.add(latin1.encode('1Y11000' '0000' '0000${raster.imageName}$_cr'));
    builder.add(latin1.encode(argoxRenderer.footer(document, raster.base)));

    return builder.toBytes();
  }

  ArgoxRasterRendererOptions _optionsOf(RendererOptions options) =>
      options is ArgoxRasterRendererOptions
      ? options
      : const ArgoxRasterRendererOptions();

  /// A raster-only job has no barcode module-width field (the one other
  /// place pplaDotMultiplier matters) for D11 to desync — see
  /// ArgoxRasterRendererOptions.fullResolution — so this can safely
  /// override the D command's DPI-based default independently of what a
  /// mixed native-command job would need.
  int _dotMultiplier(
    ResolvedDocument document,
    ArgoxRasterRendererOptions raster,
  ) => raster.fullResolution ? 1 : pplaDotMultiplier(document.dpi);
}
