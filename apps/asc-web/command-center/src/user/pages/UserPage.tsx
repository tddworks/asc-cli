import { useUsers } from '../User.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function UserPage() {
  const { users, loading, error } = useUsers();

  if (loading) return <div className="spinner">Loading users...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left"><h3>Users &amp; Roles</h3></div>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Roles</th>
              <th>All Apps</th>
              <th>Provisioning</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td className="cell-primary">{u.displayName}</td>
                <td>{u.email}</td>
                <td>{u.roles.map((r) => <span key={r} className="platform-badge" style={{ marginRight: 4 }}>{r}</span>)}</td>
                <td><span className={`status ${u.allAppsVisible ? 'live' : 'draft'}`}>{u.allAppsVisible ? 'Yes' : 'No'}</span></td>
                <td><span className={`status ${u.provisioningAllowed ? 'live' : 'draft'}`}>{u.provisioningAllowed ? 'Yes' : 'No'}</span></td>
                <td><AffordanceBar affordances={u.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
