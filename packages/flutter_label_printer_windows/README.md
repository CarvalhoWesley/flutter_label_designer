# flutter_label_printer_windows

Envio de etiquetas para impressoras instaladas no Windows, pelo spooler do sistema. Implementa o contrato `PrintTransport`/`PrinterDiscovery` de [`flutter_label_printer`](../flutter_label_printer).

Fica num pacote separado para que apps Android/iOS que usam `flutter_label_printer` ou `flutter_label_designer` não herdem um plugin só de Windows.

## Features

- **`WindowsRawPrintTransport`** — envia bytes crus (PPLA, ZPL…) direto para a impressora, sem passar pelo driver. É o caminho para `ArgoxRasterRenderer`/`ArgoxRenderer`.
- **`WindowsPdfPrintTransport`** — imprime um PDF pelo driver da impressora (aceita `copies`).
- **`WindowsPrinterDiscovery`** — lista as impressoras instaladas.

## Getting started

```yaml
dependencies:
  flutter_label_printer: ^2.0.0 # ou flutter_label_designer
  flutter_label_printer_windows: ^2.0.0
```

## Usage

```dart
import 'package:flutter_label_printer/flutter_label_printer.dart';
import 'package:flutter_label_printer_windows/flutter_label_printer_windows.dart';

final impressoras = await const WindowsPrinterDiscovery().listAvailable();

final bytes = await const ArgoxRasterRenderer().render(
  resolved,
  const ArgoxRasterRendererOptions(base: ArgoxRendererOptions(copies: 2)),
);

await const WindowsRawPrintTransport().send(bytes, target: impressoras.first);
```

`target: null` usa a impressora padrão do sistema.

Ao imprimir várias linhas de um rolo com colunas, concatene os bytes de todas as linhas e envie **um único** job: jobs separados em sequência fazem a impressora começar o próximo antes de terminar de avançar o papel, e as linhas saem sobrepostas.
