import { useState } from 'react';
import { useBuilds } from '../Build.hooks.ts';
import { BuildRow } from '../components/BuildRow.tsx';
import type { Build } from '../Build.ts';

type Filter = 'all' | 'valid' | 'processing' | 'invalid';

function applyFilter(builds: Build[], filter: Filter): Build[] {
  switch (filter) {
    case 'valid': return builds.filter((b) => b.isValid);
    case 'processing': return builds.filter((b) => b.isProcessing);
    case 'invalid': return builds.filter((b) => !b.isValid && !b.isProcessing);
    default: return builds;
  }
}

export default function BuildList({ appId = 'app-1' }: { appId?: string }) {
  const { builds, loading, error } = useBuilds(appId);
  const [filter, setFilter] = useState<Filter>('all');

  if (loading) return <div className="spinner">Loading builds...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  const filtered = applyFilter(builds, filter);

  return (
    <div>
      <h2>Builds</h2>
      <div className="filter-bar" style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
        {(['all', 'valid', 'processing', 'invalid'] as Filter[]).map((f) => (
          <button
            key={f}
            className={`affordance-btn ${filter === f ? 'active' : ''}`}
            onClick={() => setFilter(f)}
            style={filter === f ? { background: 'var(--accent)', color: 'white', borderColor: 'var(--accent)' } : {}}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>Build</th>
            <th>Usable</th>
            <th>Status</th>
            <th>Expired</th>
            <th>Uploaded</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {filtered.map((b) => <BuildRow key={b.id} build={b} />)}
        </tbody>
      </table>
    </div>
  );
}
