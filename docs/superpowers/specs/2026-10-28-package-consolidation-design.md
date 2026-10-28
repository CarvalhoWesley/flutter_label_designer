# Consolidação de pacotes para publicação no pub.dev

**Data:** 2026-10-28
**Status:** aprovado em conversa; aguardando revisão do spec

## Objetivo

Tornar o projeto publicável no pub.dev atendendo dois perfis de consumidor:

- **(a) App Flutter com editor + impressão** — público principal.
- **(b) App Flutter só de impressão** — modelos `.label` prontos, sem editor;
  não deve carregar MobX, `file_picker` nem o editor.

Hoje são 21 pacotes com `publish_to: none` e dependências `path:`, o que o
pub.dev não aceita. Publicar todos (≈18) gera custo de versionamento
desproporcional e expõe pacotes internos.

## Decisão

Três pacotes publicáveis; os pacotes internos atuais viram pastas em
`lib/src/` de um deles.

| Pacote | Conteúdo (pacotes atuais → `lib/src/<pasta>/`) | Atende |
|---|---|---|
| `flutter_label_printer` | `core`, `barcode`, `expression_engine`, `layout_engine`, `serialization`, `renderer`, `renderer_pdf`, `renderer_canvas`, `renderer_raster`, `renderer_argox`, `renderer_argox_raster`, `print_transport` | (b) e base de (a) |
| `flutter_label_designer` | `designer`, `designer_state`, `canvas`, `property_panel`, `widgets`, `preview`, `history`; depende de `flutter_label_printer` e o reexporta | (a) |
| `flutter_label_printer_windows` | `print_transport_windows` (renomeado) | impressão via spooler do Windows |

O transporte do Windows fica separado para que apps Android/iOS não herdem o
plugin `windows_printer`.

### Superfície pública

- `flutter_label_printer.dart` exporta apenas o que o consumidor usa
  (modelo, `LabelLayoutEngine`, `LabelDocumentCodec`, renderers e opções,
  contratos `LabelRenderer`/`RasterPrinterLanguage`/transporte). Detalhes
  internos (`ppla_fields`, `downsampleRgba`, `thresholdToMonochrome`,
  `encodeMonochromeBmp` etc.) ficam só em `lib/src/`.
- `flutter_label_designer.dart` exporta `LabelDesigner` e reexporta
  `flutter_label_printer`, mantendo "uma dependência" para o perfil (a).

### Dependências entre pacotes

`flutter_label_designer` e `flutter_label_printer_windows` declaram
`flutter_label_printer: ^1.0.0` (o editor não depende do transporte do
Windows; só o app que imprime por ele o declara); o melos faz o link local em desenvolvimento via
`pubspec_overrides.yaml`. Nenhum `path:` nos pubspecs publicáveis.

## Migração

Cada fase termina com `analyze` limpo e testes no mesmo estado de antes.

1. Criar `packages/flutter_label_printer`; mover os 12 pacotes com `git mv`
   para `lib/src/<pasta>/` e os testes para `test/<pasta>/`. Imports
   `package:label_*/...` entre eles viram imports relativos.
2. Converter `packages/flutter_label_designer` no pacote do editor, movendo os
   7 pacotes de UI da mesma forma e trocando dependências internas por
   `flutter_label_printer`.
3. Renomear `packages/label_print_transport_windows` para
   `packages/flutter_label_printer_windows`.
4. Atualizar `apps/label_studio` e `apps/playground` para depender apenas dos
   pacotes novos.
5. Remover as pastas `label_*` vazias; `melos bootstrap`, `analyze`, testes.

### Critério de sucesso

- Mesma contagem de testes passando antes e depois. As 2 falhas
  preexistentes de `label_renderer_raster` (`thresholdToMonochrome` no limite
  de luminância e `downsampleRgba` na borda parcial) continuam como estão.
- `flutter analyze` sem novos problemas nos três pacotes e nos dois apps.
- `apps/label_studio` compila e imprime como antes.
- Nenhum pubspec publicável contém `path:`.

## Fora de escopo (etapas seguintes)

- Transporte TCP (porta 9100).
- Fachada de alto nível `LabelPrinter`.
- Limpeza de opções (parâmetros de calibração, `base:` aninhado), renomear
  `label_core.EdgeInsets`, raster como caminho padrão.
- `onChanged`/`LabelDesignerController` e atalho de miniatura no editor.
- `example/`, `LICENSE`, `CHANGELOG`, `repository`/`topics` nos pubspecs e a
  publicação em si.

## Branch

`feature/package-consolidation`, criada da `develop` depois do merge de
`feature/raster-printer-language` (a consolidação toca todos os arquivos que
aquela feature alterou).
