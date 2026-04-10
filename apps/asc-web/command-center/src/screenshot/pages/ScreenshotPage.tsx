export default function ScreenshotPage() {
  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left"><h3>Screenshots</h3></div>
      </div>
      <div className="card-body" style={{ textAlign: 'center', padding: 40 }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>🖼️</div>
        <h3>Screenshot Management</h3>
        <p style={{ color: 'var(--text-muted)', marginBottom: 16, maxWidth: 480, margin: '8px auto 16px' }}>
          Manage app store screenshots with version picker, locale tabs, and device-type grouping.
          Upload, reorder, and preview screenshots across all device types and locales.
        </p>
        <p style={{ color: 'var(--text-muted)', fontSize: 13 }}>
          Full screenshot management coming soon. Use <code style={{ background: 'var(--bg-hover)', padding: '2px 6px', borderRadius: 4 }}>asc screenshot-sets list</code> via CLI.
        </p>
      </div>
    </div>
  );
}
