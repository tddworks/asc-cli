import type { Affordances } from '../shared/types.ts';

export enum BuildProcessingState {
  Processing = 'PROCESSING',
  Failed = 'FAILED',
  Invalid = 'INVALID',
  Valid = 'VALID',
}

export class Build {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly version: string,
    readonly preReleaseVersion: string,
    readonly processingState: BuildProcessingState,
    readonly expired: boolean,
    readonly usesNonExemptEncryption: boolean,
    readonly uploadedDate: string,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get isValid(): boolean {
    return this.processingState === BuildProcessingState.Valid;
  }

  get isProcessing(): boolean {
    return this.processingState === BuildProcessingState.Processing;
  }

  get isExpired(): boolean {
    return this.expired;
  }

  get isUsable(): boolean {
    return this.isValid && !this.expired;
  }

  // ── Capability Checks ──

  get canAddToTestFlight(): boolean {
    return 'addToTestFlight' in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.version} (${this.preReleaseVersion})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): Build {
    return new Build(
      json.id as string,
      (json.appId as string) ?? '',
      (json.version ?? json.buildNumber ?? '') as string,
      (json.preReleaseVersion ?? json.version ?? '') as string,
      (json.processingState as BuildProcessingState) ?? BuildProcessingState.Valid,
      (json.expired as boolean) ?? false,
      (json.usesNonExemptEncryption as boolean) ?? false,
      (json.uploadedDate as string) ?? '',
      (json.affordances as Affordances) ?? {},
    );
  }
}
