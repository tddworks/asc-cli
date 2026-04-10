import type { Affordances } from '../shared/types.ts';

export class App {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly bundleId: string,
    readonly sku: string,
    readonly primaryLocale: string,
    readonly isAvailableInNewTerritories: boolean,
    readonly affordances: Affordances,
    readonly contentRightsDeclaration?: string,
  ) {}

  // ── Semantic Booleans ──

  get hasContentRights(): boolean {
    return this.contentRightsDeclaration !== undefined;
  }

  // ── Capability Checks — from server affordances ──

  get canViewVersions(): boolean {
    return 'getVersions' in this.affordances;
  }

  get canViewBuilds(): boolean {
    return 'getBuilds' in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.bundleId})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): App {
    return new App(
      json.id as string,
      (json.name as string) ?? '',
      (json.bundleId as string) ?? '',
      (json.sku as string) ?? '',
      (json.primaryLocale as string) ?? 'en-US',
      (json.isAvailableInNewTerritories as boolean) ?? true,
      (json.affordances as Affordances) ?? {},
      json.contentRightsDeclaration as string | undefined,
    );
  }
}
