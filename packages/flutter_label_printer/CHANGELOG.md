# Changelog

## 2.0.0

### Quebras
- Novo pacote. Consolida os antigos `label_core`, `label_barcode`, `label_expression_engine`, `label_layout_engine`, `label_serialization`, `label_renderer`, `label_renderer_pdf`, `label_renderer_canvas`, `label_renderer_argox`, `label_renderer_argox_raster` e `label_print_transport`, que deixam de existir. Importe tudo por `package:flutter_label_printer/flutter_label_printer.dart`.
- A API pública ficou enxuta: detalhes internos (`downsampleRgba`, `thresholdToMonochrome`, `encodeMonochromeBmp`, `pplaDotMultiplier` e demais funções de campo PPLA, geração de barcode, motor de expressões) não são mais exportados.
- Argox: o padrão do cabeçalho passou a ser o sensor de gap (`<STX>e`) em vez do comprimento contínuo (`<STX>c`). `feedOffsetMm` só é aplicado em `ArgoxMediaSensing.continuous`.

### Novidades
- `ArgoxRendererOptions.mediaSensing` (`gap`, `blackMark`, `continuous`).
- `RasterRenderer` + `RasterPrinterLanguage` + `RasterizeOptions` + `MonochromePixels`: base genérica de impressão em imagem. `ArgoxRasterRenderer` agora é `RasterRenderer(PplaRasterLanguage())`, e outras linguagens (PPLB, ZPL, TSPL) só precisam implementar `RasterPrinterLanguage`.

### Correções
- Argox: a impressão em lotes grandes deixava de "subir" etiqueta após etiqueta até cair entre duas — a impressora agora ressincroniza no gap a cada etiqueta, inclusive no modo imagem.
