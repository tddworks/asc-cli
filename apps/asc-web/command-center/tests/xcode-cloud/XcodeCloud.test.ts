import { describe, it, expect } from 'vitest';
import { CiProduct } from '../../src/xcode-cloud/CiProduct.ts';
import { CiWorkflow } from '../../src/xcode-cloud/CiWorkflow.ts';

describe('CiProduct', () => {

  it('can list workflows when affordance is present', () => {
    const p = new CiProduct('p-1', 'My App', 'APP', 'app-1', {
      listWorkflows: 'asc xcode-cloud workflows list --product-id p-1',
    });
    expect(p.canListWorkflows).toBe(true);
  });

  it('cannot list workflows when affordance is missing', () => {
    const p = new CiProduct('p-1', 'My App', 'APP', 'app-1', {});
    expect(p.canListWorkflows).toBe(false);
  });

  it('has optional appId', () => {
    const p = new CiProduct('p-1', 'Framework', 'FRAMEWORK', undefined, {});
    expect(p.appId).toBeUndefined();
  });

  it('hydrates from API JSON', () => {
    const json = {
      id: 'p-1',
      name: 'My App',
      productType: 'APP',
      appId: 'app-1',
      affordances: { listWorkflows: 'asc xcode-cloud workflows list --product-id p-1' },
    };

    const p = CiProduct.fromJSON(json);

    expect(p.id).toBe('p-1');
    expect(p.name).toBe('My App');
    expect(p.productType).toBe('APP');
    expect(p.appId).toBe('app-1');
    expect(p.canListWorkflows).toBe(true);
  });

  it('hydrates with empty affordances when missing', () => {
    const json = { id: 'p-2', name: 'Lib', productType: 'FRAMEWORK' };
    const p = CiProduct.fromJSON(json);
    expect(p.affordances).toEqual({});
  });
});

describe('CiWorkflow', () => {

  it('can start build when affordance is present', () => {
    const w = new CiWorkflow('w-1', 'p-1', 'Release', true, false, {
      startBuild: 'asc xcode-cloud build-runs start --workflow-id w-1',
    });
    expect(w.canStartBuild).toBe(true);
  });

  it('cannot start build when affordance is missing', () => {
    const w = new CiWorkflow('w-1', 'p-1', 'Release', true, false, {});
    expect(w.canStartBuild).toBe(false);
  });

  it('can list build runs when affordance is present', () => {
    const w = new CiWorkflow('w-1', 'p-1', 'Release', true, false, {
      listBuildRuns: 'asc xcode-cloud build-runs list --workflow-id w-1',
    });
    expect(w.canListBuildRuns).toBe(true);
  });

  it('reports enabled and locked state', () => {
    const w = new CiWorkflow('w-1', 'p-1', 'Release', false, true, {});
    expect(w.isEnabled).toBe(false);
    expect(w.isLockedForEditing).toBe(true);
  });

  it('hydrates from API JSON', () => {
    const json = {
      id: 'w-1',
      productId: 'p-1',
      name: 'Release',
      isEnabled: true,
      isLockedForEditing: false,
      affordances: {
        startBuild: 'asc xcode-cloud build-runs start --workflow-id w-1',
        listBuildRuns: 'asc xcode-cloud build-runs list --workflow-id w-1',
      },
    };

    const w = CiWorkflow.fromJSON(json);

    expect(w.id).toBe('w-1');
    expect(w.productId).toBe('p-1');
    expect(w.name).toBe('Release');
    expect(w.isEnabled).toBe(true);
    expect(w.isLockedForEditing).toBe(false);
    expect(w.canStartBuild).toBe(true);
    expect(w.canListBuildRuns).toBe(true);
  });

  it('hydrates with empty affordances when missing', () => {
    const json = {
      id: 'w-2', productId: 'p-1', name: 'Test',
      isEnabled: true, isLockedForEditing: false,
    };
    const w = CiWorkflow.fromJSON(json);
    expect(w.affordances).toEqual({});
    expect(w.canStartBuild).toBe(false);
  });
});
