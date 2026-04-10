import type { Affordances } from '../shared/types.ts';

export class IrisApp {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly bundleId: string,
    readonly sku: string,
    readonly platforms: string[],
    readonly affordances: Affordances,
  ) {}

  static fromJSON(json: Record<string, unknown>): IrisApp {
    return new IrisApp(
      (json.id as string) ?? '',
      (json.name as string) ?? '',
      (json.bundleId as string) ?? '',
      (json.sku as string) ?? '',
      (json.platforms as string[]) ?? [],
      (json.affordances as Affordances) ?? {},
    );
  }
}
