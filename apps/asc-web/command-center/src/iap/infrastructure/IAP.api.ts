import { InAppPurchase } from '../InAppPurchase.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchIAPs(appId: string, mode: DataMode): Promise<InAppPurchase[]> {
  if (mode === 'mock') {
    const { mockIAPs } = await import('./IAP.mock.ts');
    return mockIAPs(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/iap`);
  return json.data.map(InAppPurchase.fromJSON);
}
