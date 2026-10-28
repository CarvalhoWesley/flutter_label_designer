# preview (flutter_label_designer)

Widget de preview ao vivo do editor:

```
LabelDocument --> LabelLayoutEngine --> CanvasRenderer --> Image.memory
```

`LabelPreview` recebe um `LabelDocument` e um `Map<String, dynamic>` de
dados de amostra como valores simples (não conhece `designer_state`
nem MobX — ver `docs/ARCHITECTURE.md`, seção 6: só depende de
`layout_engine` e `renderer_canvas`). Quem observa mudanças em
`DocumentStore` e repassa o `LabelDocument` atual para este widget a cada
rebuild é o composition point do editor (`designer`, etapa 13).

Reage a mudanças em `document`/`data` com debounce (resolve+renderizar é
trabalho assíncrono, não deve rodar a cada rebuild): mudanças rápidas em
sequência coalescem em uma única renderização, e o último PNG válido
continua visível durante uma nova renderização em andamento, evitando
flicker.

Usa exatamente o mesmo `LabelLayoutEngine` e o mesmo `CanvasRenderer` que
`renderer_canvas` usa para exportação PNG/JPEG — o preview nunca
diverge do resultado real de impressão. Nunca importa nenhum
`renderer_argox`/`_zebra`/`_tsc`/`_pdf`.
