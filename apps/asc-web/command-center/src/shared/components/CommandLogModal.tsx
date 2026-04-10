interface CommandLogEntry {
  type: 'prompt' | 'output' | 'error';
  text: string;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
  entries: CommandLogEntry[];
}

export function CommandLogModal({ isOpen, onClose, entries }: Props) {
  return (
    <div className={`modal-overlay ${isOpen ? 'open' : ''}`} onClick={onClose}>
      <div className="modal" style={{maxWidth:640}} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Command Log</h3>
          <button className="modal-close" onClick={onClose}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
        <div className="modal-body">
          <div className="cmd-log">
            {entries.length === 0 ? (
              <div><span className="cmd-prompt">$</span> Ready. Run commands from the UI to see logs here.</div>
            ) : (
              entries.map((e, i) => (
                <div key={i}><span className={`cmd-${e.type}`}>{e.text}</span></div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export type { CommandLogEntry };
