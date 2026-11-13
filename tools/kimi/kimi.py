"""Chama o Kimi K3 (servidor próprio na Modal, API compatível com OpenAI) como subagente.

A chave NÃO fica aqui: no ambiente de nuvem do Claude ela é injetada pelo proxy no cabeçalho
Authorization. Para rodar no seu PC, defina KIMI_API_KEY (nunca faça commit da chave).

    python tools/kimi/kimi.py "pergunta"                 # resposta no terminal
    python tools/kimi/kimi.py -f pedido.md -o saida.md   # pedido de um arquivo, resposta em arquivo
    python tools/kimi/kimi.py -e high "..."              # esforço de raciocínio: low | high | max
"""
import argparse
import json
import os
import sys
import urllib.request

BASE = os.environ.get("KIMI_BASE", "https://lucianoneves2003--ep-kimi-k3-server.us-west.modal.direct")
MODELO = "moonshotai/Kimi-K3"


def perguntar(texto: str, sistema: str = "", esforco: str = "low", max_tokens: int = 4000) -> str:
    msgs = ([{"role": "system", "content": sistema}] if sistema else []) + [{"role": "user", "content": texto}]
    corpo = {"model": MODELO, "messages": msgs, "max_tokens": max_tokens, "stream": True,
             "reasoning": {"effort": esforco}, "temperature": 0.3}
    req = urllib.request.Request(BASE.rstrip("/") + "/v1/chat/completions", data=json.dumps(corpo).encode(),
                                 headers={"Content-Type": "application/json",
                                          "Authorization": "Bearer " + os.environ.get("KIMI_API_KEY", "proxy-injected")})
    # Streaming (SSE): mantém a conexão viva em respostas longas (sem streaming o gateway corta em ~30 s).
    partes = []
    with urllib.request.urlopen(req, timeout=900) as r:
        for linha in r:
            linha = linha.decode("utf-8").strip()
            if not linha.startswith("data:"):
                continue
            conteudo = linha[5:].strip()
            if conteudo == "[DONE]":
                break
            escolhas = json.loads(conteudo).get("choices") or []  # o último pedaço traz só estatísticas
            if not escolhas:
                continue
            delta = escolhas[0].get("delta", {})
            if delta.get("content"):
                partes.append(delta["content"])
    return "".join(partes)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("texto", nargs="?")
    ap.add_argument("-f", "--arquivo")
    ap.add_argument("-s", "--sistema", default="")
    ap.add_argument("-o", "--saida")
    ap.add_argument("-e", "--esforco", default="low", choices=["low", "high", "max"])
    ap.add_argument("-m", "--max-tokens", type=int, default=4000)
    a = ap.parse_args()
    texto = open(a.arquivo, encoding="utf-8").read() if a.arquivo else (a.texto or sys.stdin.read())
    resposta = perguntar(texto, a.sistema, a.esforco, a.max_tokens)
    if a.saida:
        open(a.saida, "w", encoding="utf-8").write(resposta)
    print(resposta)
