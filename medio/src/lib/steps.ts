// Os 13 passos do roteiro, alimentados pelos DADOS OFICIAIS do SAEB 2023
// (microdados de aluno do 9º ano EF, matemática, ponderados por PESO_ALUNO_MT).
//
// O JSON `medio-data.json` é gerado por pipeline/R/15_medio_dados.R. Atualizá-lo
// quando o INEP publicar nova onda do SAEB. Aqui só importamos os valores
// derivados e os usamos em template strings nas falas.

import type { PoseName } from './poses';
import dados from './medio-data.json';

export interface BarDef {
  id: string;
  x: number;
  w: number;
  score: number;
  label?: string;
  color?: string;
  opacity?: number;
  showScore?: boolean;
}

export interface MedioPlacement {
  id: string;
  barId?: string;
  freeX?: number;
  freeY?: number;
  scale: number;
  pose: PoseName;
  opacity?: number;
  offsetX?: number;
  offsetY?: number;
}

export type OverlayName = 'dispersion' | 'two-types' | 'final';

export interface Step {
  bars: BarDef[];
  medios: MedioPlacement[];
  speech: string;
  removeMedios?: string[];
  overlay?: OverlayName;
  alt: string;
}

// Paleta abreviada
const C = {
  orange: '#D35400',
  brown: '#5A3825',
  inkSoft: '#5A4A3F',
  mark: '#A82E2E',
  inkFaint: '#9A8B7E',
  brownSoft: '#8B5A3C',
  brownDeep: '#3D2418',
} as const;

// Atalho pra arredondar pra inteiro (a peça narra valores em pontos inteiros)
const R = (n: number) => Math.round(n);

// Constantes derivadas dos dados oficiais
const NACIONAL = R(dados.nacional);                            // 257
const PRIVADA = R(dados.rede.privada);                         // 295
const PUBLICA = R(dados.rede.publica);                         // 250
const DIF_REDE = R(dados.rede.diferenca);                      // 45
const NORTE_PUB = R(dados.norte_publico);                      // 240
const SE_PRIV = R(dados.sudeste_privado);                      // 300
const DIF_REGIAO_REDE = SE_PRIV - NORTE_PUB;                   // 60
const PRIV_EXT = R(dados.interseccional.privilegiado.media);   // 311
const DEPR_EXT = R(dados.interseccional.deprimido.media);      // 219
const DIF_INTERSEC = R(dados.interseccional.diferenca);        // 92

// 10 pontos do gradiente do passo 8 (interpolação linear entre o extremo
// deprimido e o privilegiado, pra representar o privilégio crescente).
const GRAD_10_SCORES: number[] = (() => {
  const lo = DEPR_EXT;
  const hi = PRIV_EXT;
  const n = 10;
  return Array.from({ length: n }, (_, i) => Math.round(lo + (hi - lo) * (i / (n - 1))));
})();

const GRAD_10_COLORS = [
  C.brownDeep, C.brown, '#704632', C.brownSoft, '#9A7A5C',
  '#B89072', '#D89A4F', C.orange, C.orange, C.mark,
];

// Quantis reais da nuvem (20 pontos, P2.5 a P97.5)
const NUVEM = dados.nuvem_quantis;

// Helper pra construir as 20 barras da nuvem com x igualmente espaçadas
function buildCloud20(): { id: string; x: number; w: number; score: number }[] {
  const n = NUVEM.length;
  const startX = 80;
  const totalW = 640;
  const gap = totalW / n;
  const barW = gap - 4;
  return NUVEM.map((score, i) => ({
    id: `d${i}`,
    x: startX + i * gap,
    w: barW,
    score,
  }));
}

// Posição do Médio "narrador" nos passos 9-13: canto esquerdo, na baseline.
const NARRATOR_X = 60;
const NARRATOR_Y = 460;

