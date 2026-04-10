import type { Affordances } from '../shared/types.ts';

export class BetaGroup {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly name: string,
    readonly isInternal: boolean,
    readonly publicLinkEnabled: boolean,
    readonly publicLink: string | undefined,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get hasPublicLink(): boolean {
    return this.publicLink !== undefined && this.publicLinkEnabled;
  }

  // ── Capability Checks ──

  get canAddTester(): boolean {
    return 'addTester' in this.affordances;
  }

  get canListTesters(): boolean {
    return 'listTesters' in this.affordances;
  }

  // ── Display ──

  get typeBadge(): string {
    return this.isInternal ? 'Internal' : 'External';
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): BetaGroup {
    return new BetaGroup(
      json.id as string,
      json.appId as string,
      json.name as string,
      json.isInternal as boolean,
      json.publicLinkEnabled as boolean,
      json.publicLink as string | undefined,
      (json.affordances as Affordances) ?? {},
    );
  }
}
