import type { Affordances } from '../shared/types.ts';

export class User {
  constructor(
    readonly id: string,
    readonly firstName: string,
    readonly lastName: string,
    readonly email: string,
    readonly roles: string[],
    readonly allAppsVisible: boolean,
    readonly provisioningAllowed: boolean,
    readonly affordances: Affordances,
  ) {}

  get displayName(): string { return `${this.firstName} ${this.lastName}`; }

  static fromJSON(json: Record<string, unknown>): User {
    return new User(
      (json.id as string) ?? '',
      (json.firstName as string) ?? '',
      (json.lastName as string) ?? '',
      (json.email as string) ?? '',
      (json.roles as string[]) ?? [],
      (json.allAppsVisible as boolean) ?? false,
      (json.provisioningAllowed as boolean) ?? false,
      (json.affordances as Affordances) ?? {},
    );
  }
}
