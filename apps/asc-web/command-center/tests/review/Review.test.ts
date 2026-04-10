import { describe, it, expect } from 'vitest';
import { Review } from '../../src/review/Review.ts';

describe('Review', () => {

  it('formats star rating display', () => {
    const r = new Review('r-1', 'app-1', 'Great app', 'Love it!', 5, 'US', 'John', '2024-03-15', {});
    expect(r.starDisplay).toBe('★★★★★');
  });

  it('formats partial star rating', () => {
    const r = new Review('r-1', 'app-1', 'OK', 'Meh', 3, 'US', 'Jane', '2024-03-15', {});
    expect(r.starDisplay).toBe('★★★☆☆');
  });

  it('can reply when server provides respond affordance', () => {
    const r = new Review('r-1', 'app-1', 'Bug', 'Crash', 1, 'US', 'User', '2024-03-15', {
      respond: 'asc reviews respond --review-id r-1',
    });
    expect(r.canReply).toBe(true);
  });

  it('cannot reply when affordance missing', () => {
    const r = new Review('r-1', 'app-1', 'Bug', 'Crash', 1, 'US', 'User', '2024-03-15', {});
    expect(r.canReply).toBe(false);
  });

  it('has response when server provides getResponse affordance', () => {
    const r = new Review('r-1', 'app-1', 'Bug', 'Crash', 1, 'US', 'User', '2024-03-15', {
      getResponse: 'asc reviews response --review-id r-1',
    });
    expect(r.hasResponse).toBe(true);
  });

  it('identifies negative reviews (1-2 stars)', () => {
    const r1 = new Review('r-1', 'app-1', 'Bad', 'Terrible', 1, 'US', 'U', '2024-01-01', {});
    const r2 = new Review('r-2', 'app-1', 'OK', 'Fine', 3, 'US', 'U', '2024-01-01', {});
    expect(r1.isNegative).toBe(true);
    expect(r2.isNegative).toBe(false);
  });

  it('hydrates from API JSON', () => {
    const json = {
      id: 'r-1', appId: 'app-1', title: 'Great', body: 'Love it',
      rating: 5, territory: 'US', reviewerNickname: 'John',
      createdDate: '2024-03-15',
      affordances: { respond: 'asc reviews respond --review-id r-1' },
    };

    const r = Review.fromJSON(json);

    expect(r.id).toBe('r-1');
    expect(r.rating).toBe(5);
    expect(r.canReply).toBe(true);
    expect(r.starDisplay).toBe('★★★★★');
  });
});
