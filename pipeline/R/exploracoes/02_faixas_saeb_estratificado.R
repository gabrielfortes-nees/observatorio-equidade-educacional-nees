## Exploração — estudantes por faixa de proficiência Saeb 2023
## Estratificações: rede, raça/cor, sexo, região (cada uma em uma tabela)
## + cruzamento raça × sexo × região (tabela única)
## Universo: todas as redes (sem filtro de in_publica)
## Disciplinas: LP e MT · Etapas: 5º EF, 9º EF, 3º EM · 4 faixas TPE.
source(here::here("pipeline/R/00_setup.R"))

cortes <- list(
  lp = list("5ef" = c(150, 225, 300),
            "9ef" = c(200, 275, 325),
            "3em" = c(250, 325, 375)),
  mt = list("5ef" = c(175, 225, 275),
            "9ef" = c(225, 300, 350),
            "3em" = c(250, 350, 400))
)
niveis <- c("Insuficiente", "Básico", "Adequado", "Avançado")
classificar <- function(prof, cuts) {
  suppressWarnings(cut(prof, breaks = c(-Inf, cuts[1], cuts[2], cuts[3], Inf),
                       labels = niveis, right = FALSE))
}

## ---------- rótulos ----------
## região a partir do id_uf (IBGE): 11-17 Norte, 21-29 Nordeste,
## 31-35 Sudeste, 41-43 Sul, 50-53 Centro-Oeste
regiao_de <- function(id_uf) {
  g <- as.integer(id_uf) %/% 10
  fcase(g == 1, "Norte",
        g == 2, "Nordeste",
        g == 3, "Sudeste",
        g == 4, "Sul",
        g == 5, "Centro-Oeste")
}
## SAEB 2023 microdados aluno só carrega público × privado (IN_PUBLICA);
## a quebra federal/estadual/municipal não vem no microdado e a ID_ESCOLA
## do SAEB não casa com a CO_ENTIDADE do Censo Escolar (sistemas distintos).
rede_lbl <- c("0"="Privada","1"="Pública")
raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda","D"="Amarela","E"="Indígena")
sexo_lbl <- c("A"="Masculino","B"="Feminino")

## ---------- carregar e classificar ----------
carregar <- function(arq, etapa_chave, etapa_lbl) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arq)))
  dt[, etapa := etapa_lbl]
  dt[, faixa_lp := classificar(proficiencia_lp_saeb, cortes$lp[[etapa_chave]])]
  dt[, faixa_mt := classificar(proficiencia_mt_saeb, cortes$mt[[etapa_chave]])]
  dt[, rede   := rede_lbl[as.character(in_publica)]]
  dt[, raca   := raca_lbl[tx_resp_q04]]
  dt[, sexo   := sexo_lbl[tx_resp_q01]]
  dt[, regiao := regiao_de(id_uf)]
  dt
}
all_d <- rbindlist(list(
  carregar("saeb_2023_5ef.parquet","5ef","5º ano EF"),
  carregar("saeb_2023_9ef.parquet","9ef","9º ano EF"),
  carregar("saeb_2023_3em.parquet","3em","3º ano EM")
), fill = TRUE)
all_d[, etapa := factor(etapa, levels = c("5º ano EF","9º ano EF","3º ano EM"))]

## ---------- função de estratificação ----------
estratificar <- function(strat_var) {
  res <- list()
  for (disc in c("lp","mt")) {
    fcol <- paste0("faixa_", disc)
    sub <- all_d[!is.na(get(strat_var)) & !is.na(get(fcol)),
                 .(N = .N), by = c("etapa", strat_var, fcol)]
    setnames(sub, fcol, "faixa")
    sub[, disciplina := toupper(disc)]
    sub[, pct := round(N / sum(N) * 100, 1), by = c("etapa","disciplina", strat_var)]
    res[[disc]] <- sub
  }
  rbindlist(res)[order(etapa, disciplina, get(strat_var), faixa)]
}

