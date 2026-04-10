import type { Affordances } from '../shared/types.ts';

export class Review {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly title: string,
    readonly body: string,
    readonly rating: number,
    readonly territory: string,
    readonly reviewerNickname: string,
    readonly createdDate: string,
    readonly affordances: Affordances,
  ) {}

  get starDisplay(): string {
    return '★'.repeat(this.rating) + '☆'.repeat(5 - this.rating);
  }

  get canReply(): boolean {
    return 'respond' in this.affordances;
  }

  get hasResponse(): boolean {
    return 'getResponse' in this.affordances;
  }

  get isNegative(): boolean {
    return this.rating <= 2;
  }

  static fromJSON(json: Record<string, unknown>): Review {
    return new Review(
      json.id as string,
      json.appId as string,
      json.title as string,
      json.body as string,
      json.rating as number,
      json.territory as string,
      json.reviewerNickname as string,
      json.createdDate as string,
      (json.affordances as Affordances) ?? {},
    );
  }
}
