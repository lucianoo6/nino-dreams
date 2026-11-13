# Ferramentas na Modal (GPU na nuvem)

Scripts para **produzir arte** com modelos abertos rodando em GPU da [Modal](https://modal.com). O jogo em si não usa a Modal.

## Preparar (uma vez)

```bash
pip install modal
modal token set --token-id <ID> --token-secret <SECRET>
```

## Scripts

| Script | O que faz | Modelo / licença |
|---|---|---|
| `imagem_para_3d.py` | Imagem de referência → `.glb` com textura em `assets/models/gerados/` | TRELLIS (Microsoft) — MIT |

```bash
modal run tools/modal/imagem_para_3d.py --imagem referencias/xicara.png
```

Fluxo sugerido: imagem (ElevenLabs ou foto de feltro de verdade) → `imagem_para_3d.py` → limpar/arredondar no Blender → Godot.
Bom para objetos de cenário (xícaras, cogumelos, carretéis, brinquedos). Personagens (Nino e Mel) continuam modelados à mão.

⚠️ Antes de adotar qualquer modelo novo aqui, confira se a licença permite **uso comercial** no mundo inteiro.
