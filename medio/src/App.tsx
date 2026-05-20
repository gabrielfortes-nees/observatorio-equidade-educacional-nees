// App.tsx — orquestra a peça inteira.
//
// Estado:
//   - currentStep: índice do passo atual (0..12)
//   - creditsOpen: tela final
//   - reducedMotion: lido de prefers-reduced-motion do sistema do usuário,
//     atravessa pra Canvas e Speech pra cortar animações quando pedido.
//
// Navegação:
//   - Setas direita/esquerda
//   - Espaço/Enter avançam
//   - Clique no canvas avança
//   - Dots clicáveis pulam pra qualquer passo
//   - Botões "anterior" / "próximo"

import { useCallback, useEffect, useState } from 'react';
import { BrandBar } from './components/BrandBar';
import { Canvas } from './components/Canvas';
import { Speech } from './components/Speech';
import { ProgressDots } from './components/ProgressDots';
import { Credits } from './components/Credits';
import { STEPS, TOTAL_STEPS, STEP_TITLES, STEP_BLOCK_STARTS } from './lib/steps';

function usePrefersReducedMotion(): boolean {
  const [reduced, setReduced] = useState<boolean>(() => {
    if (typeof window === 'undefined') return false;
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  });
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    const onChange = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);
  return reduced;
}

export function App() {
  const [currentStep, setCurrentStep] = useState(0);
  const [creditsOpen, setCreditsOpen] = useState(false);
  const reducedMotion = usePrefersReducedMotion();

  const goNext = useCallback(() => {
    setCurrentStep((s) => {
      if (s < TOTAL_STEPS - 1) return s + 1;
      // chegou no último passo, abrir créditos
      setCreditsOpen(true);
      return s;
    });
  }, []);

  const goPrev = useCallback(() => {
    if (creditsOpen) {
      setCreditsOpen(false);
      return;
    }
    setCurrentStep((s) => Math.max(0, s - 1));
  }, [creditsOpen]);

  const goTo = useCallback((idx: number) => {
    setCreditsOpen(false);
    setCurrentStep(Math.max(0, Math.min(TOTAL_STEPS - 1, idx)));
  }, []);

  const restart = useCallback(() => {
    setCreditsOpen(false);
    setCurrentStep(0);
  }, []);

  // Teclado
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        goNext();
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        goPrev();
      } else if (e.key === 'Escape' && creditsOpen) {
        setCreditsOpen(false);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [goNext, goPrev, creditsOpen]);

  const step = STEPS[currentStep];

  return (
    <>
      <BrandBar />

      <main className="piece-stage" aria-label="Peça Médio: confissões de um número em conflito">
        <header className={`piece-header${currentStep === 0 ? '' : ' compact'}`}>
          {currentStep === 0 ? (
            <>
              <div className="breadcrumb">Storytelling · estatística e equidade</div>
              <h1>
                Médio: <em>confissões de um número em conflito</em>
              </h1>
              <div className="ato-info">
                Ato 1 de {TOTAL_STEPS}
              </div>
            </>
          ) : (
            // A partir do ato 2 o título da peça já foi apresentado; o header
            // encolhe pra liberar espaço vertical pro canvas e pra fala. Só
            // o título do ato + a posição no arco continuam visíveis.
            <div className="breadcrumb compact-row">
              <span className="piece-name">Médio</span>
              <span className="dot-sep" aria-hidden="true">·</span>
              <span className="ato-title">{STEP_TITLES[currentStep] ?? `Ato ${currentStep + 1}`}</span>
              <span className="dot-sep" aria-hidden="true">·</span>
              <span className="ato-counter">{currentStep + 1} de {TOTAL_STEPS}</span>
            </div>
          )}
        </header>

        <section className="main-grid">
          <div
            className="canvas-wrap"
            onClick={() => goNext()}
            role="button"
            tabIndex={-1}
            aria-label="Clique para avançar para o próximo ato"
          >
            <span className="canvas-hint">← → ou clique pra avançar</span>
            <Canvas stepIndex={currentStep} reducedMotion={reducedMotion} />
          </div>

          <div className="narrative">
            <Speech html={step.speech} reducedMotion={reducedMotion} />
          </div>
        </section>

        <footer className="piece-footer">
          <div className="meta">protótipo · SAEB 9º ano · matemática (dados ilustrativos)</div>
          <ProgressDots
            total={TOTAL_STEPS}
            current={currentStep}
            onGoTo={goTo}
            titles={STEP_TITLES}
            blockStartIndices={STEP_BLOCK_STARTS}
          />
          <div className="controls">
            <button
              type="button"
              className="btn"
              onClick={goPrev}
              disabled={currentStep === 0 && !creditsOpen}
              aria-label="Ato anterior"
            >
              ← anterior
            </button>
            <button
              type="button"
              className="btn primary"
              onClick={goNext}
              aria-label={currentStep === TOTAL_STEPS - 1 ? 'Ir para os créditos' : 'Próximo ato'}
            >
              {currentStep === TOTAL_STEPS - 1 ? 'créditos →' : 'próximo →'}
            </button>
          </div>
        </footer>
      </main>

      {creditsOpen && (
        <Credits
          onRestart={restart}
          onClose={() => setCreditsOpen(false)}
        />
      )}
    </>
  );
}
