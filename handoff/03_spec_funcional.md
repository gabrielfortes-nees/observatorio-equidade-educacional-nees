# Spec funcional — leitura por leitura

Uma página por leitura. O time front deve usar isso para entender o que cada componente faz. O time back para entender que dado precisa estar disponível.

Template: **dimensão · pergunta de leitura · fonte de dado · cálculo · viz · copy · qualitativo · aviso**.

---

## L1 · Desempenho — média esconde gap interseccional

- **Pergunta:** quem aprende? A média nacional do SAEB esconde quanta diferença?
- **Fonte:** SAEB 2023 microdados aluno · 5º EF · escolas públicas · 1,7 milhão de alunos
- **Variáveis usadas:** `PROFICIENCIA_LP_SAEB`, `TX_RESP_Q01` (sexo), `TX_RESP_Q04` (cor/raça), `INSE_ALUNO` (NSE)
- **Cálculo:** filtra escolas públicas + respostas válidas; recodifica raça em `branca/amarela` × `preta/parda` × `indígena`; quintiliza INSE; calcula `adequado = proficiencia_lp_saeb >= 200`; agrupa nos 8 grupos `(sexo × raça-binária × Q1/Q5)`.
- **Viz:** barras horizontais empilhadas top→bottom, paleta gradiente laranja-escuro→vermelho conforme grupo desce a hierarquia. Linha tracejada na média.
- **Copy:** o título traz a média Brasil. O texto cita gap racial bruto (8,4 pp), faixa interseccional do extremo ao extremo (~34 pp) e crítica à média.
- **Qualitativo:** Cavalleiro (2000), Carvalho (2009) — silenciamento institucional sobre raça começa antes da alfabetização.
- **Atualização:** anual (SAEB é bienal, mas a estrutura roda sempre que o INEP publica novos microdados).

---

## L2 · Desempenho — escolaridade da mãe explica mais

- **Pergunta:** o capital educacional materno pesa mais que o paterno na trajetória do filho?
- **Fonte:** SAEB 2023 9º EF · escolas públicas
- **Variáveis:** `PROFICIENCIA_LP_SAEB`, `TX_RESP_Q08` (escolaridade mãe), `TX_RESP_Q09` (escolaridade pai)
- **Códigos Q08/Q09:** A=não completou EF · B=EF até 5º ano · C=EF completo · D=EM completo · E=Superior completo · F=Não sei (**descartar**). **Atenção:** o protótipo original assumiu 8 níveis (com pós-graduação) — não existe na pergunta SAEB.
- **Cálculo:** média de proficiência por nível, separado mãe vs pai.
- **Viz:** linha (mãe = laranja escuro contínuo; pai = cinza tracejado). 5 pontos no eixo X.
- **Copy:** abre a diferença em pontos entre extremos (mãe +38, pai +32, diferença de +6) e crítica racial: "escolaridade da mãe carrega a marca racial da geração anterior".
- **Qualitativo:** Yosso (2005) · *community cultural wealth*.

---

## L3 · Desempenho · Contrafactual — infraestrutura como direito

- **Pergunta:** o que aconteceria se nenhuma escola brasileira tivesse os 3 itens básicos (água + banheiro PNE + alimentação)?
- **Fonte:** Censo Escolar 2025 (escola) × SAEB 2023 5º EF · agregado por **UF** (SAEB usa código de município INEP ≠ IBGE, então só UF cruza limpo)
- **Variáveis:** `IN_AGUA_POTAVEL`, `IN_BANHEIRO_PNE`, `IN_ALIMENTACAO` (Censo Escolar) · `PROFICIENCIA_LP_SAEB`
- **Cálculo:** marca escolas `infra_3_3 = (todos 3 itens == 1)`; % escolas 3/3 por UF; quartiliza 27 UFs em Q1 (menor cobertura) a Q4 (maior); calcula média ponderada de `adequado` por UF dentro de cada quartil.
- **Contrafactual "off":** todas as UFs caem para o valor de Q1 (40,2% adequado). Interpretação: *"se nenhuma escola tivesse os 3 itens, a aprendizagem em todo o país convergiria para o pior cenário observado"*.
- **Viz:** 4 barras horizontais com toggle real ↔ off + barra "ghost" tracejada com o cenário alternativo. Mini-legenda explicativa no topo.
- **Copy:** alta % nacional de escolas faltando algum item (54,3%); diferença entre extremos da quartilização (23,3 pp em aprendizagem adequada).
- **Aviso:** o "off" é uma estimativa conservadora baseada em comparação cross-section, não experimento. Documentar isso.

