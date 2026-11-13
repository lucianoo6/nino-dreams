# Testes automáticos com o Godot (sem janela)

- `TesteAnim.tscn`: carrega o Cap. 7, simula andar/pular/acender a Luna e imprime a animação a cada 0,2 s.
  Com `SHOTS=/pasta` (e um display, ex. `xvfb-run`) salva prints de frente e de lado do Nino.
- `FotoCena.tscn`: abre `CENA=res://...` e salva um print depois de `ESPERA` segundos.

```bash
godot --headless --path . res://tools/debug/TesteAnim.tscn
SHOTS=/tmp/fotos xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/debug/TesteAnim.tscn
CENA=res://scenes/menu/Quarto.tscn SHOTS=/tmp/fotos xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/debug/FotoCena.tscn
```
