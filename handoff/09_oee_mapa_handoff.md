# Handoff — Construção do Mapa Interativo do OEE

> **Para a outra janela do Claude que vai retomar o mapa.** Este documento é a fonte única de verdade. Leia inteiro antes de começar.

**Data do handoff:** 2026-05-24
**Autor desta sessão:** Claude (sessão de análises — MAIHDA SAEB 2023)
**Para:** Claude da sessão dedicada a produtos digitais do OEE
**Projeto raiz:** `/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/`

---

## 1. Onde paramos

O usuário aceitou o **Plano A** de implementação do mapa interativo do Observatório de Equidade Educacional. Trabalho pausado a pedido do usuário (queria primeiro focar em explorações analíticas).

O **MVP funcional só com SAEB 2023** é o próximo passo. PNADC e INEP ficam para depois.

---

## 2. Decisões editoriais já tomadas (NÃO repetir o debate)

### 2.1 Indicadores do mapa (escopo fechado)

| Eixo | Indicador(es) | Filtros internos | Fonte |
|---|---|---|---|
| **Desempenho** | % Adequado+ (LP e MT) | etapa (5º EF, 9º EF, 3º EM), disciplina (LP/MT), rede (Pública/Privada) | SAEB 2023 microdados ✅ |
| **Permanência** | Taxa líquida de matrícula + Taxa de conclusão | etapa (EI, EF iniciais, EF finais, EM), faixa etária | PNADC via SIDRA ⏳ |
| **Abandono** | Taxa de abandono escolar + Distorção idade-série | etapa | Indicadores INEP (planilha) ⏳ |

### 2.2 Decisões sem volta

- **Sem série histórica.** Apenas um ponto temporal (2023). Decisão explícita do usuário.
- **Plano A escolhido:** SAEB com desagregação por raça/sexo/rede ✅; abandono e TDI sem raça (não publicado pelo INEP). Card mostra nota explicativa.
- **Granularidade:** UF (não município). 27 unidades.
- **Card lateral, não modal.** Aberto por clique em UF.
- **Mapa colore pela UF** sob o filtro selecionado. Card mostra **sempre** desagregações fixas (raça, sexo, rede) independente do filtro do mapa.
- **Stack GitHub Pages estático.** Sem backend. Dado pré-agregado em JSON ou parquet via `duckdb-wasm` (decisão técnica pendente).

### 2.3 Terminologia para o site

| No site (usuário final) | Tecnicamente correto (metodologia) |
|---|---|
| "Etapa" | "Ano avaliado" (SAEB) ou "Etapa de ensino" (Permanência/Abandono) |
| "Branca/Parda/Preta" | autodeclaração SAEB Q04 (excluí Amarela, Indígena por N pequeno) |
| "Pública/Privada" | binário IN_PUBLICA do SAEB |

---

## 3. Estado atual da implementação

### 3.1 ✅ Pronto

| Item | Localização | Estado |
|---|---|---|
| Orquestrador R do parquet único | `pipeline/R/30_indicadores_uf_serie.R` | rodando, gera 1.620 linhas só com SAEB 2023 |
| Parquet de output | `pipeline/data/processed/indicadores_uf_serie.parquet` | existe, formato long ok |
| Sketch HTML do card | `prototipo/sketch_card_uf.html` | aprovado conceitualmente, pode ir direto pra produção |
| Microdados SAEB 2023 | `pipeline/data/processed/saeb_2023_{5ef,9ef,3em}.parquet` | 35 colunas selecionadas, ~4.8M linhas total |

### 3.2 ⏳ Pendente (em ordem sugerida)

1. **Coleta PNADC via SIDRA** — taxa líquida + conclusão. Exploração SIDRA começou (tabela 7155 funciona para conclusão; taxa líquida precisa de outra abordagem, possivelmente baixar planilha "Indicadores PNE" do INEP diretamente).
2. **Coleta INEP Indicadores** — abandono + TDI. URLs no portal do INEP. Tentativas de URLs típicos retornaram 404; melhor caminho é WebFetch/scraping do portal `gov.br/inep/...`.
3. **Frontend** — mapa Leaflet + integração com card. Decisão técnica: JSON pré-agregado ou `duckdb-wasm`.

---

## 4. Esquema do parquet único

```
pipeline/data/processed/indicadores_uf_serie.parquet  (long format)

uf            chr   sigla (AL, BA, ...)
uf_nome       chr   nome completo
ano           int   2023 (único ponto)
eixo          chr   desempenho | permanencia | abandono
indicador     chr   pct_adequado_plus | taxa_liquida_matricula | taxa_conclusao
                    | taxa_abandono | distorcao_idade_serie
ano_avaliado  chr   5EF | 9EF | 3EM       (só SAEB, senão NA)
etapa         chr   EI | EF_iniciais | EF_finais | EM  (só permanência/abandono)
disciplina    chr   LP | MT  (só SAEB, senão NA)
rede          chr   total | publica | privada
raca          chr   total | branca | parda | preta | amarela | indigena
sexo          chr   total | masculino | feminino
localizacao   chr   total | urbana | rural
valor         num   percentual 0-100
n             int   denominador
cv            num   coeficiente de variação (só PNADC)
fonte         chr   saeb | pnadc | censo_escolar
```

