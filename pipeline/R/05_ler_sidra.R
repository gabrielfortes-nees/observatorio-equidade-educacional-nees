## 05 — SIDRA: população 0-3 anos × município (Censo Demográfico 2022, tabela 9514)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

cat_step("lendo pop_0_3_municipios_2022.json ...")
raw <- fromJSON(file.path(DIR_RAW, "censo_demografico_2022/pop_0_3_municipios_2022.json"),
                simplifyVector = TRUE)

## header é a primeira linha; dado começa em [-1, ]
df <- as.data.table(raw[-1, ])
setnames(df, c("nivel_cod","nivel_nome","unid_cod","unid_nome","valor",
               "cod_municipio","municipio_uf","_d2c","_d2n",
               "ano_cod","ano","idade_cod","idade","sexo_cod","sexo",
               "decl_cod","decl"))

df[, pop := as.integer(valor)]
df[is.na(pop), pop := 0]                                      # casos "-" / ".."
df[, .(cod_municipio, municipio_uf, idade, pop)] -> pop

## agregar por município: total 0-3 anos
pop_mun <- pop[, .(pop_0_3 = sum(pop, na.rm = TRUE)), by = .(cod_municipio, municipio_uf)]
write_parquet(pop_mun, file.path(DIR_PROC, "sidra_pop_0_3_municipios_2022.parquet"))
cat_step(sprintf("  → %s municípios | Brasil 0-3 = %s",
                 format(nrow(pop_mun), big.mark = "."),
                 format(sum(pop_mun$pop_0_3), big.mark = ".")))
cat_step("05 concluído ✓")
