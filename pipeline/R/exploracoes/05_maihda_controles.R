## 05 — Controles MAIHDA v1
## (a) Sobrevivência de coorte: MAIHDA com reponderação de 9EF e 3EM
##     pela composição de estratos do 5EF. Se VPC reponderado sobe ao patamar
##     do 5EF, a queda observada é sobrevivência seletiva, não equalização.
## (b) Robustez: rodar M1A/M1B com INSE em quintis (5) em vez de tercis (3)
##     e com região como covariada fixa, e comparar VPC/PCV.
suppressMessages({
  library(arrow); library(data.table); library(lme4); library(broom.mixed)
})
source(here::here("pipeline/R/00_setup.R"))

raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda")
sexo_lbl <- c("A"="Masculino","B"="Feminino")
arqs <- c("5ef"="saeb_2023_5ef.parquet","9ef"="saeb_2023_9ef.parquet","3em"="saeb_2023_3em.parquet")
etapa_nome <- c("5ef"="5º EF","9ef"="9º EF","3em"="3º EM")

regiao_de <- function(id_uf) {
  g <- as.integer(id_uf) %/% 10
  fcase(g==1,"Norte", g==2,"Nordeste", g==3,"Sudeste", g==4,"Sul", g==5,"Centro-Oeste")
}

## ----- preparar dados -----
carregar <- function(et) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arqs[et])))
  dt <- dt[tx_resp_q04 %in% c("A","B","C") & tx_resp_q01 %in% c("A","B") &
           !is.na(inse_aluno) & !is.na(in_publica) &
           !is.na(proficiencia_lp_saeb) & !is.na(proficiencia_mt_saeb)]
  dt[, raca := raca_lbl[tx_resp_q04]]
  dt[, sexo := sexo_lbl[tx_resp_q01]]
  dt[, rede := fifelse(in_publica==1, "Publica", "Privada")]
  dt[, regiao := regiao_de(id_uf)]
  dt[, etapa := et]
  dt[, .(etapa, raca, sexo, rede, regiao, inse_aluno,
         prof_lp=proficiencia_lp_saeb, prof_mt=proficiencia_mt_saeb)]
}
all_d <- rbindlist(lapply(names(arqs), carregar))

