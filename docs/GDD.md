# Once Upon a Pillow: Nino & Mel — Documento de Design (rascunho v0.1)

> Título em português: **Era Uma Vez um Sonho**. Repositório: `nino-dreams`.

> Documento vivo para discussão. Tudo marcado com **❓** é decisão em aberto.

## 1. Premissa

**Nino** lê um livro antes de dormir — às vezes junto com a irmãzinha, **Mel**. Quando apaga a luz, ele sonha
com aquele livro — mas o mundo do sonho é feito do que tem no quarto dele: **feltro, lã, retalhos, botões,
zíperes, linha de costura, almofadas**. Cada livro vira uma pequena "galáxia" de planetinhas de tecido.

Algumas noites são **sonhos** (explorar, cumprir uma missão). Outras são **pesadelos**: o vilão do livro aparece,
o mundo perde a cor, e Nino enfrenta o vilão com a **Luna**, a luz em formato de lua do quarto dele. A Mel vem junto com a **Estrelinha**, uma luz de estrela quente.

**Tom:** fofo, aconchegante, mas com controle **dinâmico** e gostoso (pulo responsivo, rodopio, gravidade de planetinhas).
Os pesadelos dão um friozinho na barriga, nunca terror — o vilão não morre: é **acalmado** pela luz e adormece / vira pelúcia.

## 2. Loop principal

```
Quarto (hub, à noite)
  └─ Estante → escolhe um LIVRO
        └─ Nino lê, a luz apaga, transição "páginas viram tecido"
              └─ Galáxia do livro (mapa com 3–6 capítulos/planetas)
                    ├─ Capítulo de SONHO  → missão (encontrar X / sair)
                    └─ Capítulo de PESADELO → enfrentar o vilão com a Luz da Lua
              └─ Acordar → manhã no quarto: recompensa aparece no quarto
                 (um botão novo na colcha, um bordado na cortina, um brinquedo novo…)
```

O quarto evolui com o progresso — é a "sala de troféus" e o menu ao mesmo tempo.

**❓ Como decidir sonho x pesadelo?** Propostas:
1. **Estruturado (recomendado):** cada livro tem capítulos de sonho e um capítulo-pesadelo final (o chefe = vilão do livro). Fácil de balancear.
2. **Medidor de calma:** ações no quarto antes de dormir (ler um trecho assustador, deixar a luz da lua sem carga) aumentam a chance de pesadelo.
3. **Mistura:** estrutura fixa (1) + "pesadelos surpresa" opcionais que dão recompensas raras.

## 2.0 Capítulos = noites ✅

**Cada sonho é um capítulo do livro, não o livro inteiro.** Nino lê um capítulo por noite, como na vida real:

- O **marcador de página** (fitinha no livro da estante) guarda até onde ele leu — salvo em `user://progresso.cfg`.
- Ao escolher o livro, abre o **sumário**: ✓ lidos (dá para sonhar de novo), 🔖 próximo, 🔒 ainda não, 🌑 pesadelo.
- Antes de dormir ele lê a **última linha do capítulo** e diz **"continua…"**. O **"e FIM"** só no último capítulo.
- **Pesadelos são os capítulos do vilão** (Alice: 8 – Croquet da Rainha; 12 – O Depoimento de Alice, chefe final).
- Livro sem capítulos cadastrados = um capítulo só (compatível com os livros antigos).
- Em build de debug todos os capítulos ficam liberados para teste.

**Alice — 12 capítulos (títulos do original):** 1 Descendo pela Toca do Coelho · 2 A Lagoa de Lágrimas ·
3 Uma Corrida Maluca e uma História Comprida · 4 O Coelho Manda o Pequeno Bill · 5 Conselhos de uma Lagarta ·
6 Porco e Pimenta · **7 Um Chá Maluco (fase pronta)** · 8 O Campo de Croquet da Rainha 🌑 · 9 A História da Tartaruga Falsa ·
10 A Quadrilha da Lagosta · 11 Quem Roubou as Tortas? · 12 O Depoimento de Alice 🌑

**Pendente:** traduzir a última linha de cada capítulo a partir do texto original (Project Gutenberg);
enquanto isso o Nino lê o título do capítulo. Cadastrar os capítulos dos outros livros.

