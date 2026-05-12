#!/usr/bin/env Rscript
# ============================================================
# 01_exportar_excel_inicial.R
# Extrai o `DADOS` do HTML original (matriz_analitica_equidade2.html)
# e gera o Excel longo (uma linha por par documento-dimensao) +
# a aba de metadados.
#
# Rode UMA UNICA VEZ para iniciar o fluxo:
#   Rscript 01_exportar_excel_inicial.R
#
# Saida: ../data/matriz_documentos.xlsx
# ============================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(openxlsx)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

args <- commandArgs(trailingOnly = FALSE)
arg_file <- args[grep("--file=", args)]
aqui <- if (length(arg_file) == 1) {
  dirname(normalizePath(sub("--file=", "", arg_file)))
} else {
  getwd()
}

caminho_json <- file.path(aqui, "..", "data", "dados_originais.json")
caminho_saida <- file.path(aqui, "..", "data", "matriz_documentos.xlsx")

dados <- fromJSON(caminho_json, simplifyVector = FALSE)
cat("Lidos", length(dados), "documentos do JSON intermediario.\n")

# ----- Aba 1: metadados (45 linhas) -----------------------
metadados <- data.frame(
  id = vapply(dados, \(d) d$id, integer(1)),
  nome_curto = vapply(dados, \(d) d$nome_curto, character(1)),
  categoria = vapply(dados, \(d) d$categoria, character(1)),
  identificacao_formal = vapply(dados, \(d) d$identificacao_formal, character(1)),
  ano = vapply(dados, \(d) d$ano, character(1)),
  orgao_responsavel = vapply(dados, \(d) d$orgao_responsavel, character(1)),
  nivel_ensino = vapply(dados, \(d) d$nivel_ensino, character(1)),
  dimensao_equidade_principal = vapply(dados, \(d) d$dimensao_equidade_principal, character(1)),
  fonte_oficial = vapply(dados, \(d) d$fonte_oficial, character(1)),
  stringsAsFactors = FALSE
)

# ----- Aba 2: matriz longa (45 x 6 = 270 linhas) ----------
ordem_dim <- c("atendimento", "aprendizagem", "infraestrutura",
               "pessoal_formacao", "territorialidade", "inclusao")
nome_dim <- c("Atendimento", "Aprendizagem", "Infraestrutura",
              "Pessoal / Formacao", "Territorialidade", "Inclusao")
names(nome_dim) <- ordem_dim

linhas <- list()
for (d in dados) {
  for (dim in ordem_dim) {
    atribs <- d$dimensoes[[dim]]
    linhas[[length(linhas) + 1]] <- data.frame(
      id_doc = d$id,
      nome_curto = d$nome_curto,
      dimensao_chave = dim,
      dimensao_nome = nome_dim[[dim]],
      variaveis = atribs$variaveis %||% "nao encontrado",
      quant = atribs$quant %||% "nao encontrado",
      qual = atribs$qual %||% "nao encontrado",
      equidade = atribs$equidade %||% "nao encontrado",
      stringsAsFactors = FALSE
    )
  }
}
matriz_longa <- do.call(rbind, linhas)
cat("Geradas", nrow(matriz_longa), "linhas na matriz longa.\n")

