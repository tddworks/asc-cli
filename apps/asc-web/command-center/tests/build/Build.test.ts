import { describe, it, expect } from 'vitest';
import { Build, BuildProcessingState } from '../../src/build/Build.ts';

describe('Build', () => {

  // ── Semantic Booleans ──

  it('is usable when usesNonExemptEncryption is false', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, false, false, '2024-01-15', {});
    expect(b.isUsable).toBe(true);
  });

  it('is not usable when expired', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, true, false, '2024-01-15', {});
    expect(b.isUsable).toBe(false);
  });

  it('is not usable when processing state is invalid', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Invalid, false, false, '2024-01-15', {});
    expect(b.isUsable).toBe(false);
  });

  it('is processing when state is PROCESSING', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Processing, false, false, '2024-01-15', {});
    expect(b.isProcessing).toBe(true);
    expect(b.isValid).toBe(false);
  });

  it('is valid when state is VALID', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, false, false, '2024-01-15', {});
    expect(b.isValid).toBe(true);
  });

  it('is expired', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, true, false, '2024-01-15', {});
    expect(b.isExpired).toBe(true);
  });

  // ── Capability Checks ──

  it('can add to TestFlight when server provides affordance', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, false, false, '2024-01-15', {
      addToTestFlight: 'asc testflight add --build-id b-1',
    });
    expect(b.canAddToTestFlight).toBe(true);
  });

  it('cannot add to TestFlight when affordance missing', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, false, false, '2024-01-15', {});
    expect(b.canAddToTestFlight).toBe(false);
  });

  // ── Display ──

  it('formats display as build number (version)', () => {
    const b = new Build('b-1', 'app-1', '100', '2.0', BuildProcessingState.Valid, false, false, '2024-01-15', {});
    expect(b.displayName).toBe('100 (2.0)');
  });

  // ── Hydration ──

  it('hydrates from API JSON', () => {
    const json = {
      id: 'b-1',
      appId: 'app-1',
      version: '100',
      preReleaseVersion: '2.0',
      processingState: 'VALID',
      expired: false,
      usesNonExemptEncryption: false,
      uploadedDate: '2024-01-15',
      affordances: { addToTestFlight: 'asc testflight add --build-id b-1' },
    };

    const b = Build.fromJSON(json);

    expect(b.id).toBe('b-1');
    expect(b.appId).toBe('app-1');
    expect(b.isValid).toBe(true);
    expect(b.isUsable).toBe(true);
    expect(b.canAddToTestFlight).toBe(true);
    expect(b.displayName).toBe('100 (2.0)');
  });

  it('hydrates with empty affordances when missing', () => {
    const json = {
      id: 'b-1', appId: 'app-1', version: '50', preReleaseVersion: '1.0',
      processingState: 'PROCESSING', expired: false, usesNonExemptEncryption: false,
      uploadedDate: '2024-01-10',
    };

    const b = Build.fromJSON(json);
    expect(b.affordances).toEqual({});
    expect(b.isProcessing).toBe(true);
  });
});
