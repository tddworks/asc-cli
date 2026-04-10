import { apiClient } from '../shared/api-client.ts';
import { pluginRegistry } from './PluginRegistry.ts';

interface PluginManifest {
  name: string;
  slug: string;
  ui: string[];
}

export async function loadPlugins(): Promise<void> {
  const response = await apiClient.get<{ plugins: PluginManifest[] }>('/api/plugins');

  for (const manifest of response.plugins) {
    for (const scriptUrl of manifest.ui) {
      try {
        const module = await import(
          /* @vite-ignore */ `/api/plugins/${manifest.slug}/${scriptUrl}`
        );
        if (typeof module.registerPlugin === 'function') {
          const registration = module.registerPlugin();
          pluginRegistry.register(registration);
        }
      } catch (err) {
        console.warn(`Failed to load plugin ${manifest.name}:`, err);
      }
    }
  }
}
