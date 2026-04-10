import { User } from '../User.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchUsers(mode: DataMode): Promise<User[]> {
  if (mode === 'mock') {
    const { mockUsers } = await import('./User.mock.ts');
    return mockUsers();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/users');
  return json.data.map(User.fromJSON);
}
