# Plataformas

**Alvo:** PC (Windows/Linux/macOS) na **Steam**, com **Steam Deck verificado**, + **Nintendo Switch / Switch 2, PlayStation 5, Xbox Series X|S**.

## Situação do Godot em consoles (verificado em nov/2026)

- O Godot oficialmente só exporta para PC, mobile e web. **Consoles exigem um parceiro de port** (o mais conhecido é a **W4 Games**,
  fundada por membros do núcleo do Godot; também existem Lone Wolf Technology, Pineapple Works etc.) e contas de desenvolvedor
  aprovadas em Nintendo, Sony e Microsoft (dev kits sob NDA).
- Segundo a W4 Games, o suporte a C# ainda está em **beta** e cobre só **Switch e Xbox** (PS5 com C# não é oferecido).
  **Por isso o projeto usa GDScript**, que é suportado em todos os consoles pelos parceiros.

## Decisão tomada: GDScript tipado ✅

Migramos de C# para **GDScript com tipos declarados** enquanto o projeto era pequeno.
Se algum trecho ficar pesado no Switch, ele pode ser reescrito em C++ (GDExtension), que também roda em console.

**Próximo passo de negócio:** contatar a W4 Games (e um segundo parceiro) para orçamento de port, e se cadastrar
nos programas de desenvolvedor da Nintendo, Sony e Microsoft (pode levar semanas para aprovar).

## Orçamento de desempenho (pensando no console mais fraco: Switch)

- Iluminação **assada** (LightmapGI) nas fases; nada de SDFGI no Switch.
- Shell texturing (lã felpuda) só em peças de destaque, com LOD.
- Testar cedo com o renderizador **Mobile** como perfil de Switch.
- Meta: 60 fps no PC/PS5/Xbox, 30–60 fps estáveis no Switch.

## Steam

- Steam Input (controles) e Steam Deck: sem custo extra; o Godot exporta normalmente para Windows/Linux/macOS.
- Coop local funciona com **Remote Play Together** (coop online "de graça" para o modo da Mel).
