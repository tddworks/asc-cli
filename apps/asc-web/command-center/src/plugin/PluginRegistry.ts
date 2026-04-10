import type { PluginRegistration, PluginPage, PluginSidebarItem, PluginWidget } from './Plugin.ts';

export class PluginRegistry {
  private plugins: Map<string, PluginRegistration> = new Map();

  register(plugin: PluginRegistration): void {
    this.plugins.set(plugin.id, plugin);
  }

  getPages(): PluginPage[] {
    return [...this.plugins.values()].flatMap((p) => p.pages ?? []);
  }

  getSidebarItems(): PluginSidebarItem[] {
    return [...this.plugins.values()].flatMap((p) => p.sidebarItems ?? []);
  }

  getWidgets(slot: string): PluginWidget[] {
    return [...this.plugins.values()]
      .flatMap((p) => p.widgets ?? [])
      .filter((w) => w.slot === slot)
      .sort((a, b) => (a.priority ?? 100) - (b.priority ?? 100));
  }

  getAll(): PluginRegistration[] {
    return [...this.plugins.values()];
  }

  has(id: string): boolean {
    return this.plugins.has(id);
  }
}

export const pluginRegistry = new PluginRegistry();
