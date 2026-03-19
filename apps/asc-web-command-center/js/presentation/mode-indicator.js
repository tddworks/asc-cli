// Presentation: Data source mode indicator
import { DataProvider } from '../../../shared/infrastructure/data-provider.js';

export function updateModeIndicator() {
  const isCLI = DataProvider._mode === 'cli';
  document.getElementById('modeIconMock').style.display = isCLI ? 'none' : 'block';
  document.getElementById('modeIconCLI').style.display = isCLI ? 'block' : 'none';
  document.getElementById('modeDot').style.background = isCLI ? 'var(--success)' : 'var(--warning)';
  document.getElementById('modeToggle').title = isCLI ? 'Data source: Live CLI (click for mock)' : 'Data source: Mock (click for live CLI)';
}
