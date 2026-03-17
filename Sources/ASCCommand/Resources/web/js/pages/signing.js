import { asc, toList } from '../api.js';
import { esc, badge, timeAgo, table, empty } from '../components.js';

export async function render() {
  const [bundleIds, certs, profiles] = await Promise.all([
    asc('bundle-ids list --output json').catch(() => []),
    asc('certificates list --output json').catch(() => []),
    asc('profiles list --output json').catch(() => []),
  ]);

  const bList = toList(bundleIds);
  const cList = toList(certs);
  const pList = toList(profiles);

  return `<h1 class="text-lg font-semibold text-neutral-900 mb-6">Code Signing</h1>
    <!-- Summary -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      ${summaryCard(bList.length, 'Bundle IDs')}
      ${summaryCard(cList.length, 'Certificates')}
      ${summaryCard(pList.length, 'Profiles')}
    </div>
    ${resourceTable('Certificates', cList, ['name', 'certificateType', 'platform', 'expirationDate'])}
    ${resourceTable('Provisioning Profiles', pList, ['name', 'profileType', 'profileState', 'expirationDate'])}
    ${resourceTable('Bundle IDs', bList, ['name', 'identifier', 'platform'])}
  `;
}

function summaryCard(count, label) {
  return `<div class="bg-white border border-neutral-200 rounded-xl p-4 text-center">
    <p class="text-2xl font-semibold text-neutral-800">${count}</p>
    <p class="text-xs text-neutral-400 mt-1">${label}</p>
  </div>`;
}

function resourceTable(title, list, keys) {
  if (!list.length) return `<div class="mb-4"><h3 class="text-sm font-semibold text-neutral-700 mb-2">${title}</h3><p class="text-xs text-neutral-400">None found.</p></div>`;

  const rows = list.slice(0, 15).map(item => `
    <tr class="border-t border-neutral-50 hover:bg-neutral-50/50">
      ${keys.map(k => {
        const v = item[k];
        const display = v == null ? '-' : String(v);
        const cls = k === 'expirationDate' ? 'text-neutral-400' : k === 'profileState' ? '' : 'text-neutral-700';
        const content = k === 'expirationDate' ? (timeAgo(display) || esc(display))
          : k === 'profileState' ? badge(display)
          : esc(display);
        return `<td class="px-5 py-2.5 text-xs ${cls} truncate max-w-[220px]">${content}</td>`;
      }).join('')}
    </tr>
  `).join('');

  return `<div class="mb-4">
    <h3 class="text-sm font-semibold text-neutral-700 mb-2">${title}</h3>
    ${table(keys.map(k => k.replace(/([A-Z])/g, ' $1').replace(/^./, c => c.toUpperCase())), rows)}
  </div>`;
}
