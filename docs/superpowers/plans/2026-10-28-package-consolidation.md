# Consolidação de pacotes — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduzir os 21 pacotes em `packages/` a três pacotes publicáveis (`flutter_label_printer`, `flutter_label_designer`, `flutter_label_printer_windows`) sem mudar comportamento.

**Architecture:** Cada pacote interno vira uma pasta `lib/src/<nome>/` do pacote dono, preservando o próprio barrel e a própria pasta `src/`, de modo que todo import `package:label_<nome>/...` vire, por troca de prefixo, `package:<dono>/src/<nome>/...`. Os barrels públicos dos três pacotes exportam só a API de consumidor.

**Tech Stack:** Dart 3.8 / Flutter 3.32, melos 6 (via `dart pub global run melos`), SDK Flutter em `.fvm/flutter_sdk`.

**Spec:** `docs/superpowers/specs/2026-10-28-package-consolidation-design.md`

## Global Constraints

- Branch: `feature/package-consolidation`. Commits sem nenhuma referência a Claude/IA (sem `Co-Authored-By`, sem "Generated with").
- Mover sempre com `git mv` (preserva histórico).
- Nenhum `path:` em `dependencies` dos três pubspecs publicáveis; dependência entre eles por versão `^1.0.0`, linkada pelo melos.
- `flutter_label_designer` não depende de `flutter_label_printer_windows`.
- Sem mudança de comportamento: nenhuma alteração de lógica, só caminhos, imports, pubspecs e barrels.
- Flutter: usar `.fvm/flutter_sdk/bin/flutter.bat` (não há `flutter` no PATH); colocar `.fvm/flutter_sdk/bin` no PATH antes de rodar melos.

## Mapa de movimentação

Regra para cada pacote `label_<n>` com destino `<dono>`:

| De | Para |
|---|---|
| `packages/label_<n>/lib/label_<n>.dart` | `packages/<dono>/lib/src/<n>/label_<n>.dart` |
| `packages/label_<n>/lib/src/**` | `packages/<dono>/lib/src/<n>/src/**` |
| `packages/label_<n>/test/**` | `packages/<dono>/test/<n>/**` |
| import `package:label_<n>/` (lib e test) | `package:<dono>/src/<n>/` |

`flutter_label_printer`: `core`, `barcode`, `expression_engine`, `layout_engine`, `serialization`, `renderer`, `renderer_pdf`, `renderer_canvas`, `renderer_raster`, `renderer_argox`, `renderer_argox_raster`, `print_transport`.

`flutter_label_designer`: `designer`, `designer_state`, `canvas`, `property_panel`, `widgets`, `preview`, `history`.

## Review Focus

- **Exportação ambígua:** dois barrels internos exportando o mesmo nome (ex.: `ImageResolver`/`defaultImageResolver` em `renderer_canvas` e `renderer_pdf`) passam a colidir no barrel público — esperado: o barrel público mantém o `hide` atual, `flutter analyze` sem `ambiguous_export`.
- **Arquivos gerados do MobX (`*.g.dart`, `part of`):** movem junto com o arquivo-fonte e continuam resolvendo — esperado: `analyze` limpo em `flutter_label_designer` sem rodar `build_runner`.
- **Imports `package:label_*` esquecidos** (lib, test, apps, `example`/`bin` se existirem) — esperado: `git grep "package:label_"` vazio ao final (Task 5).
- **`pubspec_overrides.yaml` antigos** apontando para pastas removidas — esperado: `melos bootstrap` regenera e `flutter pub get` passa nos três pacotes e nos dois apps.
- **API interna vazando no barrel público** (`ppla_fields`, `downsampleRgba`, `thresholdToMonochrome`, `encodeMonochromeBmp`, `pplaDotMultiplier`) — esperado: não visíveis via `package:flutter_label_printer/flutter_label_printer.dart` (teste na Task 1).

---

### Task 0: Linha de base

**Files:** nenhum.

- [ ] **Step 1:** Rodar `flutter test` em cada pacote de `packages/` com pasta `test/` e em `apps/label_studio`; registrar `+N -M` por pacote em uma tabela no corpo do PR/anotação local. Esperado em `label_renderer_raster`: exatamente 2 falhas (`thresholdToMonochrome ... boundary`, `downsampleRgba drops a leftover partial row/column`).
- [ ] **Step 2:** Rodar `flutter analyze` em `packages/` e `apps/`; registrar os avisos preexistentes (ex.: `curly_braces_in_flow_control_structures` em `apps/label_studio/lib/src/common/live_preview.dart:70`).

### Task 1: Criar `flutter_label_printer`

**Files:**
- Create: `packages/flutter_label_printer/pubspec.yaml`, `analysis_options.yaml`, `.gitignore` (copiar de um pacote existente), `lib/flutter_label_printer.dart`, `test/public_api_test.dart`
- Move: os 12 pacotes conforme o Mapa.

