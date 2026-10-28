/// Ponto de entrada único para a parte de impressão do framework: motor de
/// layout, serialização e renderers prontos (PDF, PNG, PPLA/Argox) atrás de
/// uma única dependência, sem nenhuma UI de edição. Ver `docs/INTEGRATION.md`
/// e `docs/ARCHITECTURE.md`.
///
/// Reexporta a superfície pública que o projeto consumidor toca:
///
/// - `core`: `LabelDocument` e todo o modelo de domínio.
/// - `layout_engine`: `LabelLayoutEngine.resolve(document, data)`.
/// - `serialization`: `LabelDocumentCodec` para persistir `.label`.
/// - `renderer`: o contrato `LabelRenderer`/`RendererOptions` e o
///   `BaseRenderer` Template Method (só relevante se você for escrever um
///   renderer de impressora próprio).
/// - `renderer_pdf`, `renderer_canvas`, `renderer_argox`: os backends de
///   saída prontos (PDF, PNG, PPLA). Do Argox só a API de consumidor é
///   exposta (`ArgoxRenderer`, `ArgoxRendererOptions`, `ArgoxDialect`,
///   `ArgoxTransferType`, `ArgoxMediaSensing`).
/// - `renderer_raster`, `renderer_argox_raster`: variante do backend PPLA
///   que rasteriza a etiqueta inteira em vez de comandos nativos por
///   elemento — contorna os limites de fonte/forma do PPLA nativo ao custo
///   de um job maior.
/// - `print_transport`: contrato `PrintTransport`/`PrinterDiscovery` para
///   enviar bytes já renderizados a uma impressora física.
///
/// `barcode` e `expression_engine` são detalhes de implementação e **não**
/// são reexportados.
///
/// **Uma armadilha conhecida**: `EdgeInsets` (margens em mm) deste pacote e
/// o de `flutter/material.dart` têm o mesmo nome. Se seu arquivo importar os
/// dois, use `import 'package:flutter/material.dart' hide EdgeInsets;`.
library;

export 'src/core/label_core.dart';
export 'src/layout_engine/label_layout_engine.dart';
export 'src/serialization/label_serialization.dart';
export 'src/renderer/label_renderer.dart';
export 'src/renderer_pdf/label_renderer_pdf.dart';
// `ImageResolver`/`defaultImageResolver` are intentionally duplicated,
// identical typedefs in renderer_canvas and renderer_pdf — renderer
// modules are siblings and must not depend on each other. Both resolve to
// the same underlying function type, so hiding the canvas copy here loses
// nothing: a lambda passed as either renderer's `imageResolver` works
// regardless of which typedef name is in scope.
export 'src/renderer_canvas/label_renderer_canvas.dart'
    hide ImageResolver, defaultImageResolver;
export 'src/renderer_argox/label_renderer_argox.dart'
    show
        ArgoxRenderer,
        ArgoxRendererOptions,
        ArgoxDialect,
        ArgoxTransferType,
        ArgoxMediaSensing;
export 'src/renderer_raster/label_renderer_raster.dart'
    show
        RasterRenderer,
        RasterPrinterLanguage,
        RasterizeOptions,
        MonochromePixels;
export 'src/renderer_argox_raster/label_renderer_argox_raster.dart'
    show ArgoxRasterRenderer, ArgoxRasterRendererOptions, PplaRasterLanguage;
export 'src/print_transport/label_print_transport.dart';
