# Referências para avaliação de protótipos do OEE

Esta pasta abriga material de referência usado para avaliar, ancorar e justificar decisões de design dos protótipos do Observatório de Equidade Educacional (Travessias, Médio, Insights3 dinâmico, Matriz Documental, e futuros).

A ideia: em vez de avaliar protótipos com princípios genéricos de UX, cruzá-los com critérios **vencedores de prêmios reais de visualização de dados** (Cláudio Weber Abramo, Sigma Awards, PacificVis VisStory). Isso transforma "minha opinião" em "rubrica externa replicável".

## Documento principal

[`Revisao_Plataformas_VisData_Premiadas.xlsx`](Revisao_Plataformas_VisData_Premiadas.xlsx)

Revisão consolidada de plataformas e projetos premiados em visualização de dados (06/05/2026). Dez abas:

| Aba | Conteúdo | Quando usar |
|---|---|---|
| 1. Sumário | Objetivo, estrutura, instruções de uso | Ler primeiro pra entender o material |
| 2. Prêmios | Comparativo dos 4 prêmios fonte (CWA, Sigma, VisStory, IIB Awards) com critérios-chave de cada júri | Decidir qual prêmio é referência mais próxima do tipo de projeto |
| 3. Critérios | Rubrica de 14 critérios em 6 dimensões (Narrativa, Rigor, Técnica, Impacto, UX/Design, Inclusão, Inovação) com perguntas-guia | **Avaliar qualquer protótipo OEE.** Use como checklist antes de publicar |
| 4. Projetos | Catálogo de 30+ projetos premiados (URL, organização, ano, tema, formato, justificativa do júri) | Buscar referências visuais e estilísticas concretas |
| 5. Features | Matriz 30+ projetos × 17 features (scrollytelling, mapas, 3D, IA, multilíngue, etc.) com ✓/○/– | Checklist de features candidatas; comparar o que cada premiado faz |
| 6. Stack | Stacks tecnológicas recorrentes (D3, MapLibre, Python, Svelte, GSAP, etc.) | Justificar escolhas técnicas com precedentes |
| 7. Diferenciais | 12+ padrões qualitativos recorrentes em vencedores (ex: storytelling guiado supera dashboard) | Identificar o "ingrediente diferencial" a buscar |
| 8. Acessibilidade | Onde projetos premiados falham em a11y e o que recomendam (WCAG 2.2, mobile, multilíngue) | Posicionar acessibilidade como diferencial competitivo do OEE |
| 9. Lições p Educação | Síntese: o que os premiados ensinam aplicado ao contexto de desigualdade educacional brasileira | Briefing condensado pra qualquer protótipo OEE novo |
| 10. Referências | Links de prêmios, projetos e literatura acadêmica de visualização | Aprofundar em qualquer ponto |

## Como usar

### Antes de começar um protótipo novo
- Aba 9 (Lições p Educação) como briefing.
- Aba 4 (Projetos) pra buscar 2-3 referências visuais específicas.

### Durante o design
- Aba 3 (Critérios) como checklist contínua: cada critério tem pergunta-guia.
- Aba 7 (Diferenciais) pra confirmar que está fazendo o que vencedores fazem.

### Antes de publicar
- Auditar contra Aba 3 inteira.
- Verificar Aba 8 (Acessibilidade) com axe-core/Lighthouse.
- Confirmar Aba 5 (Features): há features ausentes que valeriam adicionar?

### Quando outro pesquisador pegar o projeto
- README + Aba 1 (Sumário) dão contexto em 5 minutos.

## Atualização

Documento gerado em **06/05/2026**. Atualizar quando:
- Novas edições de prêmios saírem (anual).
- Projetos novos ganharem reconhecimento internacional relevante.
- Aparecerem referências de literatura acadêmica importantes (ex: Franconeri 2021 já está; novos surveys de perception estarão).
