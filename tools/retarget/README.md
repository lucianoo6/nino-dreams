# Retarget de animações (Quaternius UAL → Nino/Mel)

Ferramenta usada para passar as animações da **Universal Animation Library 1 e 2** (Quaternius, **CC0**)
para o esqueleto Hyper3D dos personagens. Roda em three.js num Chromium headless (Playwright).

Como funciona (`retarget.js`):
1. Mapa de ossos fonte → alvo (Rigify `DEF-*` e UE `pelvis/spine_01…` → `Hips/Spine/LeftArm…`).
2. A fonte é posta na T-pose (`A_TPose`, quadro 0); o alvo é posto na MESMA pose alinhando a direção
   de braços, mãos, dedos e pernas (coluna/pescoço ficam como estão — cabeça grande de pelúcia).
3. Para cada quadro (30 fps): rotação de mundo do alvo = delta da fonte × pose de referência do alvo;
   o quadril copia o deslocamento da fonte escalado pela altura do quadril.
4. Exporta um .glb só com esqueleto + clipes (`ual_<Nome>`), sem textura.

Uso (com `three@0.170.0` instalado e um servidor estático na pasta dos .glb):
```
node run_retarget.js   # gera nino_anims.glb e mel_anims.glb
node run_check.js      # renderiza poses de conferência
```
No jogo, o `CharacterAnimator` carrega o .glb (`biblioteca_extra`) e reaponta as trilhas para o
Skeleton3D do modelo — nomes ficam `ual/<Nome>` (ex.: `ual/Jump_Start`).
