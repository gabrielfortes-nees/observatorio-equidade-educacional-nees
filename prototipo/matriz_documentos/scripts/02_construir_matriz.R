#!/usr/bin/env Rscript
# ============================================================
# 02_construir_matriz.R
# Le o Excel (matriz_documentos.xlsx) e regenera o HTML
# (index.html), injetando o array DADOS no <script>.
#
# Rode sempre que editar o Excel:
#   Rscript 02_construir_matriz.R
#
# Entrada: ../data/matriz_documentos.xlsx
# Saida:   ../index.html
# ============================================================

suppressPackageStartupMessages({
  library(readxl)
  library(jsonlite)
})

`%||%` <- function(a, b) if (!is.null(a) && !is.na(a) && nzchar(a)) a else b

args <- commandArgs(trailingOnly = FALSE)
arg_file <- args[grep("--file=", args)]
aqui <- if (length(arg_file) == 1) {
  dirname(normalizePath(sub("--file=", "", arg_file)))
} else {
  getwd()
}

caminho_xlsx <- file.path(aqui, "..", "data", "matriz_documentos.xlsx")
caminho_template <- file.path(aqui, "..", "template.html")
caminho_saida <- file.path(aqui, "..", "index.html")

if (!file.exists(caminho_xlsx)) stop("Excel nao encontrado: ", caminho_xlsx)
if (!file.exists(caminho_template)) stop("Template nao encontrado: ", caminho_template)

meta <- as.data.frame(read_excel(caminho_xlsx, sheet = "metadados"))
matriz <- as.data.frame(read_excel(caminho_xlsx, sheet = "matriz_longa"))

cat("Lidos", nrow(meta), "documentos e", nrow(matriz), "linhas de matriz.\n")

ordem_dim <- c("atendimento", "aprendizagem", "infraestrutura",
               "pessoal_formacao", "territorialidade", "inclusao")

# ----- Montar lista de documentos no formato esperado pelo JS ------
dados <- lapply(seq_len(nrow(meta)), function(i) {
  m <- meta[i, ]
  dimensoes <- list()
  for (dim in ordem_dim) {
    sub <- matriz[matriz$id_doc == m$id & matriz$dimensao_chave == dim, ]
    if (nrow(sub) >= 1) {
      dimensoes[[dim]] <- list(
        variaveis = sub$variaveis[1] %||% "nao encontrado",
        quant = sub$quant[1] %||% "nao encontrado",
        qual = sub$qual[1] %||% "nao encontrado",
        equidade = sub$equidade[1] %||% "nao encontrado"
      )
    } else {
      dimensoes[[dim]] <- list(
        variaveis = "nao encontrado", quant = "nao encontrado",
        qual = "nao encontrado", equidade = "nao encontrado"
      )
    }
  }
  list(
    id = m$id,
    nome_curto = m$nome_curto,
    categoria = m$categoria,
    identificacao_formal = m$identificacao_formal,
    ano = as.character(m$ano),
    orgao_responsavel = m$orgao_responsavel,
    nivel_ensino = m$nivel_ensino,
    dimensao_equidade_principal = m$dimensao_equidade_principal,
    fonte_oficial = m$fonte_oficial,
    dimensoes = dimensoes
  )
})

json_str <- toJSON(dados, auto_unbox = TRUE, pretty = FALSE)

# ----- Injetar no template -----------------------------------------
template <- readLines(caminho_template, encoding = "UTF-8", warn = FALSE)
html <- paste(template, collapse = "\n")

marcador <- "/*__DADOS_INJETADOS__*/"
if (!grepl(marcador, html, fixed = TRUE)) {
  stop("Template nao contem marcador '", marcador, "'")
}

injecao <- paste0("const DADOS = ", json_str, ";")
html_final <- sub(marcador, injecao, html, fixed = TRUE)

writeLines(html_final, caminho_saida, useBytes = TRUE)
cat("HTML gerado em:", caminho_saida, "\n")
cat("Tamanho:", round(file.size(caminho_saida) / 1024, 1), "KB\n")
