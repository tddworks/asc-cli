import { BetaGroup } from '../BetaGroup.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchBetaGroups(appId: string, mode: DataMode): Promise<BetaGroup[]> {
  if (mode === 'mock') {
    const { mockBetaGroups } = await import('./TestFlight.mock.ts');
    return mockBetaGroups(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/betaGroups`);
  return json.data.map(BetaGroup.fromJSON);
}
