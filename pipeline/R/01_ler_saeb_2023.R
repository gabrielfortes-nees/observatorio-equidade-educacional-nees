## 01 — Ler SAEB 2023 microdados aluno (5EF, 9EF, 3EM)
## Lê CSVs grandes (1 GB cada) com data.table::fread + select de colunas relevantes
## Saída: parquet em data/processed/saeb_2023_*.parquet

source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

cols_aluno <- c(
  ## identificadores territoriais e da escola
  "ID_SAEB", "ID_REGIAO", "ID_UF", "ID_MUNICIPIO", "ID_ESCOLA",
  "IN_PUBLICA", "ID_LOCALIZACAO", "ID_SERIE",
  ## socio + proficiência (LP/MT padronizada e na escala SAEB 0-500)
  "INSE_ALUNO",
  "PROFICIENCIA_LP", "PROFICIENCIA_LP_SAEB",
  "PROFICIENCIA_MT", "PROFICIENCIA_MT_SAEB",
  "IN_PREENCHIMENTO_QUESTIONARIO",
  ## questionário aluno — vars usadas nas leituras
  "TX_RESP_Q01",                         # sexo
  "TX_RESP_Q04",                         # raça/cor
  "TX_RESP_Q08", "TX_RESP_Q09",          # escolaridade mãe/pai
  "TX_RESP_Q19", "TX_RESP_Q20",          # reprovação / abandono
  "TX_RESP_Q21a", "TX_RESP_Q21b",
  "TX_RESP_Q21c", "TX_RESP_Q21d", "TX_RESP_Q21e",  # uso do tempo
  paste0("TX_RESP_Q23", letters[1:9])    # clima escolar / pertencimento
)

ler_saeb <- function(arq, etapa) {
  cat_step(sprintf("lendo %s (etapa %s) ...", basename(arq), etapa))
  dt <- fread(arq, select = cols_aluno, na.strings = c("", ".", "*"),
              showProgress = FALSE)
  setnames(dt, tolower(names(dt)))
  dt[, etapa := etapa]
  cat_step(sprintf("  %s — %s linhas, %.1f MB em mem.", etapa,
                   format(nrow(dt), big.mark = "."), object.size(dt)/1e6))
  dt
}

saeb_5ef <- ler_saeb(file.path(DIR_RAW, "saeb_2023/TS_ALUNO_5EF.csv"), "5EF")
write_parquet(saeb_5ef, file.path(DIR_PROC, "saeb_2023_5ef.parquet"))
cat_step("  → saeb_2023_5ef.parquet gravado")

saeb_9ef <- ler_saeb(file.path(DIR_RAW, "saeb_2023/TS_ALUNO_9EF.csv"), "9EF")
write_parquet(saeb_9ef, file.path(DIR_PROC, "saeb_2023_9ef.parquet"))
cat_step("  → saeb_2023_9ef.parquet gravado")

saeb_3em <- ler_saeb(file.path(DIR_RAW, "saeb_2023/TS_ALUNO_34EM.csv"), "3EM")
write_parquet(saeb_3em, file.path(DIR_PROC, "saeb_2023_3em.parquet"))
cat_step("  → saeb_2023_3em.parquet gravado")

cat_step("01 concluído ✓")
