interface Props {
  title?: string;
}

export function Header({ title = 'Command Center' }: Props) {
  return (
    <header className="header">
      <div className="header-left">
        <h1 className="header-title" id="pageTitle">{title}</h1>
      </div>
      <div className="header-right">
        <div className="header-btn" title="Theme toggle">🌙</div>
      </div>
    </header>
  );
}