## 2.1 A estante (tela inicial / escolha de fase) — implementado

Cena `scenes/menu/Quarto.tscn` (`quarto_menu.gd`):

1. **Composição:** estante de livros de feltro em primeiro plano, nítida; **Nino na cama ao fundo, desfocado** (profundidade de campo), luz de abajur quente e luar azulado.
2. **Escolher:** passar o mouse/direcional faz o livro **pular** (squash & stretch) e mostra título + autor. Funciona com mouse e controle.
3. **Ao confirmar:** o foco da câmera **passa da estante para o Nino** (rack focus), o livro **voa até as mãos dele**.
4. **Ele lê a última linha da história** — com **voz balbuciada** (sem dublagem!) e o texto aparecendo letra a letra.
5. **"e FIM"** grande, pulando na tela.
6. **Nuvens fofas** cobrem a tela → o sonho começa com a **câmera descendo das nuvens** até o Nino no planeta.

**Truque da voz balbuciada** (`babble_voice.gd`): cada letra vira uma sílaba sintetizada com tom próprio — a mesma frase
sempre soa igual, parece uma língua de verdade, e funciona em qualquer idioma de legenda. Zero custo de dublagem e de localização de áudio.
Depois podemos trocar a síntese por sílabas gravadas de um ator ("ba", "mi", "nu"…) mantendo a mesma interface.
Mel usa a mesma voz com tom mais agudo.

A última linha fica em `BookData.ultima_linha` — **tradução nossa** do original em domínio público.

## 3. Mundos estilo "planetinhas"

- Cada fase é um conjunto de **planetoides de tecido** com **gravidade própria** (já implementado: `Area3D` com *gravity point*; o personagem alinha o "para cima" com a gravidade).
- Formas: esferas de feltro (novelos!), almofadas cúbicas, carretéis cilíndricos, cachecóis-fita, chapéus, xícaras (Alice), bules.
- **Elementos de travessia temáticos:**
  - **Carretel-lançador** — catapulta entre planetas (puxa a linha e solta).
  - **Linha de costura** — trilhos de gravidade para caminhar por fora/por baixo.
  - **Zíper** — puxar abre passagens dentro dos planetas.
  - **Almofada-trampolim**, **botão-mola**, **meia-túnel**.
  - **Agulha-gancho** (talvez) — enganchar em ilhoses para balançar.
  - **Retalho solto** — plataforma que cai se você ficar muito tempo.

## 3.1 Alice — Capítulo 7: "Um Chá Maluco" — fatia vertical (padrão de qualidade)

Alvo visual: `docs/referencias/conceitos/cap07_a.png` (arte conceitual gerada). Estado atual:
`docs/referencias/cap07_jogo_*.png`, `cap07_bule.png`, `cap07_relogio.png`.

- Céu de entardecer lilás/pêssego, sol baixo dourado, névoa volumétrica leve, desfoque tilt-shift de longe.
- Mar de nuvens de algodão embaixo, nuvens soltas e xícaras flutuantes com arvorezinhas (decoração).
- Jardim de feltro com costura em ponto cruz, florzinhas, botões meio enterrados, cogumelos com bolinhas.
- Bule-casinha de porcelana pintada (flores azuis), com porta, janelas acesas e vapor de tule.
- Trilha de cartas de papel até um relógio de bolso dourado (substituiu a 3ª carta).
- Som: trilha de caixinha de música em valsa (loop), passinhos no feltro, "puf" de pouso; efeitos de fiapos
  ao pousar e estrelinhas ao pegar botão.
- Peças procedurais reutilizáveis: `PropProcedural` (bule, xícara, relógio, nuvem, flor, botão) e `CosturaPlaneta`.
- Relevo e caminhos: morrinhos de feltro, cerquinhas, trilha de botões até o carretel.
- Linhas dos carretéis esticadas até o destino (`FioEsticado`); postes com varal de luzinhas na trilha de cartas;
  letras nos cantos das cartas.
