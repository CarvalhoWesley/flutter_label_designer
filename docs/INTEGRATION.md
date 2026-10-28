# Guia de integração

> Ver [ROADMAP.md](./ROADMAP.md), etapa 17, e [ARCHITECTURE.md](./ARCHITECTURE.md), seção 20.

Este workspace não produz um app entregável — ele produz **pacotes Dart/Flutter** que o seu projeto Flutter já existente importa como qualquer outra dependência. Este guia é o passo a passo para isso.

**Status desta etapa**: os passos abaixo foram validados rodando o pipeline completo dentro de `apps/playground` (sandbox interno deste workspace — ver seu README), que hoje consome os pacotes exatamente do mesmo jeito descrito aqui (via `flutter_label_designer`). A validação num projeto Flutter *fora* deste workspace, consumindo via `path:`/`git:` como um cliente real faria, ainda não foi feita — é uma pendência manual para antes de considerar a integração "pronta para produção".

## 1. Adicionar os pacotes ao seu `pubspec.yaml`

### Opção recomendada: `flutter_label_designer`

`flutter_label_designer` é um pacote guarda-chuva que reexporta tudo que um consumidor típico precisa (editor, layout engine, serialização e os renderers prontos) atrás de **uma única dependência** — ver [`packages/flutter_label_designer/README.md`](../packages/flutter_label_designer/README.md) para o que exatamente está incluído.

```yaml
# pubspec.yaml do seu projeto Flutter
dependencies:
  flutter:
    sdk: flutter
  flutter_label_designer:
    path: ../label_designer_workspace/packages/flutter_label_designer
```

```dart
import 'package:flutter_label_designer/flutter_label_designer.dart';
```

Isso já dá acesso a `LabelDesigner`, `LabelDocument`, `LabelLayoutEngine`, `PdfRenderer`, `CanvasRenderer`, `ArgoxRenderer` e `LabelDocumentCodec` — o resto deste guia usa esse único import.

### Opção avançada: só impressão ou spooler do Windows

Se você não precisa do editor visual (por exemplo, um serviço de impressão headless que só precisa de renderers), dependa apenas de `flutter_label_printer` (modelo, layout engine, serialização, renderers PDF/PNG/PPLA e contrato de transporte). Para enviar bytes ao spooler do Windows, adicione também `flutter_label_printer_windows`:

```yaml
dependencies:
  flutter_label_printer:
    path: ../label_designer_workspace/packages/flutter_label_printer
  flutter_label_printer_windows: # opcional, só Windows
    path: ../label_designer_workspace/packages/flutter_label_printer_windows
```

### Em produção

Depois de publicado (pub.dev ou um repositório git seu), troque `path:` por `git:` (ou pela versão do pub.dev) — vale para `flutter_label_designer` ou para qualquer pacote individual:

```yaml
dependencies:
  flutter_label_designer:
    git:
      url: https://github.com/sua-empresa/label_designer_workspace.git
      path: packages/flutter_label_designer
      ref: v0.1.0 # tag/branch/commit — fixe uma versão
```

Rode `flutter pub get` depois de editar.

## 2. Embutir o `LabelDesigner`

`LabelDesigner` é um widget Flutter comum — não gerencia navegação nem faz I/O. Ele recebe um `LabelDocument` e devolve o documento editado via `onSave`; salvar em disco/banco é responsabilidade da sua tela:

```dart
import 'package:flutter/material.dart' hide EdgeInsets; // ver "armadilha conhecida" abaixo
import 'package:flutter_label_designer/flutter_label_designer.dart';

class MinhaTelaDeEdicao extends StatelessWidget {
  const MinhaTelaDeEdicao({super.key, required this.documento});

  final LabelDocument documento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LabelDesigner(
        document: documento,
        onSave: (documentoEditado) {
          // salvar no seu banco/arquivo — fora do escopo deste framework.
          meuRepositorio.salvar(documentoEditado);
        },
      ),
    );
  }
}
```

**Armadilha conhecida**: `EdgeInsets` do modelo (`flutter_label_printer`) (margens em mm) e `flutter/material.dart`'s `EdgeInsets` têm o mesmo nome. Se o seu arquivo importar os dois, esconda um deles como no exemplo acima — é o mesmo workaround que o próprio editor já usa internamente, não é algo novo.

## 3. Resolver e renderizar na hora de exportar/imprimir

`LabelDocument` não sabe nada sobre impressoras ou pixels — o `LabelLayoutEngine` resolve variáveis/expressões/unidades para o DPI alvo, e um renderer (`PdfRenderer`, `ArgoxRenderer`, ...) converte o layout resolvido para bytes de saída. Nenhum renderer recalcula layout; todos recebem o mesmo `ResolvedDocument`.

```dart
import 'package:flutter_label_designer/flutter_label_designer.dart';

const layoutEngine = LabelLayoutEngine();
final resolved = layoutEngine.resolve(documento, {
  'produto': 'Parafuso Sextavado M6',
  'preco': 3.9,
  'codigo': 'PROD-000123',
});

// Exportar como PDF (para conferência visual, e-mail, arquivo):
const pdfRenderer = PdfRenderer();
final pdfBytes = await pdfRenderer.render(resolved, const PdfRendererOptions());

// Ou gerar comandos PPLA para uma impressora Argox:
const argoxRenderer = ArgoxRenderer();
final pplaBytes = await argoxRenderer.render(resolved, const ArgoxRendererOptions(
  darkness: 12,
  copies: 1,
));
```

## 4. Enviar os bytes para a saída física

Este framework entrega bytes já codificados na linguagem de destino — **o transporte é sempre responsabilidade do seu projeto**:

- **PDF**: grave em arquivo (`dart:io`), abra num visualizador, ou envie por e-mail/API.
- **PPLA/Argox**: envie por USB, rede (socket TCP na porta 9100, tipicamente) ou Bluetooth, conforme como sua impressora está conectada. `flutter_label_printer` define o contrato de transporte (`PrintTransport`) e `flutter_label_printer_windows` implementa o envio ao spooler do Windows; para outros meios, implemente o contrato ou escreva o seu.

## 5. O que já foi validado vs. o que falta

| Validado | Como |
|---|---|
| `LabelDesigner` produz um `LabelDocument` editável de ponta a ponta | `apps/playground`, etapas 14 e 17 |
| `LabelDocument` → `LabelLayoutEngine` → `PdfRenderer`/`CanvasRenderer`/`ArgoxRenderer` → bytes, sem exceções, usando só o import de `flutter_label_designer` | `apps/playground` (etapa 17) e `packages/flutter_label_designer/test/` |
| `flutter_label_designer` sozinho (sem nenhum outro import de pacote) é suficiente para tudo isso | `packages/flutter_label_designer/test/flutter_label_designer_test.dart` |
| Os pacotes resolvem corretamente via `path:` dentro deste monorepo (`melos bootstrap`) | Todas as etapas |
| **Pendente**: os pacotes funcionam quando consumidos via `path:`/`git:` a partir de um `pubspec.yaml` genuinamente fora deste workspace (fora do gerenciamento do melos) | Não feito ainda — recomendado antes de depender disso em produção |
| **Pendente**: bytes PPLA validados contra uma impressora Argox real | Ver `packages/flutter_label_printer/lib/src/renderer_argox/README.md` |
