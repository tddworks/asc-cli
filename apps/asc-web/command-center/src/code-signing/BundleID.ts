import type { Affordances } from '../shared/types.ts';

export class BundleID {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly identifier: string,
    readonly platform: string,
    readonly seedId: string,
    readonly affordances: Affordances,
  ) {}

  // ── Capability Checks ──

  get canDelete(): boolean {
    return 'delete' in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.identifier})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): BundleID {
    return new BundleID(
      json.id as string,
      json.name as string,
      json.identifier as string,
      json.platform as string,
      json.seedId as string,
      (json.affordances as Affordances) ?? {},
    );
  }
}
