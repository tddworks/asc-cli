import { Review } from '../Review.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchReviews(appId: string, mode: DataMode): Promise<Review[]> {
  if (mode === 'mock') {
    const { mockReviews } = await import('./Review.mock.ts');
    return mockReviews(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/reviews`);
  return json.data.map(Review.fromJSON);
}
