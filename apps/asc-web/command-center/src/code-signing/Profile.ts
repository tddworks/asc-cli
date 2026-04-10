import type { Affordances } from '../shared/types.ts';

export type ProfileState = 'ACTIVE' | 'INVALID';

export class Profile {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly profileType: string,
    readonly profileState: ProfileState,
    readonly expirationDate: string,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get isActive(): boolean {
    return this.profileState === 'ACTIVE';
  }

  // ── Capability Checks ──

  get canDelete(): boolean {
    return 'delete' in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.profileType})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): Profile {
    return new Profile(
      json.id as string,
      json.name as string,
      json.profileType as string,
      json.profileState as ProfileState,
      json.expirationDate as string,
      (json.affordances as Affordances) ?? {},
    );
  }
}
