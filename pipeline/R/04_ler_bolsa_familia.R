## 04 — Novo Bolsa Família abr/2025 (folha do Portal da Transparência)
## CSV de 2,2 GB descompactado — lemos via pipe do unzip sem extrair em disco.
## Só interessam UF, código mun. SIAFI e VALOR PARCELA para agregação.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

zip_path <- file.path(DIR_RAW, "bolsa_familia/202504_NovoBolsaFamilia.zip")
csv_in   <- "202504_NovoBolsaFamilia.csv"

cat_step("lendo BF abr/2025 via unzip -p (3 colunas) ...")
bf <- fread(cmd = sprintf("unzip -p '%s' '%s'", zip_path, csv_in),
            select = c(3, 4, 9),                       # UF, CD_MUN_SIAFI, VALOR PARCELA
            col.names = c("uf", "cod_siafi", "valor_str"),
            encoding = "Latin-1",
            showProgress = FALSE)

cat_step(sprintf("  CSV carregado: %s linhas", format(nrow(bf), big.mark = ".")))

## VALOR PARCELA vem com vírgula decimal → converter
bf[, valor := as.numeric(gsub(",", ".", valor_str, fixed = TRUE))]
bf[, valor_str := NULL]

## Agregado nacional
total_benef <- nrow(bf)
total_valor <- bf[, sum(valor, na.rm = TRUE)]
cat_step(sprintf("  TOTAL: %s benefícios | R$ %.2f bilhões",
                 format(total_benef, big.mark = "."), total_valor / 1e9))

## Por UF
bf_uf <- bf[, .(n_beneficios = .N,
                valor_total  = sum(valor, na.rm = TRUE),
                valor_medio  = mean(valor, na.rm = TRUE)),
            by = uf][order(-n_beneficios)]
write_parquet(bf_uf, file.path(DIR_PROC, "bolsa_familia_2025_04_uf.parquet"))
cat_step("  → bolsa_familia_2025_04_uf.parquet")

## Por município (SIAFI)
bf_mun <- bf[, .(n_beneficios = .N,
                 valor_total  = sum(valor, na.rm = TRUE)),
             by = .(uf, cod_siafi)]
write_parquet(bf_mun, file.path(DIR_PROC, "bolsa_familia_2025_04_municipio.parquet"))
cat_step(sprintf("  → bolsa_familia_2025_04_municipio.parquet (%s mun)",
                 format(nrow(bf_mun), big.mark = ".")))

## resumo nacional como JSON enxuto para a L6 puxar direto
bf_summary <- list(
  mes_referencia = "abril/2025",
  total_beneficios = total_benef,
  total_valor_brl = total_valor,
  valor_medio_brl = round(mean(bf$valor, na.rm = TRUE), 2),
  n_municipios = nrow(bf_mun),
  n_ufs = nrow(bf_uf)
)
write_json(bf_summary, file.path(DIR_PROC, "bolsa_familia_2025_04_resumo.json"),
           pretty = TRUE, auto_unbox = TRUE)
cat_step("04 concluído ✓")
