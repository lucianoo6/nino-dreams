# Direção de Arte — um mundo de tecido

Objetivo: parecer um **brinquedo artesanal fotografado de perto** — feltro, lã, retalhos, costuras, botões — com
luz suave de abajur. Fofo de dia (sonho), frio e descolorido nos pesadelos.

## Os 5 pilares que vendem "tecido"

1. **Silhueta inflada** — nada de quina viva. Tudo parece almofada recheada (bevel grande, formas "infladas").
   No Blender: *Cloth sim* com *pressure* ou modificador *Displace* suave; ou modelar *subdivision* baixo e deixar arredondar.
2. **Superfície fosca com penugem** — roughness 1.0, quase sem especular, e um **brilho de borda** (a "fuzz" que tecido tem contra a luz).
   Já está no shader `shaders/feltro.gdshader` (RIM + BACKLIGHT + ruído de fibra triplanar).
3. **Costuras** — a coisa que mais diz "feito à mão". Pontos de linha nas bordas e junções:
   - *Trim sheet* de costuras (uma textura com várias tiras de pontos) aplicada em faixas de UV nas bordas; ou
   - *Decals* (`Decal` do Godot) para remendos e pespontos em cima do terreno;
   - No Blender, *Geometry Nodes* espalhando instâncias de "ponto" ao longo das arestas marcadas (fica 3D de verdade, lindo de perto).
4. **Materiais variados** — não é tudo feltro. Contraste é o que deixa bonito:
   feltro (chão, personagens), **lã tricotada** (montanhas, cachecóis), **veludo** (cortinas, coelho), **brim/jeans** (pesado, pesadelos),
   **chita/estampado** (Brasil! ótimo para padrões de flores), **tule** (nuvens, névoa), **botões de plástico/madeira** (os únicos brilhantes).
5. **Luz de miniatura** — luz quente e suave, sombras macias, **profundidade de campo leve** (efeito tilt-shift) para parecer pequeno,
   SSAO forte nos vincos, um pouco de *glow*.

## Pipeline proposto (recomendação)

**Híbrido: texturas reais escaneadas + shader procedural.**

| Parte | Como | Por quê |
|---|---|---|
| Texturas de tecido | Fotografar retalhos reais (feltro, lã, jeans, chita) com o celular, luz difusa → tornar *seamless* e gerar normal/roughness (Materialize, ArmorLab, Substance Sampler) | É o que dá autenticidade; barato e 100% nosso (sem licença) |
| Terreno dos planetas | Shader triplanar (como o `feltro.gdshader`) usando essas texturas | Planetas esféricos não precisam de UV bonita |
| Personagens/props | Modelos low/mid-poly arredondados, UV simples, textura escaneada + costuras via trim sheet | Leve e fácil de iterar |
| Lã felpuda / grama de lã | *Shell texturing* (várias cascas com alpha de fibras) só em peças de destaque | Penugem 3D real, mas custa — usar com moderação |
| Fios e linhas | `Path3D` + malha tubular com textura torcida | Linhas de gravidade, varais, teias |
| Animação | Personagens animados **"em dois"** (12 fps, tipo stop-motion) com *squash & stretch* | Charme de stop-motion; esconde animação simples |
| Iluminação | `LightmapGI` assado para fases estáticas + céu ambiente; `SDFGI` só no quarto, se couber | Luz macia sem custo em tempo real |
| Pós | Tonemap AgX, SSAO, glow, DOF leve, vinheta | "Fotografia de maquete" |

## Sonho x Pesadelo (mesmo mundo, dois humores)

| | Sonho | Pesadelo |
|---|---|---|
| Paleta | pastel quente, chita florida | roxos/azuis dessaturados, jeans e lã escura |
| Tecido | macio, novo, costuras certinhas | **desfiando**, fios soltos, remendos rasgados, botões faltando |
| Luz | sol de abajur, céu de tule | só a Luz da Lua e brilhos frios |
| Mecânica visual | — | a luz **recosturar/recolorir** o mundo (`pesadelo` 1 → 0 no shader) |

## Paleta por livro (exemplos)

- **Alice**: azul-claro, branco, vermelho de baralho, xadrez preto e branco (feltro + cartolina).
- **Oz**: verde-esmeralda, amarelo-tijolo (tricô), sapatos de **prata** (como no livro!).
- **Quebra-Nozes**: vermelho, dourado, verde-pinheiro — veludo e lã natalina.
- **Rainha da Neve**: tule branco, feltro azul-gelo, lantejoulas.

## Referências de *mood* (inspiração, não cópia)

Jogos de "mundo de lã" e de artesanato, animação stop-motion com bonecos de feltro, livros de pano infantis, amigurumi,
bordado livre, colchas de patchwork brasileiras. **Não usar nenhuma arte/personagem de terceiros** — só como referência de sensação.

## Personagens (feito)

Nino e Mel foram gerados no **Hyper3D Rodin Gen-2.5** a partir das folhas de referência (frente + costas, em T-pose),
com malha em quads (~20k), textura PBR 2K e **esqueleto humano de 52 ossos com animações do catálogo Rodin**.
Arquivos: `assets/models/personagens/{nino,mel}.glb`. Prévias das animações: `docs/referencias/*_animacoes.png`.
A agulha de feltrar que aparecia na referência de costas do Nino foi removida da malha.
O `CharacterAnimator` escolhe a animação pelo movimento (e troca para "triste" e "ponta dos pés" nos pesadelos).

## Próximos passos de arte

1. Fotografar 6 tecidos-base e gerar materiais PBR.
2. *Greybox* de 1 planeta da Alice + 1 personagem com costuras.
3. Comparar lado a lado: shader procedural puro × textura escaneada → decidirmos o padrão.
4. Definir o *style guide* de proporção do Nino (cabeça grande, olhos de botão?).
