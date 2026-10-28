# Changelog

## 2.0.0

### Quebras
- O pacote passa a conter o editor (antigos `label_designer`, `label_designer_state`, `label_canvas`, `label_property_panel`, `label_widgets`, `label_preview` e `label_history`, que deixam de existir) e depende de `flutter_label_printer`, que reexporta inteiro.
- Do editor, só `LabelDesigner` é exportado; stores, widgets internos e o canvas ficam privados.
- Funções internas de impressão que antes vinham pelo barrel (`downsampleRgba`, `encodeMonochromeBmp`, `pplaDotMultiplier` etc.) não são mais exportadas — ver o CHANGELOG de `flutter_label_printer`.

### Novidades
- Tudo de `flutter_label_printer` 2.0.0: sensor de mídia Argox (`ArgoxMediaSensing`) e base genérica de impressão em imagem (`RasterRenderer`/`RasterPrinterLanguage`).

### Correções
- Argox: sem deslocamento acumulado em lotes grandes (sensor de gap por padrão).
