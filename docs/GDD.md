# Sonhos — Documento de Design (rascunho v0.1)

> Documento vivo para discussão. Tudo marcado com **❓** é decisão em aberto.

## 1. Premissa

Um menino (nome provisório: **Nino**, de *ninar*) lê um livro antes de dormir. Quando apaga a luz, ele sonha
com aquele livro — mas o mundo do sonho é feito do que tem no quarto dele: **feltro, lã, retalhos, botões,
zíperes, linha de costura, almofadas**. Cada livro vira uma pequena "galáxia" de planetinhas de tecido.

Algumas noites são **sonhos** (explorar, cumprir uma missão). Outras são **pesadelos**: o vilão do livro aparece,
o mundo perde a cor, e Nino enfrenta o vilão com a **luz em formato de lua** do quarto dele.

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

## 4. Sonhos — missões

| Tipo | Exemplo | Status |
|---|---|---|
| **Encontrar** | 3 botões do colete do Coelho Branco | base implementada (`MissionItem`) |
| **Sair** | achar a porta pequenininha / a toca | base implementada (`IsExit`) |
| Corrida | chegar antes do relógio do Coelho | ideia |
| Escoltar | levar o Patinho Feio até o lago | ideia |
| Costurar | juntar retalhos para montar uma ponte | ideia |

Colecionável global: **Estrelas de Botão** (equivalente às estrelas de progresso) que destravam livros novos na estante.

## 5. Pesadelos — a Luz da Lua

- A luz de cabeceira em forma de lua vira a "arma" de Nino: **segurar** acende um **cone de luz**.
- Tem **Brilho** (bateria): gasta acesa, recarrega apagada → ritmo de tensão/alívio. (implementado: `MoonLamp`)
- Sombras de lã escura **desaceleram, encolhem e se desfazem em estrelinhas** sob a luz. (implementado: `ShadowCreature`)
- Ideias para deixar dinâmico:
  - **Lampejo**: soltar toda a carga num flash circular (bom para cercos).
  - **Revelar**: a luz mostra fios brilhantes / plataformas que só existem iluminadas.
  - **Recolorir**: onde a luz bate, o mundo volta a ter cor (`pesadelo` no shader de feltro vai de 1 → 0).
  - **Recargas**: vaga-lumes de lã, estrelas de botão caídas.
- **Chefes**: em fases; o vilão tem pontos fracos que só ficam expostos depois de um padrão de ataque (estilo clássico de plataforma 3D).
  Ex.: Rei dos Camundongos (7 cabeças → 7 pompons a iluminar), Rainha da Neve (espelho de gelo que reflete a luz), Bruxa de João e Maria (casa de doces que anda).

## 6. Controles (protótipo)

| Ação | Teclado/Mouse | Controle |
|---|---|---|
| Mover | WASD / setas | analógico esq. |
| Câmera | Q/E ou mouse (clique p/ capturar) | analógico dir. |
| Pular | Espaço (segurar = mais alto) | A |
| Rodopio (impulso no ar) | Shift | X |
| Luz da Lua | F / botão direito | gatilho direito |
| Interagir | Enter | B |

Sensação: *coyote time*, *jump buffer*, pulo curto ao soltar, rodopio 1× por pulo. **❓** pulo triplo / mergulho / pular na parede?

## 7. Escopo sugerido para o primeiro marco (vertical slice)

1. Quarto (hub) jogável com estante e 2 livros.
2. **Alice** — 2 capítulos de sonho (Encontrar + Sair) com 4–6 planetinhas.
3. **Quebra-Nozes** — 1 pesadelo com chefe (Rei dos Camundongos).
4. Pipeline de arte de tecido validado (ver `DIRECAO_DE_ARTE.md`).
5. Transições "dormir" e "acordar".

## 8. Decisões em aberto (para discutirmos)

- ❓ Nome do menino e da luz (sugestões: **Nino** e **Lulu**/“Dona Lua”).
- ❓ Plataforma-alvo (PC/Steam Deck? Switch 2 exige export console de terceiros).
- ❓ Câmera livre ou semi-guiada por trilhos (como em jogos de planetinhas, que guiam muito a câmera).
- ❓ Coop local (segundo jogador como um bichinho de pelúcia com a lanterna?).
- ❓ Narração: um narrador lendo trechos do livro original nas transições (texto em domínio público = podemos citar!).
