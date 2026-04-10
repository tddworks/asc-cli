import { describe, it, expect } from 'vitest';
import { App } from '../../src/app/App.ts';

describe('App', () => {

  // ── Display ──

  it('formats display name as name (bundleId)', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});
    expect(app.displayName).toBe('WeatherApp (com.example.weather)');
  });

  // ── Semantic Booleans ──

  it('has content rights when declaration is present', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {}, 'USES_THIRD_PARTY_CONTENT');
    expect(app.hasContentRights).toBe(true);
  });

  it('does not have content rights when declaration is undefined', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {});
    expect(app.hasContentRights).toBe(false);
  });

  // ── Capability Checks (from API affordances) ──

  it('can view versions when server provides affordance', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {
      getVersions: 'asc versions list --app-id a-1',
    });
    expect(app.canViewVersions).toBe(true);
  });

  it('cannot view versions when server omits affordance', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {});
    expect(app.canViewVersions).toBe(false);
  });

  it('can view builds when server provides affordance', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {
      getBuilds: 'asc builds list --app-id a-1',
    });
    expect(app.canViewBuilds).toBe(true);
  });

  // ── Hydration ──

  it('hydrates from API JSON', () => {
    const json = {
      id: 'a-1',
      name: 'WeatherApp',
      bundleId: 'com.example.weather',
      sku: 'SKU001',
      primaryLocale: 'en-US',
      isAvailableInNewTerritories: true,
      affordances: { getVersions: 'asc versions list --app-id a-1' },
      contentRightsDeclaration: 'USES_THIRD_PARTY_CONTENT',
    };

    const app = App.fromJSON(json);

    expect(app.id).toBe('a-1');
    expect(app.name).toBe('WeatherApp');
    expect(app.bundleId).toBe('com.example.weather');
    expect(app.canViewVersions).toBe(true);
    expect(app.hasContentRights).toBe(true);
    expect(app.displayName).toBe('WeatherApp (com.example.weather)');
  });

  it('hydrates with empty affordances when missing from JSON', () => {
    const json = {
      id: 'a-1',
      name: 'App',
      bundleId: 'com.x',
      sku: 'SKU',
      primaryLocale: 'en-US',
      isAvailableInNewTerritories: false,
    };

    const app = App.fromJSON(json);

    expect(app.affordances).toEqual({});
    expect(app.canViewVersions).toBe(false);
    expect(app.contentRightsDeclaration).toBeUndefined();
  });
});
