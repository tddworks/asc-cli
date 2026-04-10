import { Review } from '../Review.ts';

interface Props {
  review: Review;
}

export function ReviewCard({ review }: Props) {
  return (
    <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
        <strong>{review.title}</strong>
        <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{review.createdDate}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
        <span style={{ color: '#F59E0B' }}>{review.starDisplay}</span>
        {review.territory && <span className="platform-badge">{review.territory}</span>}
      </div>
      <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 8 }}>{review.body}</p>
      <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 8 }}>{review.reviewerNickname}</div>
      <div style={{ display: 'flex', gap: 8 }}>
        {review.canReply && <button className="btn btn-primary btn-sm">Reply</button>}
        {review.hasResponse && <button className="btn btn-secondary btn-sm">View Response</button>}
      </div>
    </div>
  );
}
