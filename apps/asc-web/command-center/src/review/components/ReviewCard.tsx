import { Review } from '../Review.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  review: Review;
}

export function ReviewCard({ review }: Props) {
  return (
    <div className={`card ${review.isNegative ? 'card-negative' : ''}`}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <h3 style={{ margin: 0 }}>{review.title}</h3>
        <span className="badge">{review.territory}</span>
      </div>
      <div style={{ color: '#eab308', marginBottom: 8 }}>{review.starDisplay}</div>
      <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 8 }}>{review.body}</p>
      <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 8 }}>
        {review.reviewerNickname} &middot; {review.createdDate}
      </div>
      {review.hasResponse && <span className="badge badge-green">Responded</span>}
      <AffordanceBar affordances={review.affordances} />
    </div>
  );
}
