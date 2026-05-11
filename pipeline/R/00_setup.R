## Setup — Observatório de Equidade Educacional
## Carrega pacotes, define caminhos e constantes compartilhadas

suppressPackageStartupMessages({
  library(data.table)
  library(arrow)
  library(jsonlite)
})

PROJ     <- "/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional"
DIR_RAW  <- file.path(PROJ, "pipeline/data/raw")
DIR_PROC <- file.path(PROJ, "pipeline/data/processed")
DIR_AGG  <- file.path(PROJ, "pipeline/data/agregados")

dir.create(DIR_PROC, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_AGG,  showWarnings = FALSE, recursive = TRUE)

## ---------- Códigos SAEB 2023 (questionário aluno) ----------
SEXO_LBL   <- c(A = "masculino", B = "feminino", C = "nao_declara")
RACA_LBL   <- c(A = "branca", B = "preta", C = "parda",
                D = "amarela", E = "indigena", F = "nao_declara")
REPROV_LBL <- c(A = "nao", B = "uma_vez", C = "duas_mais")
ABAND_LBL  <- c(A = "nunca", B = "uma_vez", C = "duas_mais")

## Escolaridade dos pais (Q08/Q09)
ESCOL_LBL <- c(
  A = "nunca_estudou", B = "ef_inc",  C = "ef_comp",
  D = "em_inc",        E = "em_comp", F = "sup_inc",
  G = "sup_comp",      H = "pos"
)

## ---------- Pontos de corte "aprendizagem adequada" SAEB ----------
## Cortes OFICIAIS INEP / Todos pela Educação (Anuário Brasileiro da Educação Básica)
## Escala SAEB 0–500
ADEQ_LP_5EF <- 225     # >= 225 = aprendizagem adequada em LP no 5º EF
ADEQ_LP_9EF <- 275     # >= 275 = aprendizagem adequada em LP no 9º EF
ADEQ_LP_3EM <- 325     # >= 325 = aprendizagem adequada em LP no 3º EM

## ---------- Util ----------
cat_step <- function(msg) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))