- **Personagens do livro** (Hyper3D, com esqueleto e animações): **Coelho Branco** no relógio, batendo no pulso
  ("Ai, ai! Vou chegar atrasado!" / dica: "Alguém viu os botões do meu colete?") e **Chapeleiro** na porta do bule
  ("Não tem lugar!" / "Por que um corvo se parece com uma escrivaninha?"). Viram para o Nino e falam em balbucio
  (`Personagem`), com frases do texto original traduzidas pela equipe.

### (histórico) greybox

`scenes/livros/alice/Cap07_ChaMaluco.tscn` — missão ENCONTRAR 3 botões do colete do Coelho.

1. **Jardim de Retalhos** (planeta r=8): início; cogumelos-plataforma; botão A escondido embaixo do planeta;
   borboleta de feltro para a Mel se distrair. **Carretel 1** lança para o Bule.
2. **Bule do Chá Maluco** (planeta achatado com tampa, bico e alça): botão B na parte de baixo;
   xicrinha que distrai a Mel. **Carretel 2** lança para a trilha de cartas.
3. **Trilha de Cartas** (gravidade para baixo + zona de câmera que mostra o caminho): o vão entre a 2ª e a 3ª carta
   só se atravessa pela **ponte de fio dourado que a Estrelinha da Mel revela**, segmento por segmento —
   a Mel precisa estar junto (placa: "Chame a Mel"). Botão C no fim da última carta.

Cair no vazio leva de volta ao último chão seguro. Pegar os 3 botões → nuvens → volta para a estante.

**Como montar fases:** `Planetoid` (raio, cor, gravidade, achatamento — atualiza no editor) e `AncoraPlaneta`
(escolha planeta + direção e o objeto fica em pé na superfície). A gravidade padrão do projeto é **zero**:
só há gravidade dentro de planetas e áreas.

## 4. Sonhos — missões

| Tipo | Exemplo | Status |
|---|---|---|
| **Encontrar** | 3 botões do colete do Coelho Branco | base implementada (`mission_item.gd`) |
| **Sair** | achar a porta pequenininha / a toca | base implementada (`IsExit`) |
| Corrida | chegar antes do relógio do Coelho | ideia |
| Escoltar | levar o Patinho Feio até o lago | ideia |
| Costurar | juntar retalhos para montar uma ponte | ideia |

Colecionável global: **Estrelas de Botão** (equivalente às estrelas de progresso) que destravam livros novos na estante.

## 5. Pesadelos — Luna

- **Luna**, a luz de cabeceira em forma de lua, vira a "arma" de Nino: **segurar** acende um **cone de luz**.
- Tem **Brilho** (bateria): gasta acesa, recarrega apagada → ritmo de tensão/alívio. (implementado: `moon_lamp.gd`)
- Sombras de lã escura **desaceleram, encolhem e se desfazem em estrelinhas** sob a luz. (implementado: `shadow_creature.gd`)
- Ideias para deixar dinâmico:
  - **Lampejo**: soltar toda a carga num flash circular (bom para cercos).
  - **Revelar**: a luz mostra fios brilhantes / plataformas que só existem iluminadas.
  - **Recolorir**: onde a luz bate, o mundo volta a ter cor (`pesadelo` no shader de feltro vai de 1 → 0).
  - **Recargas**: vaga-lumes de lã, estrelas de botão caídas.
- **Chefes**: em fases; o vilão tem pontos fracos que só ficam expostos depois de um padrão de ataque (estilo clássico de plataforma 3D).
  Ex.: Rei dos Camundongos (7 cabeças → 7 pompons a iluminar), Rainha da Neve (espelho de gelo que reflete a luz), Bruxa de João e Maria (casa de doces que anda).

## 6. Mel e a Estrelinha

**Mel** — **personalidade:** menor, curiosa e **toda distraída**. Para para brincar com o cenário, fica para trás olhando uma borboleta de feltro,
pula numa poça de lantejoulas… É o charme dela e uma mecânica.

**Sozinho (IA)** — implementado em `mel_controller.gd` + `distraction.gd`:
- Segue o Nino e **pula junto quando ele pula** (imitando o irmão).
- De tempos em tempos procura uma **Distração** por perto e vai brincar (3–6 s).
- Volta sozinha se o Nino se afastar muito, ou quando ele **chama** (C / Y).
- **Distração que ajuda:** algumas distrações revelam segredos (um botão-estrela escondido atrás da borboleta…).
- **Nunca frustra:** não morre, não trava a fase; se ficar longe demais, aparece de novo do lado do Nino.