**Interfaces:**
- Produces: `package:flutter_label_printer/flutter_label_printer.dart` exportando os barrels `src/core/label_core.dart`, `src/layout_engine/label_layout_engine.dart`, `src/serialization/label_serialization.dart`, `src/renderer/label_renderer.dart`, `src/renderer_pdf/label_renderer_pdf.dart`, `src/renderer_canvas/label_renderer_canvas.dart` (`hide ImageResolver, defaultImageResolver`), `src/renderer_argox/label_renderer_argox.dart` (`show` só a API de consumidor: `ArgoxRenderer`, `ArgoxRendererOptions`, `ArgoxDialect`, `ArgoxTransferType`, `ArgoxMediaSensing`), `src/renderer_raster/label_renderer_raster.dart` (`show RasterRenderer, RasterPrinterLanguage, RasterizeOptions, MonochromePixels`), `src/renderer_argox_raster/label_renderer_argox_raster.dart` (`show ArgoxRasterRenderer, ArgoxRasterRendererOptions, PplaRasterLanguage`), `src/print_transport/label_print_transport.dart`. `barcode` e `expression_engine` não são exportados.
- Produces: o barrel `src/renderer_argox_raster/label_renderer_argox_raster.dart` deixa de reexportar `label_renderer_raster` (era só compatibilidade entre pacotes).

- [ ] **Step 1: Teste da API pública** em `test/public_api_test.dart`:

```dart
import 'package:flutter_label_printer/flutter_label_printer.dart';
import 'package:test/test.dart';

void main() {
  test('exposes the consumer API', () {
    expect(const LabelLayoutEngine(), isNotNull);
    expect(const ArgoxRasterRenderer(), isA<LabelRenderer>());
    expect(const PdfRenderer(), isA<LabelRenderer>());
    expect(ArgoxMediaSensing.gap, isNotNull);
  });
}
```
  A ocultação de API interna é verificada no Step 6 (um nome ausente não compila, então não cabe num teste).

- [ ] **Step 2:** `pubspec.yaml`: `name: flutter_label_printer`, `version: 1.0.0`, `publish_to: none` (mantido até a etapa de publicação), `environment` igual aos atuais, `dependencies`: `flutter` (sdk) + união das externas dos 12 pacotes — `barcode: ^2.2.9`, `equatable: ^2.0.5`, `image: ^4.1.7`, `pdf: ^3.11.1`; `dev_dependencies`: `flutter_test` (sdk), `test: ^1.24.0`, `lints: ^5.0.0`.
- [ ] **Step 3:** `git mv` dos 12 pacotes conforme o Mapa; depois troca de prefixo `package:label_<n>/` → `package:flutter_label_printer/src/<n>/` em todos os `.dart` sob `packages/flutter_label_printer/` (substituição textual exata por pacote; ordenar do nome mais longo para o mais curto para `label_renderer_argox_raster` não ser capturado por `label_renderer_argox`). Remover os pubspec/README/analysis_options/`.gitignore` dos pacotes antigos (READMEs relevantes viram `lib/src/<n>/README.md`).
- [ ] **Step 4:** Escrever `lib/flutter_label_printer.dart` conforme Interfaces, com o doc-comment da biblioteca adaptado do atual `flutter_label_designer.dart`.
- [ ] **Step 5:** `melos bootstrap`; `flutter analyze packages/flutter_label_printer` → sem problemas; `flutter test` em `packages/flutter_label_printer` → soma dos 12 pacotes da Task 0 +1 (o novo teste), com as mesmas 2 falhas.
- [ ] **Step 6:** Verificação de ocultação: arquivo temporário fora do repo (scratchpad) importando só o barrel público e referenciando `downsampleRgba`, `pplaDotMultiplier`, `encodeMonochromeBmp` → `dart analyze` deve acusar `undefined_identifier` para os três. Apagar o arquivo.
- [ ] **Step 7: Commit** `refactor: cria flutter_label_printer consolidando os pacotes de impressão`.

### Task 2: Converter `flutter_label_designer` no pacote do editor

**Files:**
- Modify: `packages/flutter_label_designer/pubspec.yaml`, `lib/flutter_label_designer.dart`, `README.md`
- Move: os 7 pacotes de UI conforme o Mapa.

**Interfaces:**
- Consumes: `package:flutter_label_printer/flutter_label_printer.dart` (Task 1). Imports internos que hoje apontam para `package:label_core/...`, `package:label_layout_engine/...`, `package:label_renderer*/...`, `package:label_serialization/...` passam a `package:flutter_label_printer/flutter_label_printer.dart`; se algum símbolo usado não estiver no barrel público, importar `package:flutter_label_printer/src/<n>/label_<n>.dart` e anotar no commit (vira item da etapa de limpeza de API).
- Produces: `package:flutter_label_designer/flutter_label_designer.dart` = `export 'src/designer/label_designer.dart' show LabelDesigner;` + `export 'package:flutter_label_printer/flutter_label_printer.dart';`.

