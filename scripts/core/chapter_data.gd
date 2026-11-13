class_name ChapterData
extends Resource
## Um capítulo de um livro = uma noite de sonho (ou pesadelo).
## Nino lê o capítulo antes de dormir, sonha com ele e, no fim, diz "continua…" — ou "e FIM" no último.

@export var numero: int = 1
@export var titulo: String = ""
@export_multiline var sinopse: String = ""
## Última linha do capítulo, lida em balbucio antes de dormir. Tradução nossa do original (domínio público).
## Vazio = o Nino lê o título do capítulo.
@export_multiline var ultima_linha: String = ""

@export var tipo: BookData.DreamKind = BookData.DreamKind.SONHO
@export var missao: BookData.MissionKind = BookData.MissionKind.ENCONTRAR
@export var itens_necessarios: int = 3
## Vazio = fase de protótipo (enquanto a fase do capítulo não existe).
@export_file("*.tscn") var cena: String = ""


## Este capítulo já tem fase própria? (os outros aparecem como "em breve")
func tem_fase() -> bool:
	return not cena.is_empty()


func rotulo() -> String:
	return "Capítulo %d — %s" % [numero, titulo]
