import { useState } from 'react';
import { useReviews } from '../Review.hooks.ts';
import { ReviewCard } from '../components/ReviewCard.tsx';
import type { Review } from '../Review.ts';

type Filter = 'all' | '5star' | 'needsReply';

function applyFilter(reviews: Review[], filter: Filter): Review[] {
  switch (filter) {
    case '5star': return reviews.filter((r) => r.rating === 5);
    case 'needsReply': return reviews.filter((r) => r.canReply && !r.hasResponse);
    default: return reviews;
  }
}

export default function ReviewList({ appId = 'app-1' }: { appId?: string }) {
  const { reviews, loading, error } = useReviews(appId);
  const [filter, setFilter] = useState<Filter>('all');

  if (loading) return <div className="spinner">Loading reviews...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  const filtered = applyFilter(reviews, filter);

  return (
    <div>
      <h2>Customer Reviews</h2>
      <div style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
        {([['all', 'All'], ['5star', '5 Stars'], ['needsReply', 'Needs Reply']] as [Filter, string][]).map(([f, label]) => (
          <button
            key={f}
            className="affordance-btn"
            onClick={() => setFilter(f)}
            style={filter === f ? { background: 'var(--accent)', color: 'white', borderColor: 'var(--accent)' } : {}}
          >
            {label}
          </button>
        ))}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {filtered.map((r) => <ReviewCard key={r.id} review={r} />)}
      </div>
    </div>
  );
}
