export type ReportCategory = 'sales' | 'finance' | 'analytics' | 'performance';

export class Report {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly description: string,
    readonly command: string,
    readonly category: ReportCategory,
  ) {}

  static fromJSON(json: Record<string, unknown>): Report {
    return new Report(
      json.id as string,
      json.name as string,
      json.description as string,
      json.command as string,
      json.category as ReportCategory,
    );
  }
}
