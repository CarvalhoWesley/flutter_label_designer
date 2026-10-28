import '../../renderer_raster/label_renderer_raster.dart';

import 'ppla_raster_language.dart';

/// Renders a [ResolvedDocument] to PPLA bytes by rasterizing the *entire*
/// label (real typography, filled shapes, QR codes — see
/// `renderer_raster`) and sending it as a single monochrome image,
/// instead of one native PPLA command per element like `ArgoxRenderer`.
///
/// This exists because PPLA's native text/shape commands have real,
/// unavoidable limits (a fixed internal font ladder, no fill, no true
/// ellipse, no QR) — see `renderer_argox`'s README. Rasterizing
/// sidesteps all of that at the cost of a bigger job (an image instead of
/// compact commands) and losing the printer's own crisp native font
/// rendering. Both renderers stay available side by side.
///
/// Just a [RasterRenderer] bound to [PplaRasterLanguage] — kept as its own
/// type so existing callers don't need to know about the split.
class ArgoxRasterRenderer extends RasterRenderer {
  const ArgoxRasterRenderer() : super(const PplaRasterLanguage());
}
