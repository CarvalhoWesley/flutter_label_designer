/// Rasteriza um `ResolvedDocument` inteiro via `label_renderer_raster` e
/// envia como imagem monocromática para uma impressora Argox via o comando
/// de download de imagem do PPLA — ver `ppla_raster_language.dart` e o
/// README deste pacote.
library;

// Re-exported so existing imports of this package keep seeing the
// rasterization types that moved to label_renderer_raster.
export 'package:label_renderer_raster/label_renderer_raster.dart';

export 'src/argox_raster_renderer.dart';
export 'src/argox_raster_renderer_options.dart';
export 'src/bmp_encoder.dart';
export 'src/ppla_raster_language.dart';