**Coop (drop-in/drop-out)** — o jogador 2 aperta pular ou luz e assume a irmã; sai com Select/Backspace e ela volta para a IA.

**Estrelinha — a luz quente dela** (implementada em `star_light.gd` + `star_revealable.gd`), complementar à Luna:

| | Luna (Nino) | Estrelinha (irmã) |
|---|---|---|
| Cor | fria, prateada | quente, dourada |
| Formato | cone, direcional | aura redonda ao redor dela |
| Pesadelo | dissipa sombras | **zona segura** (sombras são empurradas para fora) + **recarrega a Luna** mais rápido |
| Sonho | — | **revela** coisas escondidas: fios-ponte, plataformas de tule, botões secretos |
| Especial | — | "Abraço de luz": aura cresce por alguns segundos |
| **Combo** | **Luz de amanhecer**: as duas luzes na mesma sombra = dano ×2,5 | |

No modo solo a IA usa o "abraço de luz" sozinha quando uma sombra chega perto.

## 7. Câmera e imersão

Recomendação: **câmera livre com zonas guiadas.**
- Nos planetas abertos o jogador gira a câmera livremente (já implementado).
- Em trechos difíceis (por baixo de planetas, corredores, chefes) entram **zonas de câmera** feitas à mão que guiam suavemente o ângulo — é o que mantém a vertigem gostosa de andar de cabeça para baixo sem o jogador se perder.
- **Interface quase toda dentro do mundo** (sem HUD poluído): a carga da Luna aparece como as **fases da lua** na própria luz; o brilho da Estrelinha pulsa quando o abraço está pronto; os botões-estrela coletados ficam costurados na capa do Nino.
- **Transições sem tela de carregamento**: livro abre → páginas viram tecido → câmera "cai" no primeiro planeta.
- **Som**: tudo abafado e macio (passos em feltro, "plim" de botão), trilha de caixinha de música que fica distorcida nos pesadelos.
- **Vibração do controle** suave: ronronar quando a Luna acende, batidinha de coração no pesadelo.

## 8. Controles (protótipo)

| Ação | Teclado/Mouse | Controle |
|---|---|---|
| Mover | WASD / setas | analógico esq. |
| Câmera | Q/E ou mouse (clique p/ capturar) | analógico dir. |
| Pular | Espaço (segurar = mais alto) | A |
| Rodopio (impulso no ar) | Shift | X |
| Luna (luz da lua) | F / botão direito | gatilho direito |
| Chamar a irmã | C | Y |
| Interagir | Enter | B |

Sensação: *coyote time*, *jump buffer*, pulo curto ao soltar, rodopio 1× por pulo. **❓** pulo triplo / mergulho / pular na parede?

## 9. Escopo sugerido para o primeiro marco (vertical slice)

1. Quarto (hub) jogável com estante e 2 livros.
2. **Alice** — 2 capítulos de sonho (Encontrar + Sair) com 4–6 planetinhas.
3. **Quebra-Nozes** — 1 pesadelo com chefe (Rei dos Camundongos).
4. Pipeline de arte de tecido validado (ver `DIRECAO_DE_ARTE.md`).
5. Transições "dormir" e "acordar".

## 10. Decisões em aberto (para discutirmos)

- ✅ Título: **Once Upon a Pillow: Nino & Mel** (PT-BR: **Era Uma Vez um Sonho**).
- ✅ Nomes: **Nino** com a luz **Luna**, e a irmãzinha **Mel** com a **Estrelinha**.
- ✅ Plataformas: **PC/Steam (Steam Deck) + todos os consoles** — ver `PLATAFORMAS.md`.
- ✅ Linguagem: **GDScript tipado** (C# não roda em PS5 pelos parceiros de port).
- ✅ Câmera: livre com zonas guiadas, interface dentro do mundo.
- ✅ Coop local: o 2º jogador controla a Mel (drop-in).
- ❓ Narração: um narrador lendo trechos do livro original nas transições (texto em domínio público = podemos citar!).
