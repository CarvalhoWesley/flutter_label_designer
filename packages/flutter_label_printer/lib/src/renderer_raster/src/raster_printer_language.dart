import 'dart:typed_data';

import '../../core/label_core.dart';
import '../../renderer/label_renderer.dart';

import 'monochrome_bitmap.dart';

/// How [RasterRenderer] turns a [ResolvedDocument] into [MonochromePixels]
/// before handing it to a [RasterPrinterLanguage].
class RasterizeOptions {
  const RasterizeOptions({
    this.dotMultiplier = 1,
    this.supersample = 4,
    this.threshold = 128,
    this.mirrorHorizontal = false,
  }) : assert(dotMultiplier >= 1, 'dotMultiplier must be at least 1'),
       assert(supersample >= 1, 'supersample must be at least 1');

  /// Physical print-head dots per image pixel, per axis — e.g. 2 for a
  /// 203 DPI Argox at PPLA's `D22` default. The final image has exactly
  /// one pixel per *addressable* dot; anything else prints the label at
  /// the wrong physical size.
  final int dotMultiplier;

  /// How many times finer to render before averaging down to the final
  /// grid (see [downsampleRgba]) — anti-aliasing only, never changes the
  /// final image's pixel dimensions. `1` disables it.
  final int supersample;

  /// Luminance threshold (0-255) below which a pixel is printed — see
  /// [thresholdToMonochrome].
  final int threshold;

  /// Mirrors every row left-right — see [thresholdToMonochrome].
  final bool mirrorHorizontal;
}

/// The printer-language-specific half of a raster print job: everything
/// [RasterRenderer] can't know on its own — how a given command language
/// wants the image rasterized, and the bytes that wrap it (job header,
/// image download, image placement, copies, end of job).
///
/// Supporting a new printer language means implementing just this — the
/// rasterization itself is shared.
abstract interface class RasterPrinterLanguage {
  /// How to rasterize [document] for this language, given the caller's
  /// [options] (a language-specific [RendererOptions] subclass, or a
  /// generic one — implementations fall back to their own defaults).
  RasterizeOptions rasterizeOptions(
    ResolvedDocument document,
    RendererOptions options,
  );

  /// Wraps the already-rasterized [image] into a complete print job.
  Uint8List encodeJob(
    MonochromePixels image,
    ResolvedDocument document,
    RendererOptions options,
  );
}
