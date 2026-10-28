---
name: release
description: Fecha o trabalho em andamento e publica uma nova versão neste repositório via git-flow — commita tudo, finaliza a feature na develop, abre e finaliza release/vX.Y.Z (versão nos pubspecs, CHANGELOG, docs), tag e merge em master e develop. Use quando o usuário pedir para "gerar uma versão", "fazer release", "fechar a versão", "commitar tudo e fazer merge" ou "finalizar a feature e versionar".
---

# Release (git-flow) — flutter_label_designer

Fluxo completo do repositório: `feature/*` → `develop` → `release/vX.Y.Z` → `master` + tag → `develop`.
Configuração git-flow do repo: `master`, `develop`, prefixos `feature/`, `release/`, tag sem prefixo de versão (as tags são `vX.Y.Z` porque o nome da release já inclui o `v`). O binário `git flow` **não** está instalado; execute os passos com git puro.

## Regras inegociáveis

- **Nenhuma referência a Claude/IA** em commits, tags ou PRs: sem `Co-Authored-By`, sem "Generated with", sem emoji 🤖. Só o conteúdo da alteração, em português.
- Merges sempre `--no-ff`.
- **Não fazer push** nem apagar branch remota sem o usuário pedir explicitamente; ao final, mostrar os comandos de push.
- Nunca `reset --hard`, `stash` ou checkout que descarte alterações sem antes conferir `git status` e garantir que nada não commitado do usuário se perca.
- Flutter do repo: `.fvm/flutter_sdk/bin/flutter.bat` (não há `flutter` no PATH). Para melos: colocar `.fvm/flutter_sdk/bin` no PATH e usar `dart pub global run melos bootstrap`.

## Passos

### 1. Levantar o estado
- `git status --short`, `git branch --show-current`, `git log --oneline develop..HEAD`, `git tag --sort=-creatordate`.
- Se o usuário pediu "commitar tudo", **tudo** entra (inclusive arquivos que antes ficaram de fora). Senão, perguntar sobre arquivos que não pertencem ao trabalho.

### 2. Documentação
Antes de commitar, conferir se as mudanças da versão estão documentadas:
- `packages/<pacote>/README.md` dos pacotes afetados (uso, opções novas, versão no snippet de `pubspec`).
- READMEs de módulo em `packages/*/lib/src/<módulo>/README.md` quando o comportamento do módulo mudou.
- `docs/ARCHITECTURE.md` e `docs/INTEGRATION.md` se mudou estrutura de pacotes ou forma de consumo.
- `docs/ROADMAP.md` é histórico: não reescrever.

### 3. Validar
Rodar e registrar os resultados (comparar com a versão anterior; falhas preexistentes devem ser citadas, não escondidas):
- `flutter analyze` nos pacotes de `packages/` e nos apps.
- `flutter test` em `packages/flutter_label_printer` e `packages/flutter_label_designer`, e nos testes dos apps. `apps/label_studio/test/library_screen_test.dart` trava na execução: rodar os demais arquivos de teste explicitamente.
- Se houver falha **nova**, parar e reportar antes de versionar.

### 4. Commitar e finalizar a feature
- Na branch `feature/*`: `git add` dos arquivos e um commit por assunto (docs, testes, código), mensagens no padrão `tipo: descrição` (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`).
- `git checkout develop && git merge --no-ff feature/<nome> -m "Merge branch 'feature/<nome>' into develop"` e `git branch -d feature/<nome>`.

### 5. Definir a versão (SemVer)
- Remoção ou mudança incompatível de API pública dos pacotes (`flutter_label_printer`, `flutter_label_designer`, `flutter_label_printer_windows`) → **major**.
- Funcionalidade nova compatível → **minor**. Só correções → **patch**.
- Se a escolha não for óbvia, decidir pelo critério acima e dizer ao usuário qual foi e por quê.

### 6. Release
- `git checkout -b release/vX.Y.Z develop`.
- Atualizar `version:` em `packages/flutter_label_printer/pubspec.yaml`, `packages/flutter_label_designer/pubspec.yaml` e `packages/flutter_label_printer_windows/pubspec.yaml` (versão única para os três) e as restrições entre eles (`flutter_label_printer: ^X.Y.Z`). Apps: `apps/label_studio` usa `X.Y.Z+<build+1>`, `apps/playground` usa `X.Y.Z`.
- Atualizar o snippet de versão nos READMEs dos três pacotes.
- Adicionar a seção `## X.Y.Z` no topo de `CHANGELOG.md` de cada pacote (criar o arquivo se não existir), com as mudanças agrupadas em **Quebras**, **Novidades** e **Correções**, a partir de `git log vANTERIOR..develop`.
- Rodar `melos bootstrap` (mudança de versão pode exigir regenerar overrides) e `flutter analyze` de novo.
- Commit: `chore: versão X.Y.Z`.

### 7. Finalizar a release
```
git checkout master
git merge --no-ff release/vX.Y.Z -m "Merge branch 'release/vX.Y.Z'"
git tag -a vX.Y.Z -m "vX.Y.Z"
git checkout develop
git merge --no-ff vX.Y.Z -m "Merge tag 'vX.Y.Z' into develop"
git branch -d release/vX.Y.Z
```

### 8. Reportar
- Versão gerada e motivo da escolha (major/minor/patch), commits incluídos, resultado de analyze/testes.
- Comandos de push para o usuário rodar quando quiser:
  `git push origin master develop vX.Y.Z` (e `git push origin --delete <branch>` para branches que existiam no remoto).
