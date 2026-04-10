import { useState, useEffect } from 'react';
import { App } from '../app/App.ts';
import { Build } from '../build/Build.ts';
import { Version } from '../version/Version.ts';
import { fetchApps } from '../app/infrastructure/App.api.ts';
import { fetchBuilds } from '../build/infrastructure/Build.api.ts';
import { fetchVersions } from '../version/infrastructure/Version.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

interface DashboardData {
  apps: App[];
  builds: Build[];
  versions: Version[];
  totalApps: number;
  liveVersions: number;
  recentBuilds: number;
  pendingReviews: number;
}

export function useDashboard() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    Promise.all([
      fetchApps(mode),
      fetchBuilds('app-1', mode),
      fetchVersions('app-1', mode),
    ]).then(([apps, builds, versions]) => {
      setData({
        apps,
        builds,
        versions,
        totalApps: apps.length,
        liveVersions: versions.filter((v) => v.isLive).length,
        recentBuilds: builds.filter((b) => b.isValid).length,
        pendingReviews: versions.filter((v) => v.isPending).length,
      });
    }).finally(() => setLoading(false));
  }, [mode]);

  return { data, loading };
}
