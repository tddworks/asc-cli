import { useState } from 'react';
import { useProducts, useWorkflows } from '../XcodeCloud.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function XcodeCloudPage() {
  const { products, loading: productsLoading, error: productsError } = useProducts();
  const [selectedProductId, setSelectedProductId] = useState('');
  const { workflows, loading: workflowsLoading } = useWorkflows(selectedProductId);

  if (productsLoading) return <div className="spinner">Loading products...</div>;
  if (productsError) return <div className="error">Error: {productsError.message}</div>;

  return (
    <div>
      <h2>Xcode Cloud</h2>

      <div className="card">
        <div className="card-header">
          <h3>CI/CD Products</h3>
        </div>
        <div className="table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Type</th>
                <th>App ID</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr
                  key={p.id}
                  onClick={() => setSelectedProductId(p.id)}
                  style={{ cursor: 'pointer', background: selectedProductId === p.id ? 'var(--surface-hover)' : undefined }}
                >
                  <td>{p.name}</td>
                  <td><span className="platform-badge">{p.productType}</span></td>
                  <td className="cell-mono">{p.appId ?? '--'}</td>
                  <td><AffordanceBar affordances={p.affordances} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {selectedProductId && (
        <div className="card" style={{ marginTop: 16 }}>
          <div className="card-header">
            <h3>Workflows</h3>
          </div>
          {workflowsLoading ? (
            <div className="spinner">Loading workflows...</div>
          ) : (
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Workflow</th>
                    <th>Enabled</th>
                    <th>Locked</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {workflows.map((w) => (
                    <tr key={w.id}>
                      <td>{w.name}</td>
                      <td>
                        <span className={`status ${w.isEnabled ? 'live' : 'draft'}`}>
                          {w.isEnabled ? 'Active' : 'Disabled'}
                        </span>
                      </td>
                      <td>
                        <span className={`status ${w.isLockedForEditing ? 'pending' : 'draft'}`}>
                          {w.isLockedForEditing ? 'Locked' : 'Unlocked'}
                        </span>
                      </td>
                      <td><AffordanceBar affordances={w.affordances} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
