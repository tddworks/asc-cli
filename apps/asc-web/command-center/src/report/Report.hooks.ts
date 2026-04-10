import { useState, useEffect } from 'react';
import { Report } from './Report.ts';
import { fetchReports } from './infrastructure/Report.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useReports() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchReports(mode)
      .then(setReports)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { reports, loading, error };
}
