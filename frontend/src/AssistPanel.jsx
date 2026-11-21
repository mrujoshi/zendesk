import { useEffect, useState } from 'react';
import { api, timeAgo } from './api.js';
import { Icon, Skeleton } from './ui.jsx';

// AI support assistant (staff only): GET /api/tickets/{id}/assist
// -> { category, summary, sentiment, sentiment_reason, confidence, steps[], suggested_reply, source, model }
// source "offline" means no AI key is configured on the server and the result is a rule-based estimate.
export default function AssistPanel({ ticketId, closed, busy, onEdit, onSend }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const [done, setDone] = useState({}); // checked steps (local to this view)

  async function load(refresh = false) {
    setLoading(true);
    setError(null);
    try {
      const d = await api(`/tickets/${ticketId}/assist${refresh ? '?refresh=true' : ''}`);
      setData(d);
      setDone({});
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [ticketId]);

  const offline = data?.source === 'offline';

  return (
    <div className="card assist" aria-busy={loading}>
      <div className="card-head assist-head">
        <Icon name="sparkles" />
        <span className="assist-title">AI assistant</span>
        {data && !loading && (
          <span className="muted small" title={data.model ?? 'rule-based estimate'}>
            {offline ? 'Offline estimate' : data.cached ? `Generated ${timeAgo(data.generated_at)}` : 'Just now'}
          </span>
        )}
        <button className="icon-btn" style={{ marginLeft: 'auto' }} disabled={loading} onClick={() => load(true)} title="Regenerate" aria-label="Regenerate">
          <Icon name="refresh" size={14} className={loading ? 'spin' : ''} />
        </button>
      </div>

      {loading && !data && <AssistSkeleton />}

      {error && (
        <div className="card-body">
          <div className="banner error" style={{ margin: 0 }}>
            <Icon name="alert" /> {error}
          </div>
          <button className="ghost" style={{ marginTop: 8 }} onClick={() => load(true)}>
            Try again
          </button>
        </div>
      )}

      {data && (
        <div className={`assist-body ${loading ? 'dim' : ''}`}>
          {offline && (
            <div className="assist-offline">
              <Icon name="alert" size={14} />
              <span>
                No AI key on the server, so this is a basic keyword estimate. Set <code>ANTHROPIC_API_KEY</code> for AI analysis.
              </span>
            </div>
          )}

          <section className="assist-section">
            <div className="assist-label">Summary</div>
            <div className="assist-category">{data.category}</div>
            <p className="assist-summary">{data.summary}</p>
          </section>

          <section className="assist-section">
            <div className="assist-row">
              <div className="assist-label">Customer sentiment</div>
              <SentimentBadge value={data.sentiment} />
            </div>
            <p className="muted small" style={{ margin: '6px 0 0' }}>
              {data.sentiment_reason}
            </p>
          </section>

          <section className="assist-section">
            <div className="assist-row">
              <div className="assist-label">Confidence</div>
              <strong className="small">{data.confidence}%</strong>
            </div>
            <div className="meter" role="meter" aria-valuenow={data.confidence} aria-valuemin={0} aria-valuemax={100} aria-label="Confidence">
              <div className="meter-fill" style={{ width: `${data.confidence}%` }} />
            </div>
          </section>

          <section className="assist-box">
            <div className="assist-box-title">Suggested troubleshooting</div>
            <div className="muted small">Step-by-step for the agent</div>
            <ul className="checklist">
              {data.steps.map((s, i) => (
                <li key={i}>
                  <label className={done[i] ? 'checked' : ''}>
                    <input type="checkbox" checked={!!done[i]} onChange={(e) => setDone({ ...done, [i]: e.target.checked })} />
                    <span>{s}</span>
                  </label>
                </li>
              ))}
            </ul>
            <div className="muted small">
              {Object.values(done).filter(Boolean).length} of {data.steps.length} done
            </div>
          </section>

          <section className="assist-box">
            <div className="assist-box-title">Suggested reply</div>
            <div className="reply-preview">{data.suggested_reply}</div>
            <div className="assist-actions">
              <button disabled={closed || busy} onClick={() => onEdit(data.suggested_reply)} title="Put it in the reply box to edit">
                <Icon name="message" size={14} /> Edit before sending
              </button>
              <button className="primary" disabled={closed || busy} onClick={() => onSend(data.suggested_reply)} title="Send this reply to the customer now">
                <Icon name="send" size={14} /> Send reply
              </button>
            </div>
            {closed && <div className="muted small">Ticket is closed, so replies are off.</div>}
          </section>
        </div>
      )}
    </div>
  );
}

const SENTIMENT_STYLE = {
  Angry: { cls: 'sent-angry', icon: 'flame' },
  Neutral: { cls: 'sent-neutral', icon: 'message' },
  Positive: { cls: 'sent-positive', icon: 'check' },
};

function SentimentBadge({ value }) {
  const s = SENTIMENT_STYLE[value] ?? SENTIMENT_STYLE.Neutral;
  return (
    <span className={`sentiment ${s.cls}`}>
      <Icon name={s.icon} size={12} /> {value}
    </span>
  );
}

function AssistSkeleton() {
  return (
    <div className="assist-body">
      <div className="assist-thinking">
        <Icon name="sparkles" size={14} className="pulse" /> Reading the conversation…
      </div>
      <Skeleton width="45%" height={12} />
      <Skeleton height={14} />
      <Skeleton width="80%" height={14} />
      <Skeleton height={10} style={{ marginTop: 8 }} />
      <Skeleton height={110} style={{ marginTop: 8, borderRadius: 10 }} />
      <Skeleton height={140} style={{ borderRadius: 10 }} />
    </div>
  );
}
