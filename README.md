# 🌙 Sonhos

Jogo de plataforma 3D fofo e dinâmico feito em **Godot 4.7 .NET (C#)**.

Um menino sonha com o livro que leu antes de dormir. Cada livro é uma galáxia de **planetinhas de feltro, lã e retalhos**.
Nas noites boas, ele explora e cumpre missões; nas noites de pesadelo, enfrenta o vilão do livro com a **luz em forma de lua** do quarto.
Todos os livros são de **domínio público**.

## Como abrir

1. Instale o **Godot 4.7 – versão .NET** e o **.NET SDK 8** (ou mais novo).
2. Abra o Godot → *Importar* → selecione `project.godot`.
3. Clique em **Build** (ícone de martelo) e depois em **Play** (F5).
   A cena inicial é `scenes/dev/PlanetaTeste.tscn` — um planeta e uma luazinha com gravidade própria, 3 botões-estrela e uma sombra.

> Se o Godot pedir para atualizar o `Sonhos.csproj` (versão do SDK/TargetFramework), pode aceitar.

### Controles do protótipo

WASD mover · Espaço pular · Shift rodopio · Q/E ou mouse girar câmera (clique para capturar) · **F / botão direito: Luz da Lua** · Esc solta o mouse.
Controle de videogame também funciona.

## Estrutura

```
docs/            GDD, direção de arte, lista de livros (domínio público)
scripts/
  Core/          GameState (autoload), BookData (recurso de livro), enums
  Player/        DreamerController — movimento com gravidade de planetinhas
  Camera/        DreamCamera — câmera que se alinha ao "para cima" do jogador
  Dream/         MissionItem — itens de missão / saída
  Nightmare/     MoonLamp (luz da lua), ShadowCreature (sombras/vilões)
shaders/         feltro.gdshader — material base de tecido
materials/       feltro.tres — 1 material, cor por instância (instance uniform `tint`)
scenes/          player/, dream/, nightmare/, dev/
data/livros/     um .tres de BookData por livro
assets/          modelos, texturas, áudio, fontes (via Git LFS)
```

## Documentos

- [GDD — design do jogo](docs/GDD.md)
- [Direção de arte — mundo de tecido](docs/DIRECAO_DE_ARTE.md)
- [Livros em domínio público](docs/LIVROS.md)

## Roadmap (vertical slice)

- [x] Movimento com gravidade esférica, pulo responsivo, rodopio
- [x] Câmera alinhada à gravidade
- [x] Shader de feltro + modo pesadelo
- [x] Luz da Lua + sombras que se dissipam
- [x] Missão "encontrar" / "sair"
- [ ] Quarto (hub) com estante de livros
- [ ] Transições dormir/acordar
- [ ] Carretel-lançador, linhas de gravidade, zíperes
- [ ] Capítulos da Alice + chefe do Quebra-Nozes
- [ ] Texturas de tecido escaneadas, costuras, animação "em dois"
