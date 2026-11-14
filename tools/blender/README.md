# Blender (via `bpy`)

Scripts que rodam o Blender sem janela (ex.: `pip install bpy` num venv com Python 3.13, ou `blender -b -P`).

- `arte_capa.py` — arte de capa renderizada no **Cycles** com os modelos de verdade do jogo (Nino e Mel de pano
  posados com as animações UAL retargetadas), planetinha de feltro com as texturas do gerador, lua crescente,
  livros e botões flutuando. `python arte_capa.py saida.png 1920 1080 96` (~1,5 min na CPU).
- `titulo_capa.py` — põe o título (Fredoka) e gera os recortes da Steam: cápsula principal 616×353 e
  cabeçalho 460×215. `python titulo_capa.py render.png docs/arte`

Resultado em `docs/arte/`.
