import { Simulator } from '../Simulator.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchSimulators(mode: DataMode): Promise<Simulator[]> {
  if (mode === 'mock') {
    const { mockSimulators } = await import('./Simulator.mock.ts');
    return mockSimulators();
  }
  const json = await apiClient.get<{ devices: Record<string, unknown>[] }>('/api/sim/devices');
  return json.devices.map(Simulator.fromJSON);
}