---

## L4 · Permanência — creche que não chegou ressoa no SAEB

- **Pergunta:** a desigualdade aos 18 meses reaparece aos 10 anos?
- **Fonte:** Censo Escolar 2025 (matrículas creche por escola), SIDRA tabela 9514 (pop 0-3 por município), SAEB 2023 5º EF · agregado por **UF**
- **Variáveis:** `QT_MAT_INF_CRE` (Censo Escolar matrícula), pop 0-3 (SIDRA), `PROFICIENCIA_LP_SAEB`
- **Cálculo:** matrículas creche por UF / pop 0-3 por UF = cobertura % por UF; quintiliza UFs pela cobertura; SAEB % adequado por UF; agrega pelos mesmos quintis (média ponderada pelo nº de alunos).
- **Viz:** 2 painéis empilhados (A: cobertura creche por quintil; B: aprendizagem adequada por mesma quintilização). Linha tracejada da meta PNE (50%).
- **Copy:** cobertura nacional (41,9%) + meta PNE não atingida + paralelismo entre as curvas dos painéis.
- **Qualitativo:** Passos (2010) · permanência como construção política.

---

## L5 · Permanência — 4 forças simultâneas

- **Pergunta:** o que tira o aluno da escola? Trabalho doméstico, trabalho fora, infra, clima — tudo junto, sobre o mesmo corpo.
- **Fonte:** SAEB 2023 9º EF (uso do tempo + clima) · Censo Escolar 2025 (banheiro PNE × localização)
- **Variáveis:** `TX_RESP_Q21c` (horas trab. doméstico), `TX_RESP_Q21d` (trab. fora), `TX_RESP_Q23a-i` (clima escolar/segurança), `IN_BANHEIRO_PNE`, `TP_LOCALIZACAO`
- **Cálculo:** mapeia categorias A-E para midpoints de horas (Q21c/d); calcula média semanal (× 7) por grupo. Q23 escala 1-4 (A=4 mais positivo, D=1), média das 9 alternativas. Banheiro PNE: % escolas sem por urbana/rural.
- **Viz:** small multiples 2×2. Ordem fixa nos quadrantes 1, 2, 4: ♂brancos · ♀brancas · ♂pretos/pardos · ♀pretas/pardas. Quadrante 3 (infra): urbana vs rural.
- **Copy:** abre com diferença de horas (♀pretas/pardas vs ♂brancos) + sentimento de segurança + infra. Argumento: permanência é múltipla, tratar isolado é tratar errado.
- **Qualitativo:** Paraíso (2016) · Reay (2017).

---

## L6 · Permanência · Contrafactual — Bolsa Família

- **Pergunta:** o que acontece se removermos a condicionalidade da escola no Bolsa Família?
- **Fonte:** folha do Novo Bolsa Família, Portal da Transparência, abril/2025 (1 mês representativo; mensal). Literatura: Cedeplar/UFMG, IPEA TD 2447, Banco Mundial.
- **Cálculo:** leitura agregada (UF, município) do CSV de 2,2 GB via `unzip -p`. Total nacional: 20,4 mi benefícios · R$ 13,6 bi · 5.570 municípios.
- **Viz contrafactual:** 4 barras (quintis de renda municipal) com toggle real ↔ off. Os valores `real` e `off` **vêm da literatura** (Cedeplar et al.), não recalculados internamente. O dado BF abr/2025 aparece no callout, dando ancoragem temporal.
- **Aviso:** ser transparente que viz das 4 barras são estimativas convergentes da literatura, não cálculo direto. Badge "Evidência forte" no source.
- **Qualitativo:** Reay (2017) · Passos (2010).

---

## L7 · Abandono — reprovação como porta

