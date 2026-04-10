import { describe, it, expect, beforeEach } from 'vitest';
import { PluginRegistry } from '../../src/plugin/PluginRegistry.ts';
import type { PluginRegistration } from '../../src/plugin/Plugin.ts';

function dummyComponent() {
  return Promise.resolve({ default: () => null });
}

describe('PluginRegistry', () => {
  let registry: PluginRegistry;

  beforeEach(() => {
    registry = new PluginRegistry();
  });

  it('starts empty', () => {
    expect(registry.getAll()).toEqual([]);
    expect(registry.getPages()).toEqual([]);
    expect(registry.getSidebarItems()).toEqual([]);
  });

  it('registers a plugin and retrieves its pages', () => {
    registry.register({
      id: 'test-plugin',
      name: 'Test',
      version: '1.0.0',
      pages: [{ path: '/test', title: 'Test', component: dummyComponent }],
    });

    expect(registry.getPages()).toHaveLength(1);
    expect(registry.getPages()[0].path).toBe('/test');
  });

  it('returns widgets for a specific slot sorted by priority', () => {
    const widgetA = { slot: 'dashboard.top', component: dummyComponent, priority: 50 };
    const widgetB = { slot: 'dashboard.top', component: dummyComponent, priority: 10 };
    const widgetC = { slot: 'other.slot', component: dummyComponent };

    registry.register({ id: 'p1', name: 'P1', version: '1.0', widgets: [widgetA, widgetC] });
    registry.register({ id: 'p2', name: 'P2', version: '1.0', widgets: [widgetB] });

    const dashboardWidgets = registry.getWidgets('dashboard.top');
    expect(dashboardWidgets).toHaveLength(2);
    expect(dashboardWidgets[0].priority).toBe(10);
    expect(dashboardWidgets[1].priority).toBe(50);
  });

  it('returns empty array for slot with no widgets', () => {
    expect(registry.getWidgets('nonexistent')).toEqual([]);
  });

  it('aggregates sidebar items from all plugins', () => {
    registry.register({
      id: 'p1', name: 'P1', version: '1.0',
      sidebarItems: [{ id: 's1', label: 'Item 1', section: 'plugins', path: '/p1' }],
    });
    registry.register({
      id: 'p2', name: 'P2', version: '1.0',
      sidebarItems: [{ id: 's2', label: 'Item 2', section: 'plugins', path: '/p2' }],
    });

    expect(registry.getSidebarItems()).toHaveLength(2);
  });

  it('overwrites when registering same plugin id twice', () => {
    registry.register({
      id: 'p1', name: 'P1', version: '1.0',
      pages: [{ path: '/a', title: 'A', component: dummyComponent }],
    });
    registry.register({
      id: 'p1', name: 'P1 Updated', version: '2.0',
      pages: [{ path: '/b', title: 'B', component: dummyComponent }],
    });

    expect(registry.getAll()).toHaveLength(1);
    expect(registry.getPages()[0].path).toBe('/b');
  });

  it('checks if plugin is registered', () => {
    registry.register({ id: 'p1', name: 'P1', version: '1.0' });

    expect(registry.has('p1')).toBe(true);
    expect(registry.has('p2')).toBe(false);
  });

  it('uses default priority 100 when not specified', () => {
    const widgetA = { slot: 'top', component: dummyComponent, priority: 50 };
    const widgetB = { slot: 'top', component: dummyComponent }; // default 100

    registry.register({ id: 'p1', name: 'P1', version: '1.0', widgets: [widgetB] });
    registry.register({ id: 'p2', name: 'P2', version: '1.0', widgets: [widgetA] });

    const widgets = registry.getWidgets('top');
    expect(widgets[0].priority).toBe(50);
    expect(widgets[1].priority).toBeUndefined();
  });
});
