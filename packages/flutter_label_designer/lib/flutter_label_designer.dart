/// Editor visual de etiquetas: o widget `LabelDesigner` (canvas, painel de
/// propriedades, preview ao vivo, desfazer/refazer) mais toda a superfície
/// pública de `flutter_label_printer` (modelo de domínio, motor de layout,
/// serialização e renderers), reexportada para que um projeto consumidor
/// precise de uma única dependência.
///
/// Os módulos internos de composição (canvas, painel de propriedades,
/// preview, widgets, histórico e stores) **não** são reexportados — são
/// detalhe de implementação de `LabelDesigner`.
///
/// **Uma armadilha conhecida**: `flutter_label_printer.EdgeInsets` (margens
/// em mm) e `flutter/material.dart`'s `EdgeInsets` têm o mesmo nome. Se seu
/// arquivo importar os dois, use `import 'package:flutter/material.dart'
/// hide EdgeInsets;` — o próprio `LabelDesigner` faz isso internamente.
library;

export 'package:flutter_label_printer/flutter_label_printer.dart';

export 'src/designer/label_designer.dart' show LabelDesigner;
