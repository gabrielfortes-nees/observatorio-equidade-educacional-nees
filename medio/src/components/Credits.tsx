// Tela final com os créditos: ancoragem teórica (Collins, Soares), nota sobre
// fonte oficial dos dados, botão pra recomeçar.

import { DADOS_META } from '../lib/steps';

interface CreditsProps {
  onRestart: () => void;
  onClose: () => void;
}

export function Credits({ onRestart, onClose }: CreditsProps) {
  const n = DADOS_META.n_alunos.toLocaleString('pt-BR');
  return (
    <div className="credits" role="dialog" aria-modal="true" aria-labelledby="credits-title">
      <div className="breadcrumb">Fim da peça · 13 de 13</div>
      <h2 id="credits-title">
        Médio: <em>confissões de um número em conflito</em>
      </h2>

      <p>
        Este é um experimento de narrativa com dados sobre como a média educacional, instrumento
        essencial para política pública, também pode esconder a estrutura social que produz suas
        próprias diferenças.
      </p>
      <p>
        Dados oficiais: <strong>{DADOS_META.fonte}</strong>. Médias ponderadas por PESO_ALUNO_MT
        sobre <strong>{n}</strong> alunos com proficiência válida.
      </p>

      <div className="thinkers">
        A peça pensa com{' '}
        <strong className="author-collins">Patricia Hill Collins</strong>{' '}
        sobre como o sistema produz os apagamentos que a média resume, e com{' '}
        <strong className="author-soares">Chico Soares</strong>{' '}
        sobre a distinção entre variação esperada e injustiça estrutural.
      </div>

      <div className="signature">Observatório de Equidade Educacional · NEES UFAL</div>

      <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.75rem' }}>
        <button type="button" className="btn" onClick={onClose}>
          ← voltar ao último ato
        </button>
        <button type="button" className="btn primary" onClick={onRestart}>
          recomeçar do início
        </button>
      </div>
    </div>
  );
}
