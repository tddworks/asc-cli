import { useSimulators } from '../Simulator.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function SimulatorPage() {
  const { simulators, loading, error } = useSimulators();

  if (loading) return <div className="spinner">Loading simulators...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left"><h3>Simulators</h3></div>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>State</th>
              <th>Runtime</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {simulators.map((s) => (
              <tr key={s.udid}>
                <td className="cell-primary">{s.name}</td>
                <td><span className={`status ${s.isBooted ? 'live' : 'draft'}`}>{s.state}</span></td>
                <td><span className="platform-badge">{s.runtime}</span></td>
                <td><AffordanceBar affordances={s.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
