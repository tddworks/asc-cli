import { useParams } from 'react-router-dom';
import { useVersions } from '../Version.hooks.ts';
import { VersionBadge } from '../components/VersionBadge.tsx';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function VersionList() {
  const { appId } = useParams<{ appId: string }>();
  const { versions, loading, error } = useVersions(appId!);

  if (loading) return <div className="spinner">Loading versions...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left">
          <h3>Versions</h3>
          <div className="filter-group">
            <button className="btn btn-sm active">All</button>
            <button className="btn btn-sm">Live</button>
            <button className="btn btn-sm">Editable</button>
          </div>
        </div>
        <div className="toolbar-right">
          <button className="btn btn-primary">Create Version</button>
        </div>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Version</th>
              <th>Platform</th>
              <th>State</th>
              <th>Build</th>
              <th>Created</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {versions.map((v) => (
              <tr key={v.id}>
                <td className="cell-primary">{v.versionString}</td>
                <td><span className="platform-badge">{v.platform}</span></td>
                <td><VersionBadge version={v} /></td>
                <td className="cell-mono">—</td>
                <td>—</td>
                <td><AffordanceBar affordances={v.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