# ----- Aba 3: funcao redistributiva da Uniao (CF 211 + LDB 9) ----
# Marca os instrumentos que operacionalizam a funcao redistributiva da Uniao
# (transferir recursos, prestar assistencia tecnica, corrigir desigualdades,
# garantir padrao minimo, equalizar oportunidades) e descreve como fazem.
# Demais docs ficam com "tem=0" e podem ser editados pelo usuario no Excel.
redistrib_seed <- list(
  list(1L,  1L,"Vincula recursos a educacao (art. 212 — 18% da Uniao e 25% de estados e municipios) e estabelece o regime de colaboracao com funcao redistributiva e supletiva da Uniao (art. 211, paragrafo 1)."),
  list(2L,  1L, "Art. 9, X-XIII atribui a Uniao a responsabilidade de prestar assistencia tecnica e financeira a estados e municipios para garantir oferta com padrao minimo de qualidade."),
  list(7L,  1L, "Politica afirmativa nacional que equaliza acesso ao ensino superior publico federal — reserva 50% das vagas com subcotas por renda, raca/cor, PCD e (apos 2023) quilombolas."),
  list(9L,  1L, "Diretriz III explicita superacao das desigualdades; metas 7 (qualidade), 8 (escolaridade media por raca/renda/territorio) e 20 (financiamento como % do PIB) operam logica redistributiva entre redes."),
  list(10L, 1L, "Instrumento redistributivo central do financiamento da educacao basica. A complementacao da Uniao e repartida em tres caminhos com logicas distintas: o VAAF eleva o valor por aluno em redes cujo fundo estadual ficou abaixo do minimo nacional (equalizacao vertical entre federados); o VAAT considera o total das receitas vinculadas a educacao e completa as redes em que o valor total ainda e insuficiente; o VAAR (art. 14, paragrafo 3o) e repartido entre as redes que cumprem condicionalidades de gestao (CACS-Fundeb ativo, plano de carreira docente atualizado, Lei do Piso cumprida, sistema de avaliacao institucional permanente, plano municipal ou estadual alinhado ao PNE) e demonstram melhoria na proficiencia do Saeb com reducao de desigualdade pelo Indicador de Equidade da Aprendizagem. A propria lei estabelece, assim, os instrumentos formais de medida da funcao redistributiva."),
  list(11L, 1L, "Transferencia condicional da Uniao diretamente ao estudante (CadUnico/Bolsa Familia) com gatilhos de matricula, frequencia e conclusao — equaliza condicoes de permanencia no ensino medio publico."),
  list(12L, 1L, "Apoio financeiro e tecnico da Uniao para ampliar a matricula em tempo integral, com criterios redistributivos por vulnerabilidade territorial e socioeconomica."),
  list(14L, 1L, "Apoio tecnico e financeiro da Uniao para escolas do campo, assentados, quilombolas e ribeirinhos, com diretrizes proprias de infraestrutura, projeto pedagogico e formacao docente."),
  list(15L, 1L, "Criterios de apoio da Uniao consideram proporcao de criancas nao alfabetizadas, NSE, recortes etnico-raciais, genero e PCD — alocacao redistributiva por necessidade da rede."),
  list(16L, 1L, "Aporta R$ 1,5 bi ate 2027 para implementar a Lei 10.639/2003 com criterios tecnicos por rede; inclui o Diagnostico Equidade em 100% das redes como condicao de monitoramento."),
  list(8L,  1L, "LBI determina ao poder publico assegurar oferta de educacao inclusiva com AEE, profissional de apoio e acessibilidade (art. 28) — vincula a Uniao a apoio tecnico e ao financiamento da rede.")
)
redistrib_df <- data.frame(
  id_doc = vapply(redistrib_seed, \(x) x[[1]], integer(1)),
  tem_funcao_redistributiva = vapply(redistrib_seed, \(x) x[[2]], integer(1)),
  como_redistribui = vapply(redistrib_seed, \(x) x[[3]], character(1)),
  stringsAsFactors = FALSE
)
# Completar com todos os outros docs (tem=0, como=NA)
ids_seed <- redistrib_df$id_doc
ids_faltam <- setdiff(metadados$id, ids_seed)
if (length(ids_faltam) > 0) {
  redistrib_df <- rbind(redistrib_df,
    data.frame(
      id_doc = ids_faltam,
      tem_funcao_redistributiva = 0L,
      como_redistribui = NA_character_,
      stringsAsFactors = FALSE
    )
  )
}
redistrib_df <- redistrib_df[order(redistrib_df$id_doc), ]
# Acoplar nome do doc para facilitar edicao manual no Excel
redistrib_df$nome_curto <- metadados$nome_curto[match(redistrib_df$id_doc, metadados$id)]
redistrib_df <- redistrib_df[, c("id_doc", "nome_curto",
                                 "tem_funcao_redistributiva", "como_redistribui")]

# ----- Aba 4: legenda das categorias ----------------------
legenda <- data.frame(
  chave_categoria = c("marco_constitucional","lei_federal","decreto_federal",
                      "portaria_mec","portaria_inep","resolucao_cne",
                      "instrumento_avaliacao","indicador_educacional",
                      "sistema_informacao","programa_federal","governanca",
                      "marco_internacional","instrumento_monitoramento"),
  rotulo_exibicao = c("Marco Constitucional","Lei Federal","Decreto Federal",
                      "Portaria MEC","Portaria Inep","Resolucao CNE",
                      "Instrumento de Avaliacao","Indicador Educacional",
                      "Sistema de Informacao","Programa Federal","Governanca",
                      "Marco Internacional","Instrumento de Monitoramento"),
  stringsAsFactors = FALSE
)

# ----- Escrever Excel -------------------------------------
wb <- createWorkbook()
addWorksheet(wb, "metadados")
addWorksheet(wb, "matriz_longa")
addWorksheet(wb, "funcao_redistributiva")
addWorksheet(wb, "categorias")

writeData(wb, "metadados", metadados)
writeData(wb, "matriz_longa", matriz_longa)
writeData(wb, "funcao_redistributiva", redistrib_df)
writeData(wb, "categorias", legenda)

# Estilo de cabecalho
estilo_hdr <- createStyle(textDecoration = "bold", fgFill = "#F5EBD7",
                          border = "bottom", borderStyle = "thin")
addStyle(wb, "metadados", estilo_hdr, rows = 1, cols = seq_len(ncol(metadados)))
addStyle(wb, "matriz_longa", estilo_hdr, rows = 1, cols = seq_len(ncol(matriz_longa)))
addStyle(wb, "funcao_redistributiva", estilo_hdr, rows = 1, cols = seq_len(ncol(redistrib_df)))
addStyle(wb, "categorias", estilo_hdr, rows = 1, cols = seq_len(ncol(legenda)))

setColWidths(wb, "metadados", cols = 1:ncol(metadados),
             widths = c(5, 40, 25, 40, 10, 30, 25, 35, 60))
setColWidths(wb, "matriz_longa", cols = 1:ncol(matriz_longa),
             widths = c(6, 40, 18, 22, 50, 50, 50, 50))
setColWidths(wb, "funcao_redistributiva", cols = 1:ncol(redistrib_df),
             widths = c(6, 40, 12, 90))
setColWidths(wb, "categorias", cols = 1:2, widths = c(28, 32))

saveWorkbook(wb, caminho_saida, overwrite = TRUE)
cat("Excel salvo em:", caminho_saida, "\n")
cat("Abas: metadados (", nrow(metadados), " linhas), matriz_longa (",
    nrow(matriz_longa), " linhas), funcao_redistributiva (",
    nrow(redistrib_df), " linhas, ", sum(redistrib_df$tem_funcao_redistributiva == 1),
    " pre-marcadas), categorias (", nrow(legenda), " linhas).\n", sep = "")
