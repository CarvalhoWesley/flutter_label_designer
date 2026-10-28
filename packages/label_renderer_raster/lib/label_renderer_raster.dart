/// Base genérica para impressão em imagem: rasteriza um `ResolvedDocument`
/// em uma imagem monocromática e delega a montagem do trabalho a uma
/// [RasterPrinterLanguage] — ver `raster_renderer.dart`.
library;

export 'src/monochrome_bitmap.dart';
export 'src/raster_printer_language.dart';
export 'src/raster_renderer.dart';
export 'src/rgba_downsample.dart';
