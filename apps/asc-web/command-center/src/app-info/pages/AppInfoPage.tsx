export default function AppInfoPage() {
  return (
    <div>
      <div className="card" style={{ marginBottom: 16 }}>
        <div className="toolbar">
          <div className="toolbar-left"><h3>App Metadata</h3></div>
        </div>
        <div className="card-body">
          <div className="form-row">
            <div className="form-group">
              <label className="form-label">App Name</label>
              <input className="form-control" placeholder="My App" />
            </div>
            <div className="form-group">
              <label className="form-label">Subtitle</label>
              <input className="form-control" placeholder="A short description" />
            </div>
          </div>
          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Primary Category</label>
              <select className="form-control select-styled">
                <option>Weather</option>
                <option>Health & Fitness</option>
                <option>Utilities</option>
                <option>Productivity</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Privacy Policy URL</label>
              <input className="form-control" placeholder="https://..." />
            </div>
          </div>
          <button className="btn btn-primary" style={{ marginTop: 12 }}>Save</button>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <div className="toolbar-left"><h3>Localizations</h3></div>
          <div className="toolbar-right"><button className="btn btn-primary btn-sm">Add Locale</button></div>
        </div>
        <div className="table-wrapper">
          <table>
            <thead>
              <tr><th>Locale</th><th>Name</th><th>Subtitle</th><th>Actions</th></tr>
            </thead>
            <tbody>
              <tr>
                <td><span className="platform-badge">en-US</span></td>
                <td>WeatherApp</td>
                <td>Your daily weather</td>
                <td><button className="btn btn-secondary btn-sm">Edit</button></td>
              </tr>
              <tr>
                <td><span className="platform-badge">de-DE</span></td>
                <td>WetterApp</td>
                <td>Ihr t&auml;gliches Wetter</td>
                <td><button className="btn btn-secondary btn-sm">Edit</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
