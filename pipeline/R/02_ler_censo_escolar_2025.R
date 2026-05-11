## 02 — Censo Escolar 2025: Tabela_Escola + Tabela_Matricula (agregados por escola)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

cat_step("lendo Tabela_Escola_2025.csv ...")
escola <- fread(file.path(DIR_RAW, "censo_escolar_2025/Tabela_Escola_2025.csv"),
                select = c("NU_ANO_CENSO", "CO_UF", "SG_UF", "NO_UF", "CO_MUNICIPIO",
                           "CO_ENTIDADE", "TP_DEPENDENCIA", "TP_LOCALIZACAO",
                           "TP_SITUACAO_FUNCIONAMENTO",
                           "IN_AGUA_POTAVEL", "IN_BANHEIRO_PNE", "IN_ALIMENTACAO",
                           "LATITUDE", "LONGITUDE"),
                showProgress = FALSE)
setnames(escola, tolower(names(escola)))
## só escolas em funcionamento
escola <- escola[tp_situacao_funcionamento == 1]
write_parquet(escola, file.path(DIR_PROC, "censo_escolar_2025_escola.parquet"))
cat_step(sprintf("  → %s escolas em funcionamento", format(nrow(escola), big.mark = ".")))

cat_step("lendo Tabela_Matricula_2025.csv ...")
mat <- fread(file.path(DIR_RAW, "censo_escolar_2025/Tabela_Matricula_2025.csv"),
             select = c("NU_ANO_CENSO", "CO_ENTIDADE",
                        "QT_MAT_BAS", "QT_MAT_INF_CRE", "QT_MAT_INF_PRE",
                        "QT_MAT_FUND", "QT_MAT_MED",
                        "QT_MAT_BAS_FEM", "QT_MAT_BAS_MASC",
                        "QT_MAT_BAS_BRANCA", "QT_MAT_BAS_PRETA",
                        "QT_MAT_BAS_PARDA", "QT_MAT_BAS_AMARELA",
                        "QT_MAT_BAS_INDIGENA"),
             showProgress = FALSE)
setnames(mat, tolower(names(mat)))
write_parquet(mat, file.path(DIR_PROC, "censo_escolar_2025_matricula.parquet"))
cat_step(sprintf("  → %s escolas com matrículas", format(nrow(mat), big.mark = ".")))

cat_step("02 concluído ✓")