Hoje só `eixo = desempenho` está populado. Os outros dois aparecem com `[pendente]` no orquestrador.

---

## 5. Sketch do card aprovado

`prototipo/sketch_card_uf.html` (abrir no navegador para ver).

**Características confirmadas:**
- 380px de largura, paleta laranja/cream/Lora+Work Sans (variáveis CSS do `index.html`)
- Sem sparkline de série histórica (decisão de não fazer série)
- Mostra: nome UF + sigla → valor atual + delta opcional → ranking BR → 3 blocos de recortes (raça, sexo, rede) → link "Ver leitura completa"
- Tag "⚠ alta margem de erro" quando `cv > 20` (PNADC pequenas UFs)
- Aviso "indicador não desagregado por rede nesta fonte" quando filtro retorna NA

---

## 6. Plano A — passo a passo realista (2 dias úteis)

1. **Dia 1 manhã:** finalizar coleta PNADC (~2h)
   - SIDRA Tabela 7155 para taxa de conclusão (15+ por curso mais elevado)
   - Taxa líquida: tentar planilha do INEP Indicadores PNE; fallback é microdados PNADC com pacote `PNADcIBGE`
   - Salvar agregado em `pipeline/data/agregados/pnadc_matricula_conclusao_uf.parquet`
   - Adicionar bloco B ao orquestrador `30_indicadores_uf_serie.R`

2. **Dia 1 tarde:** coleta INEP Indicadores (~1-2h)
   - Baixar planilha de Taxa de Rendimento + TDI 2023 do portal INEP
   - URLs tentadas anteriormente deram 404; precisa navegar pelo portal real
   - Salvar agregado em `pipeline/data/agregados/censo_escolar_abandono_tdi_uf.parquet`
   - Adicionar bloco C ao orquestrador

3. **Dia 2:** frontend (~6-8h)
   - Decisão técnica: parquet via `duckdb-wasm` ou JSON pré-agregado (recomendo JSON pré-agregado para simplicidade)
   - Implementar mapa Leaflet no `index.html` (ou em página nova `mapa.html`)
   - Implementar card lateral baseado em `prototipo/sketch_card_uf.html`
   - Integrar filtros: eixo + indicador + etapa + raça + sexo + rede
   - Testar localmente com `python3 -m http.server 8731`

4. **Validação:** comparar valores com QEdu / Painel INEP para 3-5 UFs

---

## 7. Tarefas técnicas pendentes registradas

Da TaskList da sessão de análises (não migra automaticamente para a outra janela):

- `#38 [in_progress]` PNADC via SIDRA — taxa líquida + conclusão
- `#39 [pending]` INEP Indicadores — abandono + TDI
- `#40 [pending]` Mapa Leaflet + card no index.html

A outra janela pode recriar essas tasks ao começar.

---

## 8. Trade-offs e advertências honestas

### 8.1 O que vai ficar visivelmente "menos" no card

- **Abandono e Distorção idade-série não desagregam por raça** (INEP não publica). Card mostra: "indicador não desagregado por raça nesta fonte". É um achado em si mesmo — silenciamento institucional.
- **PNADC tem CV alto em UFs pequenas** (AC, RR, AP, DF). Card mostra tag de aviso quando `cv > 20`.
- **Sem série histórica.** Só um ponto temporal (2023). Não tem sparkline.

### 8.2 Riscos técnicos

- **GitHub Pages estático** = sem backend. Filtros precisam ser client-side.
- **Performance:** parquet de ~200 KB é OK em JSON. Se aumentar muito, usar `duckdb-wasm`.
- **Mobile:** card lateral 380px no desktop, drawer full-width no mobile.

---

## 9. Arquivos-chave para abrir primeiro

| Arquivo | Por quê |
|---|---|
| `prototipo/sketch_card_uf.html` | ver o design aprovado |
| `pipeline/R/30_indicadores_uf_serie.R` | orquestrador, ver onde adicionar blocos B e C |
| `pipeline/data/processed/indicadores_uf_serie.parquet` | output atual (só SAEB) |
| `index.html` | landing page, ver paleta e onde acoplar o mapa |
| Este handoff (`handoff/09_oee_mapa_handoff.md`) | manter aberto para consulta |

---

## 10. Sugestão de primeira mensagem na outra janela

> Quero retomar a construção do mapa interativo do Observatório de Equidade Educacional. Leia `handoff/09_oee_mapa_handoff.md` por inteiro antes de qualquer ação. Lá está tudo: decisões já tomadas, estado atual, pendências e plano. Depois de ler, me confirme o plano antes de começar a coletar PNADC.

---

## 11. O que NÃO mexer (esta janela cuida)

- Pasta `academico/maihda_saeb2023/` — paper MAIHDA pronto, em revisão
- `pipeline/R/exploracoes/04_maihda_v1.R` até `09_tables_paper_en.R` — análises do paper
- `handoff/08_maihda_exploratorio_brief.md` — brief do paper

Estes ficam vivos na sessão de análises. A outra janela só lê se precisar de contexto.

---

## 12. Contato em caso de divergência

Se você (outro Claude) chegar a uma decisão que parece conflitar com este handoff, pare e peça ao usuário para confirmar antes de mudar curso. As decisões aqui foram debatidas exaustivamente; mudanças unilaterais geram retrabalho.
