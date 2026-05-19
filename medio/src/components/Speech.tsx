// Fala do Médio + aside (a "voz interior").
// Renderiza o HTML do passo atual via dangerouslySetInnerHTML (conteúdo vem do
// nosso próprio steps.ts, é seguro). A cada troca de html, faz um pequeno fade-in
// pra dar ritmo de virada de página.

import { useEffect, useRef } from 'react';
import gsap from 'gsap';

interface SpeechProps {
  html: string;
  reducedMotion: boolean;
}

export function Speech({ html, reducedMotion }: SpeechProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (reducedMotion) {
      el.style.opacity = '1';
      el.style.transform = 'translateY(0)';
      return;
    }
    gsap.fromTo(
      el,
      { opacity: 0, y: 6 },
      { opacity: 1, y: 0, duration: 0.45, ease: 'power2.out' },
    );
  }, [html, reducedMotion]);

  return (
    <div
      className="speech"
      ref={ref}
      aria-live="polite"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
