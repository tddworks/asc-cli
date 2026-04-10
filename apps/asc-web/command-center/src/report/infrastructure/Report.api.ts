import { Report } from '../Report.ts';
import { type DataMode } from '../../shared/api-client.tsx';

export async function fetchReports(mode: DataMode): Promise<Report[]> {
  if (mode === 'mock') {
    const { mockReports } = await import('./Report.mock.ts');
    return mockReports();
  }
  // Reports are client-side definitions; always return mock data
  const { mockReports } = await import('./Report.mock.ts');
  return mockReports();
}
