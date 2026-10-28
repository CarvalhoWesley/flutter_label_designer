import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

import 'monochrome_bitmap.dart';
import 'raster_printer_language.dart';
import 'rgba_downsample.dart';

/// Renders a [ResolvedDocument] for any printer by rasterizing the
/// *entire* label via [CanvasRenderer] (real typography, filled shapes, QR
/// codes, images) into one monochrome image, then letting [language] wrap
/// it in that printer's command language.
///
/// Trades a bigger job (an image instead of compact native commands) for
/// output identical to the preview on every printer, with no per-element
/// encoding to write per language.
class RasterRenderer implements LabelRenderer {
  const RasterRenderer(this.language);

  final RasterPrinterLanguage language;

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final image = await rasterizeMonochrome(
      document,
      language.rasterizeOptions(document, options),
    );
    return language.encodeJob(image, document, options);
  }
}

/// Rasterizes [document] to [MonochromePixels] at one pixel per
/// addressable printer dot — see [RasterizeOptions].
Future<MonochromePixels> rasterizeMonochrome(
  ResolvedDocument document,
  RasterizeOptions options,
) async {
  final supersample = options.supersample;
  final pixelRatio = supersample / options.dotMultiplier;

  const canvasRenderer = CanvasRenderer();
  final image = await canvasRenderer.renderToImage(
    document,
    CanvasRendererOptions(pixelRatio: pixelRatio),
  );
  try {
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      throw StateError('Falha ao rasterizar o ResolvedDocument.');
    }
    final rgba = byteData.buffer.asUint8List();
    final downsampled = supersample > 1
        ? downsampleRgba(
            rgba,
            widthPx: image.width,
            heightPx: image.height,
            factor: supersample,
          )
        : rgba;
    return thresholdToMonochrome(
      downsampled,
      widthPx: image.width ~/ supersample,
      heightPx: image.height ~/ supersample,
      threshold: options.threshold,
      mirrorHorizontal: options.mirrorHorizontal,
    );
  } finally {
    image.dispose();
  }
}
