import { Build } from '../Build.ts';
import { apiClient, type DataMode } from '../../shared/api-client.ts';

export async function fetchBuilds(appId: string, mode: DataMode): Promise<Build[]> {
  if (mode === 'mock') {
    const { mockBuilds } = await import('./Build.mock.ts');
    return mockBuilds(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/builds`);
  return json.data.map(Build.fromJSON);
}
