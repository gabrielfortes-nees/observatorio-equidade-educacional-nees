## 03 — Censo da Educação Superior 2024: cadastro de cursos
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

cat_step("lendo MICRODADOS_CADASTRO_CURSOS_2024.CSV ...")
cursos <- fread(file.path(DIR_RAW, "censo_superior_2024/MICRODADOS_CADASTRO_CURSOS_2024.CSV"),
                select = c("NU_ANO_CENSO", "CO_UF",
                           "TP_CATEGORIA_ADMINISTRATIVA", "TP_ORGANIZACAO_ACADEMICA", "TP_REDE",
                           "QT_ING", "QT_MAT",
                           "QT_ING_BRANCA", "QT_ING_PRETA", "QT_ING_PARDA",
                           "QT_ING_AMARELA", "QT_ING_INDIGENA", "QT_ING_CORND"),
                showProgress = FALSE)
setnames(cursos, tolower(names(cursos)))
write_parquet(cursos, file.path(DIR_PROC, "censo_superior_2024_cursos.parquet"))
cat_step(sprintf("  → %s cursos/locais de oferta", format(nrow(cursos), big.mark = ".")))

cat_step("03 concluído ✓")
