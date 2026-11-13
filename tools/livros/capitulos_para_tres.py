"""Grava a lista de capítulos (JSON) dentro do BookData (.tres) de um livro, mantendo os campos do livro.

    python tools/livros/capitulos_para_tres.py data/livros/magico_de_oz.tres capitulos.json magico_de_oz

JSON: lista de {numero, titulo, tipo: sonho|pesadelo, missao: encontrar|sair|vilao, itens, sinopse[, cena]}
(o formato que o subagente Kimi devolve — ver tools/kimi/). A última linha do livro vai para o último capítulo.
"""
import json
import re
import sys

TIPO = {"sonho": 0, "pesadelo": 1}
MISSAO = {"encontrar": 0, "sair": 1, "vilao": 2}


def esc(t):
    return t.replace("\\", "\\\\").replace('"', '\\"')


def main(caminho, arquivo_json, chave):
    texto = open(arquivo_json, encoding="utf-8").read()
    dados = json.loads(texto[texto.find("{"):texto.rfind("}") + 1]) if texto.lstrip().startswith("{") else json.loads(texto)
    caps = dados[chave] if isinstance(dados, dict) else dados
    tres = open(caminho, encoding="utf-8").read()
    corpo = tres[tres.index("[resource]"):]
    campos = [l for l in corpo.splitlines()[1:] if l.strip() and not l.startswith("capitulos")]
    ultima = re.search(r'^ultima_linha = "(.*)"$', corpo, re.M)
    saida = [f'[gd_resource type="Resource" script_class="BookData" load_steps={len(caps) + 3} format=3]', "",
             '[ext_resource type="Script" path="res://scripts/core/book_data.gd" id="1_book"]',
             '[ext_resource type="Script" path="res://scripts/core/chapter_data.gd" id="2_cap"]', ""]
    for c in caps:
        n = int(c["numero"])
        saida += [f'[sub_resource type="Resource" id="Cap_{n:02d}"]', 'script = ExtResource("2_cap")', f"numero = {n}",
                  f'titulo = "{esc(c["titulo"])}"', f'sinopse = "{esc(c.get("sinopse", ""))}"']
        if n == len(caps) and ultima:
            saida.append(f'ultima_linha = "{ultima.group(1)}"')
        saida += [f"tipo = {TIPO[c['tipo']]}", f"missao = {MISSAO[c['missao']]}",
                  f"itens_necessarios = {int(c.get('itens', 0))}", f'cena = "{c.get("cena", "")}"', ""]
    refs = ", ".join(f'SubResource("Cap_{int(c["numero"]):02d}")' for c in caps)
    saida += ["[resource]"] + campos + [f'capitulos = Array[ExtResource("2_cap")]([{refs}])', ""]
    open(caminho, "w", encoding="utf-8").write("\n".join(saida))
    print(caminho, len(caps), "capítulos")


if __name__ == "__main__":
    main(*sys.argv[1:4])
