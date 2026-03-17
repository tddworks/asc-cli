// API layer — wraps asc CLI calls via the dev server

const API_BASE = window.location.origin;

export async function asc(cmd) {
  const full = cmd.startsWith('asc ') ? cmd : `asc ${cmd}`;
  const res = await fetch(`${API_BASE}/api/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ command: full }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error);
  if (data.exit_code !== 0) throw new Error(data.stderr || `Exit code ${data.exit_code}`);
  try { return JSON.parse(data.stdout); } catch { return data.stdout; }
}

export function toList(result) {
  if (Array.isArray(result)) return result;
  if (result?.data && Array.isArray(result.data)) return result.data;
  return [];
}
