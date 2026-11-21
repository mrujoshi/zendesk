import { useEffect, useState } from 'react';
import { api, isActive, isOverdue, isStaff, STATUS_FLOW, timeAgo } from './api.js';

export default function TicketDetail({ id, user, agents, names, onChanged }) {
  const [ticket, setTicket] = useState(null);
  const [audit, setAudit] = useState([]);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [reply, setReply] = useState('');
  const [internal, setInternal] = useState(false);

  const staff = isStaff(user);

  async function load() {
    try {
      // GET /tickets/{id} includes messages. The audit trail is staff-only.
      const [t, a] = await Promise.all([
        api(`/tickets/${id}`),
        staff ? api(`/tickets/${id}/audit`) : Promise.resolve([]),
      ]);
      setTicket(t);
      setAudit(a);
    } catch (e) {
      setError(e.message);
    }
  }

  useEffect(() => {
    load();
  }, [id]);

  // Wraps every mutation: shows busy state, surfaces API errors, reloads after.
  async function mutate(fn) {
    setBusy(true);
    setError(null);
    try {
      await fn();
      onChanged();
    } catch (e) {
      setError(e.message);
    } finally {
      await load();
      setBusy(false);
    }
  }

  const changeStatus = (status) =>
    mutate(() => api(`/tickets/${id}/status`, { method: 'PATCH', body: { status } }));
  const assign = (agentId) =>
    mutate(() => api(`/tickets/${id}/assign`, { method: 'POST', body: { agent_id: agentId } }));

  const sendReply = (e) => {
    e.preventDefault();
    if (!reply.trim()) return;
    mutate(async () => {
      await api(`/tickets/${id}/messages`, {
        method: 'POST',
        body: { text: reply, visibility: internal && staff ? 'internal' : 'public' },
      });
      setReply('');
      setInternal(false);
    });
  };

  if (!ticket) {
    return (
      <section className="detail">
        {error ? <div className="banner error">{error}</div> : <div className="muted pad">Loading…</div>}
      </section>
    );
  }

  const closed = ticket.status === 'closed';
  const moves = STATUS_FLOW[ticket.status] ?? [];
  // The API only accepts active agents with role 'agent' for manual assignment.
  const assignable = agents.filter((a) => a.is_active && a.role === 'agent');
  const overdue = isOverdue(ticket);

  // What the API will do to the status when this reply is sent (rules.status_after_reply).
  let replyHint = null;
  if (!internal) {
    if (staff && ticket.status !== 'pending') replyHint = 'A public reply sets the status to pending (waiting on client).';
    if (!staff && ticket.status !== 'open') replyHint = 'Replying reopens this ticket for the support team.';
  }

  const authorName = (m) => (m.author_type === 'client' ? names.client(m.author_id) : names.agent(m.author_id));

  return (
    <section className="detail" aria-label={`Ticket ${ticket.id}`}>
      <div className="detail-head">
        <div>
          <div className="muted small">
            #{ticket.id} · from {names.client(ticket.client_id)} · created {timeAgo(ticket.created_at)}
          </div>
          <h1>{ticket.title}</h1>
        </div>
        <div className="head-badges">
          {ticket.is_escalated && <span className="badge escalated">Escalated</span>}
          {overdue && <span className="badge breach">Overdue</span>}
        </div>
      </div>

      <div className="controls">
        <label>
          Status
          {staff ? (
            <select
              value={ticket.status}
              disabled={busy || moves.length === 0}
              onChange={(e) => changeStatus(e.target.value)}
            >
              <option value={ticket.status}>{ticket.status}</option>
              {moves.map((s) => (
                <option key={s} value={s}>
                  → {s}
                </option>
              ))}
            </select>
          ) : (
            <span className={`badge status-${ticket.status}`}>{ticket.status}</span>
          )}
        </label>

        <label>
          Assignee
          {staff && !closed ? (
            <select
              value={ticket.agent_id ?? ''}
              disabled={busy}
              onChange={(e) => e.target.value && assign(Number(e.target.value))}
            >
              {ticket.agent_id == null && <option value="">Unassigned</option>}
              {/* keep the current assignee visible even if they're an admin (escalation) */}
              {ticket.agent_id != null && !assignable.some((a) => a.id === ticket.agent_id) && (
                <option value={ticket.agent_id}>{names.agent(ticket.agent_id)}</option>
              )}
              {assignable.map((a) => (
                <option key={a.id} value={a.id}>
                  {a.name}
                </option>
              ))}
            </select>
          ) : (
            <span className="plain-value">{ticket.agent_id ? names.agent(ticket.agent_id) : 'Unassigned'}</span>
          )}
        </label>

        {user.role === 'agent' && !closed && ticket.agent_id !== user.id && (
          <button disabled={busy} onClick={() => assign(user.id)}>
            Assign to me
          </button>
        )}

        <label>
          Priority
          <span className={`prio prio-${ticket.priority} plain-value`}>{ticket.priority}</span>
        </label>

        <div className="sla">
          <span className="muted small">Due</span>
          <span className={overdue ? 'breach-text' : ''}>
            {isActive(ticket) && ticket.due_at ? timeAgo(ticket.due_at) : '—'}
          </span>
        </div>
      </div>

      {!staff && <div className="banner info">You can reply here. The support team manages status and assignment.</div>}
      {error && <div className="banner error">{error}</div>}

      <div className="thread">
        <article className="msg from-requester">
          <div className="msg-meta">
            <strong>{names.client(ticket.client_id)}</strong>{' '}
            <span className="muted small">{timeAgo(ticket.created_at)}</span>
          </div>
          <p>{ticket.description}</p>
        </article>
        {ticket.messages.map((m) => (
          <article
            key={m.id}
            className={`msg ${m.author_type === 'client' ? 'from-requester' : 'from-agent'} ${m.visibility === 'internal' ? 'internal' : ''}`}
          >
            <div className="msg-meta">
              <strong>{authorName(m)}</strong>
              {m.visibility === 'internal' && <span className="badge internal-badge">internal note</span>}
              <span className="muted small">{timeAgo(m.created_at)}</span>
            </div>
            <p>{m.text}</p>
          </article>
        ))}
      </div>

      {closed ? (
        <div className="muted pad">This ticket is closed. Replies are disabled.</div>
      ) : (
        <form className={`reply ${internal ? 'internal' : ''}`} onSubmit={sendReply}>
          <textarea
            value={reply}
            onChange={(e) => setReply(e.target.value)}
            placeholder={internal ? 'Internal note (only agents see this)…' : 'Write a reply…'}
            rows={3}
            aria-label="Reply"
          />
          <div className="reply-actions">
            {staff && (
              <label className="check">
                <input type="checkbox" checked={internal} onChange={(e) => setInternal(e.target.checked)} />
                Internal note
              </label>
            )}
            {replyHint && <span className="muted small hint">{replyHint}</span>}
            <div className="spacer" />
            <button className="primary" type="submit" disabled={busy || !reply.trim()}>
              {busy ? 'Saving…' : 'Send'}
            </button>
          </div>
        </form>
      )}

      {staff && (
        <details className="activity">
          <summary>Audit trail ({audit.length})</summary>
          <ul>
            {audit.map((e) => (
              <li key={e.id}>
                <span className="muted small">{new Date(e.created_at).toLocaleString()}</span>{' '}
                <strong>{actorName(e, names)}</strong> {describe(e, names)}
              </li>
            ))}
          </ul>
        </details>
      )}
    </section>
  );
}

function actorName(e, names) {
  if (e.actor_type === 'system' || e.actor_id == null) return 'system';
  return e.actor_type === 'client' ? names.client(e.actor_id) : names.agent(e.actor_id);
}

function describe(e, names) {
  const agent = (v) => (v ? names.agent(Number(v)) : 'nobody');
  switch (e.action) {
    case 'created':
      return 'created the ticket';
    case 'assigned':
      return e.old_value ? `reassigned it from ${agent(e.old_value)} to ${agent(e.new_value)}` : `assigned it to ${agent(e.new_value)}`;
    case 'status':
      return `changed status from ${e.old_value} to ${e.new_value}`;
    case 'escalated':
      return `escalated it (priority ${e.old_value} → ${e.new_value})`;
    default:
      return `${e.action} ${e.old_value ?? ''} → ${e.new_value ?? ''}`;
  }
}
