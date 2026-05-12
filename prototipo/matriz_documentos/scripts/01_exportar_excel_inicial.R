#!/usr/bin/env Rscript
# ============================================================
# 01_exportar_excel_inicial.R
# Extrai o `DADOS` do HTML original (matriz_analitica_equidade2.html)
# e gera o Excel longo (uma linha por par documento-dimensao) +
# a aba de metadados.
#
# Rode UMA UNICA VEZ para iniciar o fluxo:
#   Rscript 01_exportar_excel_inicial.R
#
# Saida: ../data/matriz_documentos.xlsx
# ============================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(openxlsx)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

args <- commandArgs(trailingOnly = FALSE)
arg_file <- args[grep("--file=", args)]
aqui <- if (length(arg_file) == 1) {
  dirname(normalizePath(sub("--file=", "", arg_file)))
} else {
  getwd()
}

caminho_json <- file.path(aqui, "..", "data", "dados_originais.json")
caminho_saida <- file.path(aqui, "..", "data", "matriz_documentos.xlsx")

dados <- fromJSON(caminho_json, simplifyVector = FALSE)
cat("Lidos", length(dados), "documentos do JSON intermediario.\n")

# ----- Aba 1: metadados (45 linhas) -----------------------
metadados <- data.frame(
  id = vapply(dados, \(d) d$id, integer(1)),
  nome_curto = vapply(dados, \(d) d$nome_curto, character(1)),
  categoria = vapply(dados, \(d) d$categoria, character(1)),
  identificacao_formal = vapply(dados, \(d) d$identificacao_formal, character(1)),
  ano = vapply(dados, \(d) d$ano, character(1)),
  orgao_responsavel = vapply(dados, \(d) d$orgao_responsavel, character(1)),
  nivel_ensino = vapply(dados, \(d) d$nivel_ensino, character(1)),
  dimensao_equidade_principal = vapply(dados, \(d) d$dimensao_equidade_principal, character(1)),
  fonte_oficial = vapply(dados, \(d) d$fonte_oficial, character(1)),
  stringsAsFactors = FALSE
)

# ----- Aba 2: matriz longa (45 x 6 = 270 linhas) ----------
ordem_dim <- c("atendimento", "aprendizagem", "infraestrutura",
               "pessoal_formacao", "territorialidade", "inclusao")
nome_dim <- c("Atendimento", "Aprendizagem", "Infraestrutura",
              "Pessoal / Formacao", "Territorialidade", "Inclusao")
names(nome_dim) <- ordem_dim

linhas <- list()
for (d in dados) {
  for (dim in ordem_dim) {
    atribs <- d$dimensoes[[dim]]
    linhas[[length(linhas) + 1]] <- data.frame(
      id_doc = d$id,
      nome_curto = d$nome_curto,
      dimensao_chave = dim,
      dimensao_nome = nome_dim[[dim]],
      variaveis = atribs$variaveis %||% "nao encontrado",
      quant = atribs$quant %||% "nao encontrado",
      qual = atribs$qual %||% "nao encontrado",
      equidade = atribs$equidade %||% "nao encontrado",
      stringsAsFactors = FALSE
    )
  }
}
matriz_longa <- do.call(rbind, linhas)
cat("Geradas", nrow(matriz_longa), "linhas na matriz longa.\n")

# ----- Aba 3: legenda das categorias ----------------------
legenda <- data.frame(
  chave_categoria = c("marco_constitucional","lei_federal","decreto_federal",
                      "portaria_mec","portaria_inep","resolucao_cne",
                      "instrumento_avaliacao","indicador_educacional",
                      "sistema_informacao","programa_federal","governanca",
                      "marco_internacional","instrumento_monitoramento"),
  rotulo_exibicao = c("Marco Constitucional","Lei Federal","Decreto Federal",
                      "Portaria MEC","Portaria Inep","Resolucao CNE",
                      "Instrumento de Avaliacao","Indicador Educacional",
                      "Sistema de Informacao","Programa Federal","Governanca",
                      "Marco Internacional","Instrumento de Monitoramento"),
  stringsAsFactors = FALSE
)

# ----- Escrever Excel -------------------------------------
wb <- createWorkbook()
addWorksheet(wb, "metadados")
addWorksheet(wb, "matriz_longa")
addWorksheet(wb, "categorias")

writeData(wb, "metadados", metadados)
writeData(wb, "matriz_longa", matriz_longa)
writeData(wb, "categorias", legenda)

# Estilo de cabecalho
estilo_hdr <- createStyle(textDecoration = "bold", fgFill = "#F5EBD7",
                          border = "bottom", borderStyle = "thin")
addStyle(wb, "metadados", estilo_hdr, rows = 1, cols = seq_len(ncol(metadados)))
addStyle(wb, "matriz_longa", estilo_hdr, rows = 1, cols = seq_len(ncol(matriz_longa)))
addStyle(wb, "categorias", estilo_hdr, rows = 1, cols = seq_len(ncol(legenda)))

setColWidths(wb, "metadados", cols = 1:ncol(metadados),
             widths = c(5, 40, 25, 40, 10, 30, 25, 35, 60))
setColWidths(wb, "matriz_longa", cols = 1:ncol(matriz_longa),
             widths = c(6, 40, 18, 22, 50, 50, 50, 50))
setColWidths(wb, "categorias", cols = 1:2, widths = c(28, 32))

saveWorkbook(wb, caminho_saida, overwrite = TRUE)
cat("Excel salvo em:", caminho_saida, "\n")
cat("Abas: metadados (", nrow(metadados), " linhas), matriz_longa (",
    nrow(matriz_longa), " linhas), categorias (", nrow(legenda), " linhas).\n", sep = "")