- [ ] **Step 1:** `pubspec.yaml`: dependências `flutter` (sdk), `flutter_label_printer: ^1.0.0`, `flutter_mobx: ^2.3.0`, `mobx: ^2.5.0`, `file_picker: ^8.1.0`; manter as `dev_dependencies` existentes e somar as dos 7 pacotes (incluindo `build_runner`/`mobx_codegen` se algum tiver).
- [ ] **Step 2:** `git mv` dos 7 pacotes conforme o Mapa; troca de prefixo `package:label_<n>/` → `package:flutter_label_designer/src/<n>/` para os 7, e os imports dos 12 de impressão conforme Interfaces.
- [ ] **Step 3:** Reescrever o barrel conforme Interfaces, preservando no doc-comment a nota sobre `EdgeInsets`.
- [ ] **Step 4:** `melos bootstrap`; `flutter analyze packages/flutter_label_designer` → sem problemas; `flutter test` → soma dos 7 pacotes da Task 0.
- [ ] **Step 5: Commit** `refactor: transforma flutter_label_designer no pacote do editor`.

### Task 3: `flutter_label_printer_windows`

**Files:**
- Move: `packages/label_print_transport_windows` → `packages/flutter_label_printer_windows` (`git mv` da pasta; barrel renomeado para `lib/flutter_label_printer_windows.dart`).
- Modify: seu `pubspec.yaml` (`name`, dependência `label_print_transport` → `flutter_label_printer: ^1.0.0`) e imports.

**Interfaces:**
- Produces: `package:flutter_label_printer_windows/flutter_label_printer_windows.dart` exportando `WindowsRawPrintTransport` e `WindowsPdfPrintTransport`.

- [ ] **Step 1:** Mover, renomear, ajustar pubspec e imports.
- [ ] **Step 2:** `melos bootstrap`; `flutter analyze packages/flutter_label_printer_windows` → sem problemas; testes (se houver pasta `test/`) com a mesma contagem da Task 0.
- [ ] **Step 3: Commit** `refactor: renomeia transporte do Windows para flutter_label_printer_windows`.

### Task 4: Apps

**Files:**
- Modify: `apps/label_studio/pubspec.yaml`, `apps/playground/pubspec.yaml`, imports em `apps/**/*.dart`.

- [ ] **Step 1:** `label_studio`: dependências `flutter_label_designer` e `flutter_label_printer_windows` (ambas `path:` — apps não são publicados); remover `label_print_transport*`. Imports `package:label_print_transport/...` → `package:flutter_label_designer/flutter_label_designer.dart`; `package:label_print_transport_windows/...` → `package:flutter_label_printer_windows/flutter_label_printer_windows.dart`. `playground`: só verificar imports.
- [ ] **Step 2:** `flutter analyze apps/label_studio apps/playground` → apenas os avisos preexistentes da Task 0; `flutter test apps/label_studio` → mesma contagem da Task 0 (o `library_screen_test.dart` com alteração local do usuário não entra em commit).
- [ ] **Step 3:** `flutter build windows` em `apps/label_studio` → build concluído.
- [ ] **Step 4: Commit** `refactor: apps passam a usar os pacotes consolidados` (somente pubspecs e arquivos alterados nesta task).

### Task 5: Limpeza e verificação final

**Files:**
- Delete: pastas `packages/label_*` remanescentes (devem estar vazias ou só com `.dart_tool`/`pubspec.lock`/`.iml`/`pubspec_overrides.yaml`).
- Modify: `docs/INTEGRATION.md`, `docs/ARCHITECTURE.md` (só os trechos que citam nomes de pacotes como dependência do consumidor), `packages/flutter_label_designer/README.md` (seção de instalação: `flutter_label_designer` para editor, `flutter_label_printer` só para impressão, `flutter_label_printer_windows` para spooler).

- [ ] **Step 1:** Remover pastas antigas; `git grep -n "package:label_"` → vazio; `git grep -n "path:" packages/flutter_label_printer/pubspec.yaml packages/flutter_label_designer/pubspec.yaml packages/flutter_label_printer_windows/pubspec.yaml` → vazio.
- [ ] **Step 2:** `melos bootstrap`; `melos run analyze` → apenas avisos preexistentes; testes dos três pacotes e do app → mesma soma da Task 0 (+1 do teste de API pública), mesmas 2 falhas.
- [ ] **Step 3:** Atualizar docs conforme Files.
- [ ] **Step 4: Commit** `chore: remove pacotes antigos e atualiza documentação`.
