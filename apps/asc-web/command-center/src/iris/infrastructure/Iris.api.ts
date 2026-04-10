import { IrisApp } from '../IrisApp.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchIrisApps(mode: DataMode): Promise<IrisApp[]> {
  if (mode === 'mock') {
    const { mockIrisApps } = await import('./Iris.mock.ts');
    return mockIrisApps();
  }
  const result = await apiClient.runCommand('iris apps list');
  try {
    const parsed = JSON.parse(result.stdout);
    const items = parsed.data ?? parsed;
    return (Array.isArray(items) ? items : []).map(IrisApp.fromJSON);
  } catch {
    return [];
  }
}
