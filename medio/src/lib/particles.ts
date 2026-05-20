// Efeito de "construção por pixels" pras transições da peça.
//
// Conceito: a média é "muitas pessoas viradas numa coisa só". Quando o Médio se
// divide (passo 3 → 4) ou se reúne (passo 5), ele literalmente se desfaz em
// pixels que voam pras posições de cada barra — não como purpurina aleatória,
// mas chegando em uma GRADE de coordenadas que desenha a forma da barra. Os
// pixels DESCANSAM ali um instante (o espectador vê eles formando a barra),
// depois fazem fade-out enquanto a barra sólida materializa por trás.
//
// Ordem temporal:
//   t=0.0  pixels nascem na fonte, com opacidade 0
//   t=0.0–0.6   voam até a posição-alvo na grade dentro da barra
//   t=0.6–1.0   descansam visíveis (a "construção" da barra é vista)
//   t=1.0–1.4   fade-out enquanto a barra sólida fade-in completa
//
// O Canvas, ao chamar este módulo, deve atrasar o fade-in da barra sólida
// em ~0.5s pra os pixels chegarem primeiro.

import gsap from 'gsap';
import { make } from './svg';

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
  color?: string;
}

export interface TargetPoint {
  x: number;
  y: number;
  color: string;
}

interface SpawnOptions {
  duration?: number;     // duração do voo (sem dwell e sem fade)
  dwellTime?: number;    // tempo "parado" antes do fade-out
  reducedMotion?: boolean;
}

export function spawnParticles(
  layer: SVGGElement,
  sources: Rect[],
  targets: TargetPoint[],
  opts: SpawnOptions = {},
): void {
  const {
    duration = 0.55,
    dwellTime = 0.5,
    reducedMotion = false,
  } = opts;
  if (reducedMotion || sources.length === 0 || targets.length === 0) return;

  // Embaralha targets pra evitar padrão linear no voo (quem chega primeiro
  // não fica num lugar específico da barra).
  const shuffled = [...targets].sort(() => Math.random() - 0.5);

  for (let i = 0; i < shuffled.length; i++) {
    const pt = shuffled[i];
    const src = sources[Math.floor(Math.random() * sources.length)];
    const sx = src.x + Math.random() * src.w;
    const sy = src.y + Math.random() * src.h;
    const r = 1.6 + Math.random() * 0.7;

    const p = make('circle', { cx: sx, cy: sy, r, fill: pt.color });
    p.style.opacity = '0';
    layer.appendChild(p);

    const flyStagger = (i / shuffled.length) * 0.25 + Math.random() * 0.18;
    const flyDur = duration * (0.85 + Math.random() * 0.3);
    const peakOpacity = 0.7 + Math.random() * 0.25;

    // Fase 1: voo até a posição-alvo
    gsap.to(p, {
      attr: { cx: pt.x, cy: pt.y },
      opacity: peakOpacity,
      duration: flyDur,
      delay: flyStagger,
      ease: 'power2.out',
      onComplete: () => {
        // Fase 2: dwell (fica parado, visível, formando a barra) e fade-out
        gsap.to(p, {
          opacity: 0,
          duration: 0.35,
          delay: dwellTime + Math.random() * 0.15,
          ease: 'power1.in',
          onComplete: () => p.remove(),
        });
      },
    });
  }
}

// Gera uma grade de pontos dentro de um retângulo, com leve jitter pra parecer
// mais "natural" (pixel rabiscado, não régua perfeita).
// `count` é alvo aproximado; a grade vai gerar próximo disso, respeitando a
// proporção do retângulo (cols/rows ≈ w/h).
export function gridPoints(
  x: number,
  y: number,
  w: number,
  h: number,
  count: number,
  color: string,
  jitter = 1.4,
): TargetPoint[] {
  if (count <= 0 || w <= 0 || h <= 0) return [];
  const ratio = w / h;
  const rows = Math.max(2, Math.round(Math.sqrt(count / Math.max(0.05, ratio))));
  const cols = Math.max(2, Math.round(count / rows));
  const dx = w / (cols + 1);
  const dy = h / (rows + 1);
  const out: TargetPoint[] = [];
  for (let i = 1; i <= cols; i++) {
    for (let j = 1; j <= rows; j++) {
      out.push({
        x: x + i * dx + (Math.random() - 0.5) * jitter,
        y: y + j * dy + (Math.random() - 0.5) * jitter,
        color,
      });
    }
  }
  return out;
}
