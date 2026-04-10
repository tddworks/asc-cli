import { Submission } from '../Submission.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchSubmission(versionId: string, mode: DataMode): Promise<Submission> {
  if (mode === 'mock') {
    const { mockSubmission } = await import('./Submission.mock.ts');
    return mockSubmission(versionId);
  }
  const json = await apiClient.get<Record<string, unknown>>(`/api/v1/versions/${versionId}/submission`);
  return Submission.fromJSON(json);
}

export async function fetchSubmissions(mode: DataMode): Promise<Submission[]> {
  if (mode === 'mock') {
    const { mockSubmissions } = await import('./Submission.mock.ts');
    return mockSubmissions();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/submissions');
  return json.data.map(Submission.fromJSON);
}
