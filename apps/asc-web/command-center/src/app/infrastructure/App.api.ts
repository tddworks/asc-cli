import { App } from '../App.ts';
import { apiClient } from '../../shared/api-client.tsx';
import type { DataMode } from '../../shared/api-client.tsx';

export async function fetchApps(mode: DataMode): Promise<App[]> {
  if (mode === 'mock') {
    const { mockApps } = await import('./App.mock.ts');
    return mockApps();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/apps');
  return json.data.map(App.fromJSON);
}

export async function fetchApp(appId: string, mode: DataMode): Promise<App> {
  if (mode === 'mock') {
    const { mockApps } = await import('./App.mock.ts');
    const app = mockApps().find((a) => a.id === appId);
    if (!app) throw new Error(`App ${appId} not found`);
    return app;
  }
  const json = await apiClient.get<{ data: Record<string, unknown> }>(`/api/v1/apps/${appId}`);
  return App.fromJSON(json.data);
}
