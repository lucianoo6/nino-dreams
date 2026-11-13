# 🌙 Once Upon a Pillow: Nino & Mel

*Em português: **Era Uma Vez um Sonho***

Jogo de plataforma 3D fofo e dinâmico feito em **Godot 4.7** com **GDScript** (tipado).

Um menino sonha com o livro que leu antes de dormir. Cada livro é uma galáxia de **planetinhas de feltro, lã e retalhos**.
Nas noites boas, ele explora e cumpre missões; nas noites de pesadelo, enfrenta o vilão do livro com a **Luna**, a luz em forma de lua do quarto.
A irmãzinha **Mel** vai junto, toda distraída, com a **Estrelinha**, uma luz quente. No coop, o 2º jogador controla ela.
Todos os livros são de **domínio público no mundo inteiro** (autor falecido até 1925).

Plataformas-alvo: PC/Steam (Steam Deck) e consoles — ver [docs/PLATAFORMAS.md](docs/PLATAFORMAS.md).

## Como abrir

1. Instale o **Godot 4.7** (versão padrão, não precisa da .NET).
2. Abra o Godot → *Importar* → selecione `project.godot`.
3. Aperte **Play** (F5).
   A cena inicial é a **estante** (`scenes/menu/Quarto.tscn`): escolha um livro, o Nino lê a última linha, diz "e FIM" e o sonho começa.
   Os livros ainda sem fase própria abrem a fase de protótipo `scenes/dev/PlanetaTeste.tscn` (planeta + luazinha, 3 botões-estrela,
   uma sombra, a Mel e uma borboleta de feltro).

> Estilo de código: GDScript sempre com tipos declarados. Lint opcional: `pip install "gdtoolkit==4.*"` e `gdlint scripts/` (config em `gdlintrc`).

### Controles do protótipo

**Estante:** mouse (passar = livro pula, clicar = escolher) ou ←/→ e Enter/Espaço/A. Apertar durante a leitura completa a frase.

**Nino (jogador 1):** WASD mover · Espaço pular · Shift rodopio · Q/E ou mouse girar câmera (clique para capturar) ·
**F / botão direito: Luna** · C chamar a Mel · Esc solta o mouse. Controle 1 também funciona.

**Mel (jogador 2, entra a qualquer momento):** IJKL mover · O pular · U rodopio · **P: abraço de luz da Estrelinha** · Backspace sai do coop.
Controle 2 também funciona (Select sai).

## Estrutura

```
docs/            GDD, direção de arte, lista de livros (domínio público)
scripts/
  core/          game_state.gd (autoload GameState), transicao.gd (autoload Transicao: nuvens), book_data.gd
  player/        dreamer_controller.gd (Nino) e mel_controller.gd (Mel: IA distraída / jogador 2)
  camera/        dream_camera.gd — câmera que se alinha ao "para cima" do jogador
  dream/         mission_item.gd — itens de missão / saída
  menu/          quarto_menu.gd (estante, rack focus, leitura, "e FIM"), shelf_book.gd (livro que pula)
  ui/            babble_voice.gd (voz balbuciada sintetizada), babble_dialog.gd (balão + "e FIM")
  nightmare/     moon_lamp.gd (Luna), star_light.gd (Estrelinha), shadow_creature.gd (sombras/vilões)
  world/         distraction.gd (o que distrai a Mel), star_revealable.gd (só aparece na luz da Estrelinha)
shaders/         feltro.gdshader (tecido), nuvens.gdshader (transição)
materials/       feltro.tres — 1 material, cor por instância (instance uniform `tint`)
scenes/          menu/ (Quarto), player/ (Sonhador, NinoVisual, Mel), dream/, nightmare/, dev/
data/livros/     um .tres de BookData por livro
assets/          modelos, texturas, áudio, fontes (via Git LFS)
```

## Documentos

- [GDD — design do jogo](docs/GDD.md)
- [Direção de arte — mundo de tecido](docs/DIRECAO_DE_ARTE.md)
- [Livros em domínio público](docs/LIVROS.md)
- [Plataformas e consoles](docs/PLATAFORMAS.md)

## Roadmap (vertical slice)

- [x] Movimento com gravidade esférica, pulo responsivo, rodopio
- [x] Câmera alinhada à gravidade
- [x] Shader de feltro + modo pesadelo
- [x] Luz da Lua + sombras que se dissipam
- [x] Missão "encontrar" / "sair"
- [x] Mel: IA distraída + coop drop-in + Estrelinha (zona segura, recarga, revelar, combo)
- [x] Migração para GDScript (todos os consoles, incluindo PS5)
- [ ] Zonas de câmera guiada + interface dentro do mundo
- [x] Estante: livros que pulam, rack focus, leitura balbuciada da última linha, "e FIM"
- [x] Transição de nuvens: dormir → câmera desce das nuvens → acordar de volta na estante
- [ ] Quarto explorável (hub) além da estante
- [ ] Carretel-lançador, linhas de gravidade, zíperes
- [ ] Capítulos da Alice + chefe do Quebra-Nozes
- [ ] Texturas de tecido escaneadas, costuras, animação "em dois"
