// Barra de marca do Observatório de Equidade Educacional.
// Reproduz a estrutura usada em index.html (landing) e travessias.html
// pra manter a identidade visual entre as peças.

export function BrandBar() {
  return (
    <nav className="brand-bar" aria-label="Cabeçalho do Observatório">
      <a className="logo" href="../index.html" title="Voltar para o Observatório">
        <div className="logo-mark" aria-hidden="true" />
        <span>Observatório de Equidade Educacional</span>
      </a>
      <div className="nav-meta">NEES · UFAL</div>
    </nav>
  );
}
