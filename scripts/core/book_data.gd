class_name BookData
extends Resource
## Um livro da estante do quarto. Cada livro é uma "galáxia" de sonhos.
## Só obras em domínio público no mundo inteiro (autor falecido até 1925) — ver docs/LIVROS.md.

## Tipo de noite: sonho bom (exploração/missão) ou pesadelo (enfrentar o vilão com a Luna).
enum DreamKind { SONHO, PESADELO }

## ENCONTRAR: achar N objetos · SAIR: chegar à saída · ENFRENTAR_VILAO: pesadelo com chefe.
enum MissionKind { ENCONTRAR, SAIR, ENFRENTAR_VILAO }

const ANO_LIMITE_DOMINIO_PUBLICO := 1925

@export var id: String = ""
@export var titulo: String = ""
@export var autor: String = ""
@export var ano_publicacao: int = 0
## Ano de morte do autor (0 = tradição oral/anônimo).
@export var ano_morte_autor: int = 0
@export_multiline var sinopse: String = ""
## Última linha da história — o Nino lê (balbuciando) antes do "e FIM".
## Tradução feita pela equipe a partir do original em domínio público.
@export_multiline var ultima_linha: String = ""

@export var tipo: DreamKind = DreamKind.SONHO
@export var missao: MissionKind = MissionKind.ENCONTRAR
## Quantos itens a encontrar (quando missao == ENCONTRAR).
@export var itens_necessarios: int = 3

@export_file("*.tscn") var cena_do_sonho: String = ""
@export var cor_da_capa: Color = Color(0.8, 0.4, 0.4)


func em_dominio_publico_mundial() -> bool:
	return ano_morte_autor <= ANO_LIMITE_DOMINIO_PUBLICO
