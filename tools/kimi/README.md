# Kimi K3 como subagente (servidor próprio na Modal)

Modelo `moonshotai/Kimi-K3` (contexto de 1M tokens, imagens, ferramentas, raciocínio low/high/max) servido na Modal
com API compatível com OpenAI. Usado para **tarefas grandes de texto** que depois são revisadas: rascunho de capítulos,
falas, traduções, revisão de documentos.

```bash
python tools/kimi/kimi.py "pergunta"
python tools/kimi/kimi.py -f pedido.md -e high -m 12000 -o resposta.json
```

- **Chave:** nunca no repositório. Na nuvem do Claude ela é injetada pelo proxy (segredo de rede do ambiente
  "nino-dreams", cabeçalho `Authorization: Bearer`). No seu PC: `export KIMI_API_KEY=...`.
- Usa **streaming** — sem ele o gateway corta respostas longas (~30 s, erro 502).
- O que o Kimi devolve é rascunho: confira títulos/fatos antes de usar (ex.: os capítulos dos livros foram revisados).

Exemplo real: `tools/livros/capitulos_para_tres.py` converteu o JSON de capítulos que o Kimi gerou para
O Mágico de Oz (24), A Rainha da Neve (7) e O Quebra-Nozes (14) em `data/livros/*.tres`.
