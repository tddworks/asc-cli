import type { Affordances } from '../shared/types.ts';

export type CertificateStatus = 'VALID' | 'EXPIRED' | 'REVOKED';

export class Certificate {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly certificateType: string,
    readonly serialNumber: string,
    readonly expirationDate: string,
    readonly status: CertificateStatus,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get isValid(): boolean {
    return this.status === 'VALID';
  }

  get isExpired(): boolean {
    return this.status === 'EXPIRED';
  }

  // ── Capability Checks ──

  get canRevoke(): boolean {
    return 'revoke' in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.certificateType})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): Certificate {
    return new Certificate(
      json.id as string,
      json.name as string,
      json.certificateType as string,
      json.serialNumber as string,
      json.expirationDate as string,
      json.status as CertificateStatus,
      (json.affordances as Affordances) ?? {},
    );
  }
}