export const STEPS: Step[] = [
  // 1 — apresentação
  {
    bars: [{ id: 'main', x: 360, w: 80, score: NACIONAL, label: 'nota nacional · 9º ano · matemática', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'proud' }],
    speech: `<p>Sou <span class="mark">Médio</span>. Nascido diretamente do SAEB, 9º ano, matemática: <span class="mark">${NACIONAL}</span>.</p>
             <span class="aside">Vocês me usam toda semana, nem me notam, mas eu tô lá.</span>`,
    alt: `Médio se apresenta como a média nacional de ${NACIONAL} pontos do SAEB, 9º ano, matemática (dados oficiais). Uma única barra cinza no centro com o personagem em pose orgulhosa.`,
  },

  // 2 — como sou calculado
  {
    bars: [{ id: 'main', x: 360, w: 80, score: NACIONAL, label: `${NACIONAL} · média de ${(dados.n_alunos / 1e6).toFixed(1).replace('.', ',')} milhões`, color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'curious' }],
    speech: `<p>Meu pai juntou <span class="orange">${(dados.n_alunos / 1e6).toFixed(1).replace('.', ',')} milhões</span> de notas e minha mãe foi lá e dividiu certinho. Aí nasci eu.</p>
             <p>Tipo assim: uma parte de mim é 200, uma parte é ${NACIONAL}, uma parte é 320. No fim das contas, eu fico com <span class="mark">${NACIONAL}</span>.</p>
             <span class="aside">...O do meio sou eu. Acho. Os outros dois também são. Será?</span>`,
    alt: `Médio explica que é a média de ${(dados.n_alunos / 1e6).toFixed(1)} milhões de alunos, dividindo o total pelo número de alunos. Mesma barra única, em pose curiosa.`,
  },

  // 3 — inquietação
  {
    bars: [{ id: 'main', x: 360, w: 80, score: NACIONAL, label: '...', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'surprised' }],
    speech: `<p>Ihhhhh...</p>
             <p>Se o do 200 e o do 320 também são eu...</p>
             <p><span class="mark">O que sou eu, exatamente?</span></p>`,
    alt: 'Médio se questiona: se os alunos com 200 e com 320 também são "ele", o que ele realmente representa? Mesma barra, expressão de surpresa.',
  },

  // 4 — rede de ensino
  {
    bars: [
      { id: 'priv', x: 260, w: 75, score: PRIVADA, label: 'rede privada', color: C.orange },
      { id: 'pub', x: 465, w: 75, score: PUBLICA, label: 'rede pública', color: C.brown },
    ],
    medios: [
      { id: 'M', freeX: 400, freeY: 460, scale: 0.7, pose: 'troubled', opacity: 0.3 },
      { id: 'A', barId: 'priv', scale: 1.1, pose: 'neutral' },
      { id: 'B', barId: 'pub', scale: 1.1, pose: 'neutral' },
    ],
    speech: `<p>Olha só. Separa por rede:</p>
             <p>Privada, <span class="orange">${PRIVADA}</span>. Pública, <span class="brown">${PUBLICA}</span>.</p>
             <p><span class="mark">${pontosPorExtenso(DIF_REDE)}</span> — em escala SAEB, mais ou menos o que se aprende em um ano e meio de aula.</p>
             <span class="aside">...Acho que essa diferença não é justa.</span>`,
    alt: `O Médio se divide em dois: rede privada com ${PRIVADA} pontos e rede pública com ${PUBLICA} pontos. A diferença de ${DIF_REDE} pontos equivale a cerca de um ano e meio de aprendizagem.`,
  },

  // 5 — volta
  {
    bars: [{ id: 'main', x: 360, w: 80, score: NACIONAL, label: `${NACIONAL} · de volta à média`, color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'thinking' }],
    removeMedios: ['A', 'B'],
    speech: `<p>E quando junta de novo, eu volto pra <span class="mark">${NACIONAL}</span>.</p>
             <p>Como se nada tivesse acontecido. <span class="mark">Será que dá pra tomar decisão assim?</span></p>
             <span class="aside">Estranho, né? A conta tá certa. Mas alguma coisa some no caminho.</span>`,
    alt: `As duas barras se juntam novamente em uma única barra de ${NACIONAL} pontos. Médio em pose pensativa, questionando se decisões podem ser tomadas baseadas só na média.`,
  },

  // 6 — região + rede (foco no gestor)
  {
    bars: [
      { id: 'r-n', x: 130, w: 55, score: R(dados.regiao_rede['1'].publica), label: 'N · pública', color: C.brown },
      { id: 'r-ne', x: 215, w: 55, score: R(dados.regiao_rede['2'].publica), label: 'NE · pública', color: C.brownSoft },
      { id: 'r-se', x: 345, w: 55, score: R(dados.regiao_rede['3'].privada), label: 'SE · privada', color: C.orange },
      { id: 'r-s', x: 430, w: 55, score: R(dados.regiao_rede['4'].privada), label: 'S · privada', color: C.orange },
      { id: 'r-co', x: 540, w: 55, score: R(dados.regiao['CO']), label: 'CO · total', color: C.inkSoft },
    ],
    medios: [
      { id: 'M', freeX: 307, freeY: 460, scale: 0.6, pose: 'troubled', opacity: 0.3 },
      { id: 'A', barId: 'r-n', scale: 0.9, pose: 'troubled' },
      { id: 'B', barId: 'r-ne', scale: 0.9, pose: 'neutral' },
      { id: 'C', barId: 'r-se', scale: 0.9, pose: 'neutral' },
      { id: 'D', barId: 'r-s', scale: 0.9, pose: 'neutral' },
      { id: 'E', barId: 'r-co', scale: 0.9, pose: 'neutral' },
    ],
    speech: `<p>Agora por região, marcando rede onde a diferença pesa mais:</p>
             <p>Norte público: <span class="brown">${NORTE_PUB}</span>. Sudeste privado: <span class="orange">${SE_PRIV}</span>.</p>
             <p><span class="mark">${pontosPorExtenso(DIF_REGIAO_REDE)}.</span> Mas o gestor do Norte e o gestor do Sudeste não estão jogando com as mesmas cartas.</p>
             <span class="aside">Isso aqui não é geografia. É orçamento, é história, é o que tem disponível.</span>`,
    alt: `Cinco barras representando recortes regionais com rede em destaque: Norte público (${NORTE_PUB}), Nordeste público (${R(dados.regiao_rede['2'].publica)}), Sudeste privado (${SE_PRIV}), Sul privado (${R(dados.regiao_rede['4'].privada)}) e Centro-Oeste agregado (${R(dados.regiao['CO'])}). A diferença de ${DIF_REGIAO_REDE} pontos entre os extremos reflete condições estruturais.`,
  },

  // 7 — volta de novo
  {
    bars: [{ id: 'main', x: 360, w: 80, score: NACIONAL, label: `${NACIONAL} · outra vez`, color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'troubled' }],
    removeMedios: ['A', 'B', 'C', 'D', 'E'],
    speech: `<p>De novo <span class="mark">${NACIONAL}</span>. De novo certo.</p>
             <p><span class="mark">Quantas vezes eu já fui calculado hoje e ninguém viu isso por baixo?</span></p>`,
    alt: `A média volta a ${NACIONAL}. Médio com expressão incomodada, percebendo que cada vez que é calculado sem desagregação, esconde as diferenças estruturais por baixo.`,
  },

  // 8 — cor, renda, escolaridade (virada moral)
  (() => {
    const n = GRAD_10_SCORES.length;
    const startX = 90;
    const totalW = 620;
    const gap = totalW / n;
    const barW = 48;
    const bars: BarDef[] = GRAD_10_SCORES.map((score, i) => ({
      id: `g${i}`, x: startX + i * gap, w: barW, score, color: GRAD_10_COLORS[i],
    }));
    const medios: MedioPlacement[] = GRAD_10_SCORES.map((_, i) => ({
      id: `s${i}`,
      barId: `g${i}`,
      scale: 0.55,
      pose: i < 2 ? 'troubled' : i > 7 ? 'proud' : 'neutral',
    }));
    medios.unshift({ id: 'M', barId: 'g4', scale: 0.55, pose: 'troubled', opacity: 0.2 });

    return {
      bars,
      medios,
      speech: `<p>Tá. Vou mais fundo.</p>
               <p>Branca, privada, Sul, mãe com superior: <span class="orange">${PRIV_EXT}</span>.</p>
               <p>Preta, pública, Norte, mãe sem 5º ano: <span class="brown">${DEPR_EXT}</span>.</p>
               <p><span class="mark">${pontosPorExtenso(DIF_INTERSEC)}.</span> Cerca de três anos de escolaridade entre duas crianças de catorze.</p>
               <span class="aside">Espera. ...Será que a injustiça sou eu?</span>`,
      alt: `Dez barras em gradiente cruzando raça, rede, região e escolaridade da mãe. Do extremo deprimido (preta, pública, Norte, mãe sem 5º ano, ${DEPR_EXT}) ao privilegiado (branca, privada, Sul, mãe com superior, ${PRIV_EXT}): ${DIF_INTERSEC} pontos de diferença, cerca de três anos de escolaridade entre dois adolescentes de 14 anos.`,
    } satisfies Step;
  })(),

  // 9 — formulação da dispersão (nuvem com paleta neutra)
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const t = i / (cloud.length - 1);
      const palette = [C.brown, C.brownSoft, C.inkFaint, '#A88B6E', C.orange, C.mark];
      const idx = Math.min(palette.length - 1, Math.floor(t * palette.length));
      return { ...b, color: palette[idx], opacity: 0.55, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`, barId: b.id, scale: 0.4, pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'thinking', opacity: 0.9 });

    return {
      bars,
      medios,
      removeMedios: ['s0', 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9'],
      overlay: 'dispersion',
      speech: `<p>Calma. Não, espera. Deixa eu pensar.</p>
               <p>Toda média tem uma <span class="orange">nuvem em volta</span>. Estatísticos chamam de <span class="mark">dispersão</span>.</p>
               <p>Essa nuvem sempre vai existir. Pessoas são diferentes mesmo.</p>
               <p>Mas tem <span class="mark">dois tipos de diferença</span> misturadas dentro dela. E eu nunca tinha separado uma da outra.</p>`,
      alt: `Vinte barras formam a nuvem real da distribuição do SAEB 2023, do P2.5 (${R(NUVEM[0])}) ao P97.5 (${R(NUVEM[NUVEM.length - 1])}). Médio sai da nuvem e vai pro canto esquerdo, em pose pensativa.`,
    } satisfies Step;
  })(),

  // 10 — distinção (Soares)
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const isStructural = i < 4 || i > 15;
      const color = isStructural ? (i < 4 ? C.brown : C.mark) : C.inkFaint;
      return { ...b, color, opacity: isStructural ? 0.85 : 0.4, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`, barId: b.id, scale: 0.4, pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'thinking', opacity: 0.9 });

    return {
      bars,
      medios,
      overlay: 'two-types',
      speech: `<p>Uma parte da nuvem é <span class="orange">gente sendo gente</span>. Aprende rápido, aprende devagar, gosta mais, gosta menos.</p>
               <p>A outra parte é o que aconteceu <span class="mark">antes da prova começar</span>. Livro em casa. Biblioteca aberta. Professora que ficou. Internet que funcionou.</p>
               <span class="aside">Estatisticamente, é tudo dispersão. Politicamente, são coisas muito diferentes. ...Eu não sou o problema. Eu viro problema quando o que tô resumindo já vinha quebrado de antes.</span>`,
      alt: 'A nuvem ganha rótulos: extremos (estruturais) destacados em marrom e vermelho-marca, centro (variação individual esperada) em cinza.',
    } satisfies Step;
  })(),

  // 11 — Médio percebe (Collins, sem nomear)
  (() => {
    const cloud = buildCloud20();
    const palette = [C.brown, C.brownSoft, C.inkFaint, '#A88B6E', C.orange, C.mark];
    const bars: BarDef[] = cloud.map((b, i) => {
      const t = i / (cloud.length - 1);
      const idx = Math.min(palette.length - 1, Math.floor(t * palette.length));
      return { ...b, color: palette[idx], opacity: 0.6, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`, barId: b.id, scale: 0.4, pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'realizing', opacity: 0.95 });

    return {
      bars,
      medios,
      speech: `<p>Olha o que eu faço quando me usam <span class="mark">sozinho</span>:</p>
               <p>Pego desigualdade que veio de fora (bairro, renda, história, cor da pele) e devolvo <span class="orange">como se fosse diferença de desempenho</span>.</p>
               <p><span class="mark">Como se estivesse nas crianças.</span></p>
               <span class="aside">Eu não invento a desigualdade. Mas eu disfarço de onde ela vem.</span>`,
      alt: 'Médio em pose de quem percebeu: usado sozinho, ele transforma desigualdade externa (bairro, renda, raça, história) em diferença interna, como se a injustiça estivesse nas crianças.',
    } satisfies Step;
  })(),

  // 12 — reconciliação (visibilização)
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const isExtreme = i < 2 || i > 17;
      return {
        ...b,
        color: isExtreme ? C.mark : C.inkFaint,
        opacity: isExtreme ? 0.9 : 0.3,
        showScore: false,
      };
    });
    const medios: MedioPlacement[] = cloud.map((b, i) => {
      const isExtreme = i < 2 || i > 17;
      return {
        id: `dt${b.id}`, barId: b.id,
        scale: isExtreme ? 0.55 : 0.4,
        pose: 'tiny',
        opacity: isExtreme ? 1 : 0.4,
      };
    });
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'calm', opacity: 0.95 });

    return {
      bars,
      medios,
      speech: `<p>Olha, eu sirvo para algumas coisas. Monitorar a rede ao longo do tempo, comparar país com país, ver pra onde a coisa anda.</p>
               <p>E olha uma coisa que eu faço bem: quando me calculam <span class="orange">separado pra grupos que normalmente somem nos números grandes</span> — meninas negras do Norte, indígenas, quilombolas — aí eu mostro o que estava escondido.</p>
               <p><span class="mark">A média de quem é esquecido é onde a desigualdade aparece com nome.</span></p>
               <span class="aside">Política educacional precisa de mim — e do que tá em volta de mim, ao mesmo tempo.</span>`,
      alt: 'Os extremos da nuvem (populações esquecidas) ficam destacados em vermelho-marca, o meio fica esmaecido.',
    } satisfies Step;
  })(),

  // 13 — pedido final
  (() => {
    const cloud = buildCloud20();
    const n = cloud.length;
    const bars: BarDef[] = cloud.map((b, i) => {
      const isExtreme = i === 0 || i === n - 1;
      return {
        ...b,
        color: isExtreme ? (i === 0 ? C.brown : C.mark) : C.inkFaint,
        opacity: isExtreme ? 0.95 : 0.2,
        showScore: !!isExtreme,
      };
    });
    const medios: MedioPlacement[] = cloud.map((b, i) => {
      const isExtreme = i === 0 || i === n - 1;
      return {
        id: `dt${b.id}`, barId: b.id,
        scale: isExtreme ? 0.8 : 0.35,
        pose: isExtreme ? 'neutral' : 'tiny',
        opacity: isExtreme ? 1 : 0.25,
      };
    });
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.85, pose: 'calm', opacity: 0.9 });

    return {
      bars,
      medios,
      overlay: 'final',
      speech: `<p>Quando olharem pra mim, perguntem também:</p>
               <p>— O que tá dentro da minha <span class="orange">dispersão</span>?</p>
               <p>— Quanto é diferença, e quanto é <span class="mark">injustiça que vinha de antes</span>?</p>
               <p>— Quem o sistema preparou pra estar no topo, e quem o sistema preparou pra estar embaixo?</p>
               <span class="aside">Essa distinção é com vocês. Eu sou só a conta. Mas a conta também é política.</span>`,
      alt: `Os dois extremos reais da dispersão ficam em destaque: o quantil inferior em marrom (${R(NUVEM[0])}) e o superior em vermelho-marca (${R(NUVEM[n - 1])}). A peça termina com Médio pedindo que cada uso da média venha acompanhado de perguntas estruturais.`,
    } satisfies Step;
  })(),
];

export const TOTAL_STEPS = STEPS.length;

// Exportamos os metadados pra que a tela de créditos possa referenciar a fonte
// dos dados (data de geração, n de alunos, etc.).
export const DADOS_META = {
  fonte: dados.fonte,
  variavel: dados.variavel,
  n_alunos: dados.n_alunos,
  gerado_em: dados.gerado_em,
};

// Traduz um inteiro pequeno em sua forma por extenso em PT-BR.
// Usamos só pros valores específicos da peça (45, 60, 92, etc.).
function pontosPorExtenso(n: number): string {
  const especiais: Record<number, string> = {
    0: 'Zero ponto', 1: 'Um ponto', 2: 'Dois pontos',
    20: 'Vinte pontos', 25: 'Vinte e cinco pontos',
    26: 'Vinte e seis pontos', 30: 'Trinta pontos',
    40: 'Quarenta pontos', 44: 'Quarenta e quatro pontos',
    45: 'Quarenta e cinco pontos', 46: 'Quarenta e seis pontos',
    50: 'Cinquenta pontos',
    55: 'Cinquenta e cinco pontos', 60: 'Sessenta pontos',
    62: 'Sessenta e dois pontos', 65: 'Sessenta e cinco pontos',
    70: 'Setenta pontos', 75: 'Setenta e cinco pontos',
    76: 'Setenta e seis pontos', 80: 'Oitenta pontos',
    85: 'Oitenta e cinco pontos', 90: 'Noventa pontos',
    92: 'Noventa e dois pontos', 95: 'Noventa e cinco pontos',
    100: 'Cem pontos',
  };
  return especiais[n] ?? `${n} pontos`;
}
