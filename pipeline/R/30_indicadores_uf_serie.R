## 30 — Indicadores UF × ano × raça para o mapa do OEE
## Produz: pipeline/data/processed/indicadores_uf_serie.parquet
##
## Esquema (long table):
##   uf · uf_nome · ano · eixo · indicador
##   · ano_avaliado | etapa | disciplina | rede | raca | sexo | localizacao
##   · valor · n · cv · fonte
##
## Eixos / indicadores:
##   desempenho   · pct_adequado_plus       (SAEB, 2017-2023 bienal)
##   permanencia  · taxa_liquida_matricula  (PNADC, 2012-2023)
##   permanencia  · taxa_conclusao          (PNADC, 2012-2023)
##   abandono     · taxa_abandono           (Censo Escolar, 2014-2023)
##   abandono     · distorcao_idade_serie   (Censo Escolar, 2014-2023)
##
## Este script é o ORQUESTRADOR. Cada bloco delega para um módulo dedicado:
##   30a_saeb_adequado_uf.R          (SAEB microdados aluno)
##   30b_pnadc_matricula_conclusao.R (PNADC microdados ou SIDRA)
##   30c_censo_escolar_abandono_tdi.R (Censo Escolar microdados matrícula)
##
## A consolidação une as 5 séries num único parquet long.
suppressMessages({
  library(arrow); library(data.table)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_AGG <- file.path(PROJ, "pipeline/data/agregados")
dir.create(DIR_AGG, showWarnings = FALSE, recursive = TRUE)

uf_sigla <- c("11"="RO","12"="AC","13"="AM","14"="RR","15"="PA","16"="AP","17"="TO",
              "21"="MA","22"="PI","23"="CE","24"="RN","25"="PB","26"="PE","27"="AL","28"="SE","29"="BA",
              "31"="MG","32"="ES","33"="RJ","35"="SP",
              "41"="PR","42"="SC","43"="RS",
              "50"="MS","51"="MT","52"="GO","53"="DF")
uf_nome <- c(RO="Rondônia",AC="Acre",AM="Amazonas",RR="Roraima",PA="Pará",AP="Amapá",TO="Tocantins",
             MA="Maranhão",PI="Piauí",CE="Ceará",RN="Rio Grande do Norte",PB="Paraíba",
             PE="Pernambuco",AL="Alagoas",SE="Sergipe",BA="Bahia",
             MG="Minas Gerais",ES="Espírito Santo",RJ="Rio de Janeiro",SP="São Paulo",
             PR="Paraná",SC="Santa Catarina",RS="Rio Grande do Sul",
             MS="Mato Grosso do Sul",MT="Mato Grosso",GO="Goiás",DF="Distrito Federal")

## ----- esquema canônico das colunas -----
COLS <- c("uf","uf_nome","ano","eixo","indicador",
          "ano_avaliado","etapa","disciplina","rede",
          "raca","sexo","localizacao",
          "valor","n","cv","fonte")

vazia <- function() {
  data.table(
    uf = character(), uf_nome = character(), ano = integer(),
    eixo = character(), indicador = character(),
    ano_avaliado = character(), etapa = character(), disciplina = character(),
    rede = character(),
    raca = character(), sexo = character(), localizacao = character(),
    valor = numeric(), n = integer(), cv = numeric(), fonte = character()
  )
}

## ============================================================
## BLOCO A — SAEB: % Adequado+ por UF × ano × raça × sexo × rede
## ============================================================
## Para SAEB temos 2023 nos microdados locais (saeb_2023_{5ef,9ef,3em}.parquet).
## Para 2017, 2019, 2021 precisamos baixar e processar (TS_ALUNO_*.csv do INEP).
## Este bloco roda 2023 e marca os outros anos como pendentes.

ADEQ_CORTES <- list(
  lp = c("5EF"=225, "9EF"=275, "3EM"=325),
  mt = c("5EF"=225, "9EF"=300, "3EM"=350)
)

calcular_saeb_uf <- function(ano, etapa_codigo, etapa_lbl) {
  arq <- file.path(DIR_PROC, sprintf("saeb_%d_%s.parquet", ano, etapa_codigo))
  if (!file.exists(arq)) return(NULL)
  dt <- as.data.table(read_parquet(arq))
  dt[, uf := uf_sigla[as.character(id_uf)]]
  dt[, raca := fcase(
    tx_resp_q04 == "A", "branca",
    tx_resp_q04 == "B", "preta",
    tx_resp_q04 == "C", "parda",
    tx_resp_q04 == "D", "amarela",
    tx_resp_q04 == "E", "indigena",
    default = NA_character_
  )]
  dt[, sexo := fcase(
    tx_resp_q01 == "A", "masculino",
    tx_resp_q01 == "B", "feminino",
    default = NA_character_
  )]
  dt[, rede := fifelse(in_publica == 1, "publica", "privada")]

  ## montar registros (total + cada quebra) para LP e MT
  out_list <- list()
  for (disc in c("lp","mt")) {
    col <- paste0("proficiencia_", disc, "_saeb")
    corte <- ADEQ_CORTES[[disc]][etapa_lbl]
    dt_d <- dt[!is.na(get(col))]
    dt_d[, adeq := as.integer(get(col) >= corte)]

    ## helper: agrega para um conjunto de quebras
    agreg <- function(by_cols, raca_v="total", sexo_v="total", rede_v="total") {
      g <- dt_d[, .(valor = round(mean(adeq) * 100, 2), n = .N), by = by_cols]
      g[, `:=`(uf_nome = uf_nome[uf], ano = ano,
               eixo = "desempenho", indicador = "pct_adequado_plus",
               ano_avaliado = etapa_lbl, etapa = NA_character_,
               disciplina = toupper(disc), localizacao = "total",
               cv = NA_real_, fonte = "saeb")]
      if (!"raca" %in% by_cols) g[, raca := raca_v]
      if (!"sexo" %in% by_cols) g[, sexo := sexo_v]
      if (!"rede" %in% by_cols) g[, rede := rede_v]
      g[, ..COLS]
    }

    ## total UF
    out_list[[length(out_list)+1]] <- agreg(c("uf"))
    ## UF × raça
    out_list[[length(out_list)+1]] <- agreg(c("uf","raca"))[!is.na(raca)]
    ## UF × sexo
    out_list[[length(out_list)+1]] <- agreg(c("uf","sexo"))[!is.na(sexo)]
    ## UF × rede
    out_list[[length(out_list)+1]] <- agreg(c("uf","rede"))
  }
  rbindlist(out_list, use.names = TRUE)
}

cat("BLOCO A — SAEB\n")
saeb_blocks <- list()
for (ano in c(2017, 2019, 2021, 2023)) {
  for (et in c("5ef","9ef","3em")) {
    et_lbl <- toupper(et)
    out <- calcular_saeb_uf(ano, et, et_lbl)
    if (is.null(out)) {
      cat(sprintf("  [pendente] %d %s — microdados ausentes\n", ano, et_lbl))
    } else {
      cat(sprintf("  [ok]       %d %s — %d linhas\n", ano, et_lbl, nrow(out)))
      saeb_blocks[[length(saeb_blocks)+1]] <- out
    }
  }
}
saeb_dt <- if (length(saeb_blocks) > 0) rbindlist(saeb_blocks, use.names = TRUE) else vazia()

## ============================================================
## BLOCO B — PNADC: Taxa líquida e taxa de conclusão por UF × ano × raça
## ============================================================
## Implementação delega para 30b_pnadc_matricula_conclusao.R (a criar).
## Esse módulo precisa baixar microdados PNADC anuais (uma visita por trimestre/ano)
## e calcular:
##   - taxa_liquida_matricula = % população em idade certa MATRICULADA na etapa correta
##   - taxa_conclusao = % de jovens com idade > limite que concluiu a etapa
## Idades de referência (PNE / IBGE):
##   EI 4-5     · EF_iniciais 6-10  · EF_finais 11-14  · EM 15-17
##   Conclusão EF: 16 anos+   · Conclusão EM: 19 anos+
##
## Alternativa rápida: usar agregados do SIDRA Tab 7137 + Observatório PNE
## (taxa_conclusao_ef e taxa_conclusao_em desagregadas por UF e raça).

cat("\nBLOCO B — PNADC\n")
pnadc_dt <- vazia()
arq_pnadc <- file.path(DIR_AGG, "pnadc_matricula_conclusao_uf.parquet")
if (file.exists(arq_pnadc)) {
  pnadc_dt <- as.data.table(read_parquet(arq_pnadc))
  cat(sprintf("  [ok]       %d linhas\n", nrow(pnadc_dt)))
} else {
  cat("  [pendente] criar 30b_pnadc_matricula_conclusao.R\n")
}

## ============================================================
## BLOCO C — Censo Escolar: Taxa de abandono e TDI por UF × ano × raça
## ============================================================
## Implementação delega para 30c_censo_escolar_abandono_tdi.R (a criar).
## Esse módulo precisa, para cada ano 2014-2023:
##   - ler microdados de matrícula (ou usar variável de SITUACAO no Censo Escolar)
##   - taxa_abandono     = % matriculados com situação "abandono"
##   - distorcao_idade_serie = % com idade > idade_ideal + 1 para a etapa
##
## Filtros: UF × raça × etapa × rede × ano
## Caveat: qualidade do dado de raça melhora a partir de 2014-2015
## (% Não declarado cai para níveis aceitáveis).

cat("\nBLOCO C — Censo Escolar\n")
censo_dt <- vazia()
arq_censo <- file.path(DIR_AGG, "censo_escolar_abandono_tdi_uf.parquet")
if (file.exists(arq_censo)) {
  censo_dt <- as.data.table(read_parquet(arq_censo))
  cat(sprintf("  [ok]       %d linhas\n", nrow(censo_dt)))
} else {
  cat("  [pendente] criar 30c_censo_escolar_abandono_tdi.R\n")
}

## ============================================================
## CONSOLIDAÇÃO — uniao das três fontes no parquet único
## ============================================================
cat("\nCONSOLIDAÇÃO\n")
final <- rbindlist(list(saeb_dt, pnadc_dt, censo_dt), use.names = TRUE, fill = TRUE)
setcolorder(final, COLS)

if (nrow(final) > 0) {
  cat(sprintf("  Total: %s linhas · %d UFs · %d anos · %d indicadores\n",
              format(nrow(final), big.mark="."),
              uniqueN(final$uf), uniqueN(final$ano), uniqueN(final$indicador)))

  ## sanidade: nenhum valor fora de [0, 100]
  bad <- final[valor < 0 | valor > 100]
  if (nrow(bad) > 0) {
    warning(sprintf("⚠ %d linhas com valor fora de [0, 100]", nrow(bad)))
  }

  write_parquet(final, file.path(DIR_PROC, "indicadores_uf_serie.parquet"))
  cat("  → salvo: pipeline/data/processed/indicadores_uf_serie.parquet\n")
} else {
  cat("  ⚠ nenhuma fonte rodou. Rode 30a/30b/30c antes.\n")
}