- **Pergunta:** quanto a reprovação aumenta a chance de abandono?
- **Fonte:** SAEB 2023 9º EF · `TX_RESP_Q19` (reprovação) × `TX_RESP_Q20` (abandono)
- **Cálculo:** % de quem declarou ≥1 abandono entre 3 categorias de reprovação (nunca, 1 vez, 2+); razão de chances simples.
- **Viz:** 3 barras horizontais espessas. Curva tracejada conectando "nunca reprovou" e "reprovou 1 vez" para destacar o salto.
- **Copy:** razão 4,6× para 1 reprovação; 8,4× para 2+; argumento "saída é desfecho, não causa".
- **Qualitativo:** Oliveira, Carrano & Marinho (2015).

---

## L8 · Abandono — autodeclaração SAEB 3º EM

- **Pergunta:** quem já abandonou ao menos uma vez e ainda está respondendo o SAEB?
- **Fonte:** SAEB 2023 · 3º EM · `TX_RESP_Q20` × `TX_RESP_Q04`
- **Cálculo:** % declarando abandono ≥1 por categoria racial (5 categorias).
- **Viz:** barras horizontais simples, paleta gradiente do mais privilegiado ao mais marginalizado.
- **Aviso metodológico (crítico):** "quem efetivamente abandonou JÁ NÃO está no SAEB" — sub-representa. A magnitude real é maior. Documentar explicitamente no card e em qualquer publicação derivada. **Esta leitura substitui** a "coorte que não voltou" do protótipo original, que não é viável após o INEP descontinuar microdados aluno-a-aluno em 2022.
- **Pendência:** quando a base de Taxas de Rendimento INEP for baixada, adicionar dado oficial agregado como complemento.

---

## L9 · Abandono · Contrafactual — Lei de Cotas

- **Pergunta:** como a composição racial dos ingressantes em IES federais seria sem a Lei de Cotas?
- **Fonte:** Censo Educação Superior 2024 — `QT_ING_PRETA/PARDA/BRANCA/AMARELA/INDIGENA` × `TP_CATEGORIA_ADMINISTRATIVA` (federal). Contrafactual ancorado em Censo 2010-2012 e ANDIFES.
- **Cálculo:** agregação dos 720 mil cursos por categoria administrativa; soma de ingressantes por raça; % sobre total declarado. Comparação direta com valores Censo 2012 pré-implementação plena.
- **Contrafactual "off":** valores observados em 2012 (pre_pretos = 4,6%, pre_pardos = 23,5%, pre_brancos = 65,8%, pre_indígenas = 0,4%). Não é estimativa — é série histórica.
- **Viz:** 4 barras toggle real ↔ off.
- **Copy:** salto +23,7 pp em pretos+pardos entre 2012 e 2024.

---

## Mapa navegável

- **Pergunta:** como o gap interseccional se distribui geograficamente?
- **Fonte:** SAEB 2023 5º EF · escolas públicas · agregado por UF
- **Camadas:** 6 — geral, ♂brancos/amarelos, ♀brancas/amarelas, ♂pretos/pardos, ♀pretas/pardas, indígenas
- **Cálculo:** % `adequado` ponderada por aluno dentro de cada UF × camada
- **Geometria:** GeoJSON oficial, 27 estados, propriedade `sigla`
- **Interação:** clique em filtro troca camada (cor + ranking sidebar). Hover destaca UF. Tooltip nativo SVG.

---

## Itens curatoriais que **NÃO** são dinâmicos (intencionalmente)

- Todos os textos `quali` (bloco "Em diálogo com a pesquisa qualitativa") — são citações curadas, não vêm do JSON.
- A página "Sombra silenciada" (texto de fechamento sobre limitações dos dados) — texto curatorial fixo.
- Títulos/copy curatorial dos cards — apenas os **valores numéricos** dentro deles são dinâmicos via `{{narrativa.xxx}}`.

Mudanças curatoriais (mudar uma citação, ajustar uma frase) → editar HTML direto, não precisa rodar pipeline.

Mudanças de dado (novo ano de SAEB, novo Censo Escolar) → rodar pipeline R, gerar novo JSON, página atualiza sozinha sem editar HTML.