tab_rede   <- estratificar("rede")
tab_raca   <- estratificar("raca")
tab_sexo   <- estratificar("sexo")
tab_regiao <- estratificar("regiao")

## cruzada raça × sexo × região
tab_cruz <- (function() {
  res <- list()
  for (disc in c("lp","mt")) {
    fcol <- paste0("faixa_", disc)
    sub <- all_d[!is.na(raca) & !is.na(sexo) & !is.na(regiao) & !is.na(get(fcol)),
                 .(N = .N), by = c("etapa","regiao","raca","sexo", fcol)]
    setnames(sub, fcol, "faixa")
    sub[, disciplina := toupper(disc)]
    sub[, pct := round(N / sum(N) * 100, 1), by = c("etapa","disciplina","regiao","raca","sexo")]
    res[[disc]] <- sub
  }
  rbindlist(res)[order(etapa, disciplina, regiao, raca, sexo, faixa)]
})()

## ---------- CSVs ----------
fwrite(tab_rede,   file.path(DIR_PROC, "expl_faixas_2023_rede.csv"))
fwrite(tab_raca,   file.path(DIR_PROC, "expl_faixas_2023_raca.csv"))
fwrite(tab_sexo,   file.path(DIR_PROC, "expl_faixas_2023_sexo.csv"))
fwrite(tab_regiao, file.path(DIR_PROC, "expl_faixas_2023_regiao.csv"))
fwrite(tab_cruz,   file.path(DIR_PROC, "expl_faixas_2023_raca_sexo_regiao.csv"))

## ---------- imprimir: % Adequado+ por strat ----------
adeq_plus_wide <- function(tab, strat_var, ordem = NULL) {
  ap <- tab[faixa %in% c("Adequado","Avançado"),
            .(pct_ap = sum(pct)), by = c("etapa","disciplina", strat_var)]
  w <- dcast(ap, etapa + disciplina ~ get(strat_var), value.var = "pct_ap")
  if (!is.null(ordem)) {
    cols_exist <- intersect(ordem, names(w))
    setcolorder(w, c("etapa","disciplina", cols_exist))
  }
  w
}

print_tab <- function(titulo, w) {
  cat("\n========== % Adequado + Avançado por", titulo, "==========\n")
  fmt <- copy(w)
  num_cols <- setdiff(names(fmt), c("etapa","disciplina"))
  for (c in num_cols) fmt[[c]] <- sprintf("%5.1f", fmt[[c]])
  print(fmt, row.names = FALSE)
}

print_tab("rede",   adeq_plus_wide(tab_rede,   "rede",   c("Pública","Privada")))
print_tab("raça",   adeq_plus_wide(tab_raca,   "raca",   c("Branca","Amarela","Parda","Preta","Indígena")))
print_tab("sexo",   adeq_plus_wide(tab_sexo,   "sexo",   c("Feminino","Masculino")))
print_tab("região", adeq_plus_wide(tab_regiao, "regiao", c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul")))

## ---------- cruzada — amostra (9º EF, LP) ----------
cat("\n========== Amostra da cruzada: 9º ano EF · LP · % Adequado+ ==========\n")
cruz_ap <- tab_cruz[faixa %in% c("Adequado","Avançado"),
                    .(pct_ap = sum(pct)), by = .(etapa,disciplina,regiao,raca,sexo)]
amostra <- cruz_ap[etapa == "9º ano EF" & disciplina == "LP"]
amostra_w <- dcast(amostra, regiao + raca ~ sexo, value.var = "pct_ap")
amostra_w[, regiao := factor(regiao, levels = c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]
amostra_w[, raca   := factor(raca,   levels = c("Branca","Amarela","Parda","Preta","Indígena"))]
setorder(amostra_w, regiao, raca)
for (c in c("Feminino","Masculino")) if (c %in% names(amostra_w))
  amostra_w[[c]] <- sprintf("%5.1f", amostra_w[[c]])
print(amostra_w, row.names = FALSE)

cat("\n=> CSVs salvos em pipeline/data/processed/expl_faixas_2023_*.csv\n")
