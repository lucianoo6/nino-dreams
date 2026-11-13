# Plataformas

**Alvo:** PC (Windows/Linux/macOS) na **Steam**, com **Steam Deck verificado**, + **Nintendo Switch / Switch 2, PlayStation 5, Xbox Series X|S**.

## Situação do Godot em consoles (verificado em nov/2026)

- O Godot oficialmente só exporta para PC, mobile e web. **Consoles exigem um parceiro de port** (o mais conhecido é a **W4 Games**,
  fundada por membros do núcleo do Godot; também existem Lone Wolf Technology, Pineapple Works etc.) e contas de desenvolvedor
  aprovadas em Nintendo, Sony e Microsoft (dev kits sob NDA).
- ⚠️ **C# em console é o ponto de risco**: segundo a W4 Games, o suporte a C# ainda está em **beta** e cobre **Switch e Xbox**;
  **PlayStation 5 com C# não é oferecido** no momento ("entre em contato").

## Decisão a tomar logo (o projeto ainda é pequeno — mudar agora é barato)

| Opção | Prós | Contras |
|---|---|---|
| **A. Manter C#** e confirmar com W4/outros parceiros o PS5 antes de avançar | Linguagem que você escolheu, ferramentas .NET | PS5 pode atrasar ou ficar de fora |
| **B. Migrar para GDScript** (C++/GDExtension só onde precisar de desempenho) | Funciona em todos os consoles que os parceiros suportam | Reescrever ~10 scripts (poucas horas hoje, caro depois) |

**Recomendação:** mandar mensagem para a W4 Games (e um segundo parceiro) **agora** perguntando sobre C# no PS5 com Godot 4.7.
Se a resposta não for clara, migrar para GDScript antes do vertical slice.

## Orçamento de desempenho (pensando no console mais fraco: Switch)

- Iluminação **assada** (LightmapGI) nas fases; nada de SDFGI no Switch.
- Shell texturing (lã felpuda) só em peças de destaque, com LOD.
- Testar cedo com o renderizador **Mobile** como perfil de Switch.
- Meta: 60 fps no PC/PS5/Xbox, 30–60 fps estáveis no Switch.

## Steam

- Steam Input (controles) e Steam Deck: sem custo extra; o Godot .NET exporta normalmente para Windows/Linux.
- Coop local funciona com **Remote Play Together** (coop online "de graça" para o modo da irmãzinha).
