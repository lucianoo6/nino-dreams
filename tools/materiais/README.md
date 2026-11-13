# Gerador procedural de materiais PBR

Gera texturas **tileáveis** (sem emenda) e materiais `StandardMaterial3D` prontos para o Godot.
Nada de foto ou IA: só matemática (numpy) — 100% nosso, sem licença de terceiros.

```bash
pip install numpy scipy pillow
python tools/materiais/gerador.py                 # todos, 1024 px (~45 s)
python tools/materiais/gerador.py feltro -r 2048  # um material, 2K
python tools/materiais/gerador.py --previa previa.png
```

Saída: `assets/materiais/<nome>/{albedo,normal,roughness,ao,height}.png` e `materials/pbr/<nome>[_cor].tres`.
Normais na convenção OpenGL (a do Godot). Os materiais usam **triplanar** (servem em planetas sem UV).

| Material | Como é feito | Variantes (.tres) |
|---|---|---|
| `feltro` | milhares de fibras curtas emaranhadas + grumos | verde, rosa, azul, creme, vermelho, roxo |
| `la_trico` | ponto meia: "V" de laçadas inclinadas, fio torcido, penugem | creme, laranja, azul |
| `cotele` | gomos verticais arredondados + pelúcia | marrom, oliva, vinho |
| `jeans` | sarja 3x1 (urdume índigo, trama crua), slub e desbotado | — |
| `chita` | tela 1x1 + estampa floral brasileira | — |
| `ceramica` | esmalte com variação, craquelê fino, pintinhas de ferro; clearcoat | branca, azul, rosa |
| `vidro` | manchas de dedo e micro-riscos na rugosidade; transparência + refração | claro, âmbar |
| `botao_plastico` | plástico marmorizado brilhante | amarelo, vermelho, azul |
| `madeira` | anéis deformados, veios e poros | — |
| `madreperola` | faixas iridescentes | — |

**Cor:** os albedos de tecido/cerâmica/plástico são quase brancos — a cor vem do `albedo_color` da variante.
Para uma cor nova, duplique um `.tres` e troque `albedo_color` (ou adicione em `VARIANTES` no gerador).

**Conferir no Godot:** `tools/debug/VitrineMateriais.tscn` mostra todos em esferas sobre um fundo de chita
(ver `docs/referencias/vitrine_materiais.png`).

Adicionar material novo: escreva uma função com `@material("nome")` que devolve
`dict(albedo=HxWx3, altura=HxW, rough=HxW|float, forca_normal=..)` usando `ruido.py`
(ruído espectral, Voronoi periódico, domain warp, fibras tileáveis).