brks_t <- quantile(all_d$inse_aluno, c(0,1/3,2/3,1), na.rm=TRUE)
brks_q <- quantile(all_d$inse_aluno, c(0,1/5,2/5,3/5,4/5,1), na.rm=TRUE)
all_d[, inse_tercil  := cut(inse_aluno, breaks=brks_t, labels=c("Baixo","Médio","Alto"),    include.lowest=TRUE)]
all_d[, inse_quintil := cut(inse_aluno, breaks=brks_q, labels=paste0("Q",1:5), include.lowest=TRUE)]
all_d[, raca   := factor(raca,   levels=c("Branca","Parda","Preta"))]
all_d[, sexo   := factor(sexo,   levels=c("Masculino","Feminino"))]
all_d[, rede   := factor(rede,   levels=c("Publica","Privada"))]
all_d[, regiao := factor(regiao, levels=c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]
all_d[, estrato_t := factor(paste(raca, sexo, inse_tercil,  sep=" | "))]
all_d[, estrato_q := factor(paste(raca, sexo, inse_quintil, sep=" | "))]

cat(sprintf("N total: %s · estratos tercil: %d · estratos quintil: %d\n\n",
            format(nrow(all_d), big.mark="."), nlevels(all_d$estrato_t), nlevels(all_d$estrato_q)))

## ============================================================
## CONTROLE 1 — SOBREVIVÊNCIA DE COORTE
## ============================================================
cat("\n=================== CONTROLE 1: SOBREVIVÊNCIA DE COORTE ===================\n\n")
cat("(a) Composição por estrato em cada etapa (%) e razão 3EM/5EF e 9EF/5EF:\n\n")

comp <- all_d[, .N, by=.(etapa, estrato_t)]
comp[, pct := N/sum(N)*100, by=etapa]
comp_w <- dcast(comp, estrato_t ~ etapa, value.var="pct")
setnames(comp_w, c("5ef","9ef","3em"), c("pct_5EF","pct_9EF","pct_3EM"))
comp_w[, razao_9EF_5EF := round(pct_9EF / pct_5EF, 2)]
comp_w[, razao_3EM_5EF := round(pct_3EM / pct_5EF, 2)]
for (c in c("pct_5EF","pct_9EF","pct_3EM")) comp_w[[c]] <- round(comp_w[[c]], 2)
print(comp_w[order(razao_3EM_5EF)])
cat("\nLeitura: razão <1 = estrato sobre-representado no 5EF (perdeu mais no caminho).\n")
cat("         razão >1 = estrato cresceu relativamente até o 3EM.\n\n")

cat("(b) MAIHDA reponderado: peso por estrato = p_5EF(estrato) / p_etapa(estrato)\n")
cat("    Aplicado em lmer(weights=w). Caveat: weights em lmer são tratados como\n")
cat("    inverso de variância, não como pesos amostrais de pseudo-likelihood;\n")
cat("    estimativa pontual de VPC é informativa, IC requer abordagem survey-weighted.\n\n")

# pesos para 9EF e 3EM (reflete composição 5EF)
# bug-fix: usar N/sum(N) dentro de uma etapa, não .N/nrow(.SD) com by=
p5 <- all_d[etapa=="5ef", .N, by=estrato_t][, p_ref := N/sum(N)][, .(estrato_t, p_ref)]
p9 <- all_d[etapa=="9ef", .N, by=estrato_t][, p_obs := N/sum(N)][, .(estrato_t, p_obs)]
p3 <- all_d[etapa=="3em", .N, by=estrato_t][, p_obs := N/sum(N)][, .(estrato_t, p_obs)]

w9_tab <- merge(p9, p5, by="estrato_t"); w9_tab[, w := p_ref/p_obs]
w3_tab <- merge(p3, p5, by="estrato_t"); w3_tab[, w := p_ref/p_obs]

d9 <- merge(all_d[etapa=="9ef"], w9_tab[, .(estrato_t, w)], by="estrato_t")
d3 <- merge(all_d[etapa=="3em"], w3_tab[, .(estrato_t, w)], by="estrato_t")

cat("Faixa dos pesos: 9EF [", round(min(w9_tab$w),2), "—", round(max(w9_tab$w),2), "] · ",
    "3EM [", round(min(w3_tab$w),2), "—", round(max(w3_tab$w),2), "]\n\n")

calc_vpc <- function(df, outcome, weights_col=NULL) {
  f <- as.formula(paste(outcome, "~ 1 + (1 | estrato_t)"))
  m <- if (is.null(weights_col)) lmer(f, data=df, REML=TRUE)
       else { df$.w <- df[[weights_col]]; lmer(f, data=df, REML=TRUE, weights=.w) }
  v_u <- as.numeric(VarCorr(m)$estrato_t); v_e <- sigma(m)^2
  list(vpc = 100 * v_u/(v_u+v_e))
}

tab_sobr <- data.table()
for (disc in c("lp","mt")) {
  col <- paste0("prof_", disc)
  v5  <- calc_vpc(all_d[etapa=="5ef"], col)
  v9  <- calc_vpc(d9, col)
  v9w <- calc_vpc(d9, col, "w")
  v3  <- calc_vpc(d3, col)
  v3w <- calc_vpc(d3, col, "w")
  tab_sobr <- rbind(tab_sobr, data.table(
    disciplina = toupper(disc),
    `VPC 5EF`           = round(v5$vpc,  2),
    `VPC 9EF bruto`     = round(v9$vpc,  2),
    `VPC 9EF reponderado` = round(v9w$vpc, 2),
    `VPC 3EM bruto`     = round(v3$vpc,  2),
    `VPC 3EM reponderado` = round(v3w$vpc, 2)
  ))
}
cat("VPC (%) por modelo:\n")
print(tab_sobr)

## ============================================================
## CONTROLE 2 — ROBUSTEZ (quintis e região)
## ============================================================
cat("\n\n=================== CONTROLE 2: ROBUSTEZ ===================\n\n")

run_mod <- function(df, outcome, estrato_col, fixed_inse, fixed_extra="") {
  f1a <- as.formula(paste(outcome, "~ 1 + (1 |", estrato_col, ")"))
  fb_terms <- paste0("raca + sexo + ", fixed_inse, " + rede", fixed_extra)
  f1b <- as.formula(paste(outcome, "~", fb_terms, "+ (1 |", estrato_col, ")"))
  m1a <- lmer(f1a, data=df, REML=TRUE)
  m1b <- lmer(f1b, data=df, REML=TRUE)
  v0 <- as.numeric(VarCorr(m1a)[[1]]); ve0 <- sigma(m1a)^2
  v1 <- as.numeric(VarCorr(m1b)[[1]])
  list(vpc=100*v0/(v0+ve0), pcv=100*(v0-v1)/v0)
}

tab_rob <- data.table()
for (et in names(arqs)) {
  df_et <- all_d[etapa==et]
  for (disc in c("lp","mt")) {
    col <- paste0("prof_", disc)
    base  <- run_mod(df_et, col, "estrato_t", "inse_tercil")
    quint <- run_mod(df_et, col, "estrato_q", "inse_quintil")
    reg   <- run_mod(df_et, col, "estrato_t", "inse_tercil", "+ regiao")
    tab_rob <- rbind(tab_rob, data.table(
      modelo = paste(etapa_nome[et], toupper(disc)),
      `VPC base (tercil, sem região)`   = round(base$vpc,  2),
      `PCV base`                        = round(base$pcv,  2),
      `VPC quintis`                     = round(quint$vpc, 2),
      `PCV quintis`                     = round(quint$pcv, 2),
      `VPC tercil + região`             = round(reg$vpc,   2),
      `PCV tercil + região`             = round(reg$pcv,   2)
    ))
  }
}
print(tab_rob)

## ----- salvar -----
fwrite(comp_w,   file.path(DIR_PROC, "maihda_v1_composicao_etapas.csv"))
fwrite(tab_sobr, file.path(DIR_PROC, "maihda_v1_sobrevivencia.csv"))
fwrite(tab_rob,  file.path(DIR_PROC, "maihda_v1_robustez.csv"))
cat("\n=> Salvos: maihda_v1_{composicao_etapas, sobrevivencia, robustez}.csv\n")
