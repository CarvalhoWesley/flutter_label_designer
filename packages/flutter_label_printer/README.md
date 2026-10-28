# flutter_label_printer

Impressão de etiquetas para Flutter, sem o editor visual: modelo de etiqueta, serialização `.label`, motor de layout com variáveis/expressões e renderers prontos (PDF, PNG, PPLA/Argox nativo e PPLA em imagem).

Use este pacote quando os modelos de etiqueta já existem (arquivos `.label` criados no editor, em outro app ou gerados por código) e o app só precisa preencher os dados e imprimir. Para embutir também o editor, use [`flutter_label_designer`](../flutter_label_designer), que já reexporta tudo daqui.

## Features

- **`LabelDocument`** e todo o modelo de domínio (elementos, camadas, variáveis, `PageConfig` com colunas).
- **`LabelDocumentCodec`** — lê e grava `.label` (JSON).
- **`LabelLayoutEngine`** — resolve variáveis, expressões `{{ }}` e unidades para o DPI da impressora (`resolve` para uma etiqueta, `resolveBatch` para rolos com várias colunas).
- **Renderers**:
  - `PdfRenderer` — PDF vetorial.
  - `CanvasRenderer` — PNG/JPEG.
  - `ArgoxRasterRenderer` — PPLA em imagem: a etiqueta sai idêntica ao preview (fontes reais, QR, imagens, formas preenchidas). **Recomendado para Argox.**
  - `ArgoxRenderer` — PPLA com comandos nativos por elemento (job menor, mas com os limites de fonte/forma do PPLA).
- **Extensível**:
  - `RasterRenderer` + `RasterPrinterLanguage` — para suportar outra linguagem de impressora em modo imagem, basta implementar o envoltório da linguagem; a rasterização é compartilhada.
  - `LabelRenderer`/`RendererOptions`/`BaseRenderer` — contrato para renderers de comandos nativos.
  - `PrintTransport`/`PrinterDiscovery` — contrato para enviar bytes a uma impressora (ver [`flutter_label_printer_windows`](../flutter_label_printer_windows)).

## Getting started

Requer Flutter `>=3.32.0` e Dart SDK `^3.8.1`.

```yaml
dependencies:
  flutter_label_printer: ^2.0.0
```

## Usage

### Carregar um modelo, preencher e gerar os bytes

```dart
import 'package:flutter_label_printer/flutter_label_printer.dart';

final documento = const LabelDocumentCodec().decode(conteudoDoArquivoLabel);

final resolved = const LabelLayoutEngine().resolve(documento, {
  'produto': 'Parafuso Sextavado M6',
  'preco': 3.9,
});

// Argox (PPLA em imagem), 10 cópias, etiquetas separadas por gap:
final bytes = await const ArgoxRasterRenderer().render(
  resolved,
  const ArgoxRasterRendererOptions(
    base: ArgoxRendererOptions(copies: 10, darkness: 12),
  ),
);

// PDF:
final pdf = await const PdfRenderer().render(resolved, const PdfRendererOptions());
```

Os bytes PPLA vão crus para a impressora (spooler do Windows, socket TCP na porta 9100, USB…). No Windows, use `WindowsRawPrintTransport` de `flutter_label_printer_windows`.

### Tipo de mídia (Argox)

`ArgoxRendererOptions.mediaSensing` define como a impressora acha o início de cada etiqueta:

| Valor | Quando usar |
|---|---|
| `ArgoxMediaSensing.gap` (padrão) | Etiquetas separadas por gap. A impressora ressincroniza a cada etiqueta, sem deslocamento acumulado em lotes grandes. |
| `ArgoxMediaSensing.blackMark` | Papel com marca preta no verso. |
| `ArgoxMediaSensing.continuous` | Papel contínuo. Usa a altura da etiqueta + `feedOffsetMm` como avanço fixo. |

Para ajustar a posição do conteúdo dentro da etiqueta, use `offsetXMm`/`offsetYMm`.

### Rolos com várias colunas

Com `PageConfig.columns > 1`, use `resolveBatch(documento, registros)`: cada registro vira uma etiqueta, distribuída pelas colunas, e cada item retornado é uma linha física do rolo. Renderize cada linha e concatene os bytes PPLA num único job.

### Armadilha conhecida: `EdgeInsets`

O `EdgeInsets` do modelo (margens em mm) tem o mesmo nome do `EdgeInsets` do Flutter. Se o arquivo importar os dois:

```dart
import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter_label_printer/flutter_label_printer.dart';
```

## Additional information

Detalhes de cada módulo (protocolo PPLA, decisões e limitações) ficam nos READMEs em `lib/src/<módulo>/`. Arquitetura geral: `docs/ARCHITECTURE.md` do repositório.
