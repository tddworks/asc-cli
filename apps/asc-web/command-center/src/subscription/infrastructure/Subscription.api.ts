import { SubscriptionGroup } from '../SubscriptionGroup.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchSubscriptionGroups(appId: string, mode: DataMode): Promise<SubscriptionGroup[]> {
  if (mode === 'mock') {
    const { mockSubscriptionGroups } = await import('./Subscription.mock.ts');
    return mockSubscriptionGroups(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/subscription-groups`);
  return json.data.map(SubscriptionGroup.fromJSON);
}
