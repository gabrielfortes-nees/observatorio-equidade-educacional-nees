// Efeito de partículas pra transições significativas entre passos.
//
// Conceito: a média é "muitas pessoas viradas numa coisa só". Quando o Médio se
// divide (passo 3 → 4) ou se reúne (passo 5), ele literalmente se desfaz em
// partículas que voam pras posições das novas barras (ou se reagrupam na barra
// única). É a meta-narrativa visual da peça: a estatística aparece compondo e
// se decompondo.
//
// Disparado pelo Canvas quando há barras NOVAS ou REMOVIDAS entre passos.
// Cada partícula é um círculo SVG pequeno (raio 1.5-2.5px), animado por GSAP
// de uma posição-fonte aleatória pra uma posição-destino aleatória. Staggered
// delay dá o sensação de "explosão controlada".

import gsap from 'gsap';
import { make } from './svg';

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
  color?: string;
}

interface SpawnOptions {
  count?: number;
  duration?: number;
  reducedMotion?: boolean;
}

export function spawnParticles(
  layer: SVGGElement,
  sources: Rect[],
  targets: Rect[],
  opts: SpawnOptions = {},
): void {
  const { count = 220, duration = 0.85, reducedMotion = false } = opts;
  if (reducedMotion || sources.length === 0 || targets.length === 0) return;

  // Pré-aloca todas as partículas em DOM, com opacity 0, posicionadas em fontes.
  // Depois dispara o tween com delay aleatório pra criar a sensação de jato.
  for (let i = 0; i < count; i++) {
    const src = sources[Math.floor(Math.random() * sources.length)];
    const dst = targets[Math.floor(Math.random() * targets.length)];
    const sx = src.x + Math.random() * src.w;
    const sy = src.y + Math.random() * src.h;
    const dx = dst.x + Math.random() * dst.w;
    const dy = dst.y + Math.random() * dst.h;
    const r = 1.4 + Math.random() * 1.0;
    const finalOpacity = 0.55 + Math.random() * 0.35;
    const color = dst.color ?? src.color ?? '#5a4a3f';

    const p = make('circle', {
      cx: sx,
      cy: sy,
      r,
      fill: color,
    });
    p.style.opacity = '0';
    layer.appendChild(p);

    const stagger = Math.random() * 0.35;

    // 1ª fase: aparece e voa pra posição-destino
    gsap.to(p, {
      attr: { cx: dx, cy: dy },
      opacity: finalOpacity,
      duration: duration * (0.7 + Math.random() * 0.5),
      delay: stagger,
      ease: 'power2.out',
      onComplete: () => {
        // 2ª fase: fica visível um instante, depois fade out e remove do DOM
        gsap.to(p, {
          opacity: 0,
          duration: 0.35,
          delay: 0.15 + Math.random() * 0.25,
          onComplete: () => p.remove(),
        });
      },
    });
  }
}

// Helper pra calcular Rect de uma barra (com base no score e geometria do canvas).
export function barRect(
  x: number,
  w: number,
  barTopY: number,
  baselineY: number,
  color?: string,
): Rect {
  return { x, y: barTopY, w, h: baselineY - barTopY, color };
}

// Helper pra calcular Rect do corpo do Médio aproximado (usado como fonte
// quando o Médio "se desfaz" sem ter barras anteriores).
export function medioBodyRect(
  centerX: number,
  feetY: number,
  scale = 1,
  color?: string,
): Rect {
  // O corpo do xkcd Médio (XKCD const) cobre aproximadamente:
  //   vertical: do feetY até feetY - (43 + 32 + headOffset 15) ≈ feetY - 90
  //   horizontal: ±20 ao redor do centerX (com braços abertos pode ir além,
  //   mas usamos o tronco como aproximação razoável)
  const heightLocal = 90 * scale;
  const halfWidth = 18 * scale;
  return {
    x: centerX - halfWidth,
    y: feetY - heightLocal,
    w: halfWidth * 2,
    h: heightLocal,
    color,
  };
}
