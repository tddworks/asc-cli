import { useState, useEffect } from 'react';
import { Submission } from './Submission.ts';
import { fetchSubmission, fetchSubmissions } from './infrastructure/Submission.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useSubmission(versionId: string) {
  const [submission, setSubmission] = useState<Submission | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchSubmission(versionId, mode)
      .then(setSubmission)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [versionId, mode]);

  return { submission, loading, error };
}

export function useSubmissions() {
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchSubmissions(mode)
      .then(setSubmissions)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { submissions, loading, error };
}
