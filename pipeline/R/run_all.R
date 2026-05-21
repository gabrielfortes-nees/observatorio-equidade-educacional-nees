## run_all.R — Orquestrador do pipeline do Observatório de Equidade Educacional
## ----------------------------------------------------------------------------
## Roda, em ordem, os scripts que constroem todos os dados da plataforma:
## leitores de microdados (raw -> parquet) e geradores das 9 leituras + mapa +
## landing. Cada script é executado em ambiente isolado; uma falha é registrada
## e NÃO interrompe os demais. No fim, imprime um resumo do que passou e falhou.
##
## Modos (1º argumento da linha de comando, ou variável MODO_PIPELINE):
##   agregados  (padrão)  só os geradores — assume os .parquet já processados.
##                        É rápido e é o que se usa ao reescrever uma leitura.
##   tudo                 leitores + geradores — relê os microdados raw.
##   completo             tudo + a peça "medio" (lê CSV raw de ~1.1 GB).
##
## Uso:
##   Rscript run_all.R                 # modo agregados
##   Rscript run_all.R tudo            # releitura completa dos microdados
##   Rscript run_all.R completo        # inclui a peça "medio"
## Interativo:
##   MODO_PIPELINE <- "tudo"; source(".../pipeline/R/run_all.R")

t0    <- Sys.time()
DIR_R <- "/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R"

args <- commandArgs(trailingOnly = TRUE)
modo <- if (exists("MODO_PIPELINE")) {
  MODO_PIPELINE
} else if (length(args) > 0) {
  args[1]
} else {
  "agregados"
}

## ---------- Definição das etapas ----------
## Leitores: microdados raw -> data/processed/*.parquet
leitores <- c(
  "01_ler_saeb_2023.R",          # SAEB 2023 — aluno 5º EF, 9º EF, 3º EM
  "02_ler_censo_escolar_2025.R", # Censo Escolar 2025 — escola e matrícula
  "03_ler_censo_superior_2024.R",# Censo da Educação Superior 2024
  "04_ler_bolsa_familia.R",      # Bolsa Família — folha de pagamento
  "05_ler_sidra.R"               # SIDRA/IBGE — população 0-3 anos
)
## Geradores: data/processed -> data/agregados/*.json (consumidos pelo site)
geradores <- c(
  "10_gerar_L1.R",          # L1 — a média do SAEB esconde o gap racial
  "11_gerar_L2.R",          # L2 — o gap racial dentro da mesma escola
  "12_gerar_L3.R",          # L3 — decomposição do gap (E se...)
  "13_gerar_L4.R",          # L4 — a creche que não chegou e o eco no 5º ano
  "14_gerar_L5.R",          # L5 — a sala multisseriada
  "15_gerar_L6.R",          # L6 — o transporte escolar (E se...)
  "16_gerar_L7.R",          # L7 — reprovação, abandono e raça
  "17_gerar_L8.R",          # L8 — o funil racial da trajetória
  "18_gerar_L9.R",          # L9 — a Lei de Cotas (E se...)
  "20_gerar_mapa.R",        # mapa nacional
  "21_gerar_landing_demo.R" # dados da landing /interseccionalidade/
)
## Peça "medio": lê um CSV raw pesado (~1.1 GB); roda só no modo completo.
medio <- c("15_medio_dados.R")

etapas <- switch(modo,
  "agregados" = geradores,
  "tudo"      = c(leitores, geradores),
  "completo"  = c(leitores, geradores, medio),
  stop(sprintf("Modo desconhecido: '%s'. Use agregados | tudo | completo.", modo))
)

## ---------- Execução ----------
cat(sprintf("\n=== Pipeline OEE · modo: %s · %d scripts ===\n\n", modo, length(etapas)))
resultados <- data.frame(
  ordem    = seq_along(etapas),
  script   = etapas,
  status   = NA_character_,
  segundos = NA_real_,
  stringsAsFactors = FALSE
)

for (i in seq_along(etapas)) {
  script  <- etapas[i]
  caminho <- file.path(DIR_R, script)
  cat(sprintf("[%d/%d] %s ... ", i, length(etapas), script))
  ti <- Sys.time()
  ok <- tryCatch({
    if (!file.exists(caminho)) stop("script não encontrado")
    source(caminho, local = new.env())
    TRUE
  }, error = function(e) {
    cat(sprintf("\n   ERRO: %s\n", conditionMessage(e)))
    FALSE
  })
  dt <- as.numeric(difftime(Sys.time(), ti, units = "secs"))
  resultados$status[i]   <- if (ok) "OK" else "FALHOU"
  resultados$segundos[i] <- round(dt, 1)
  if (ok) cat(sprintf("OK (%.1fs)\n", dt))
}

## ---------- Resumo ----------
cat("\n=== Resumo ===\n")
print(resultados, row.names = FALSE)
n_ok    <- sum(resultados$status == "OK")
n_falha <- sum(resultados$status == "FALHOU")
cat(sprintf("\n%d OK · %d falhou · tempo total %.1f min\n",
            n_ok, n_falha,
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
if (n_falha > 0) {
  cat("Scripts que falharam: ",
      paste(resultados$script[resultados$status == "FALHOU"], collapse = ", "),
      "\n", sep = "")
  if (!interactive()) quit(status = 1)
}
