import { useEffect, useRef, useState } from 'react';
import { api, isStaff, STATUS_FLOW, timeAgo } from './api.js';
import { Avatar, Icon, Kbd, PriorityTag, Skeleton, SlaChip, StatusPill, useHotkeys, useToast } from './ui.jsx';

const STEPS = ['open', 'pending', 'solved', 'closed'];
const STEP_HELP = {
  open: 'Needs an agent',
  pending: 'Waiting on client',
  solved: 'Client can reopen',
  closed: 'Locked for good',
};

export default function TicketDetail({ id, user, agents, names, onChanged, onBack }) {
  const [ticket, setTicket] = useState(null);
  const [audit, setAudit] = useState([]);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [reply, setReply] = useState('');
  const [internal, setInternal] = useState(false);
  const replyRef = useRef(null);
  const threadEnd = useRef(null);
  const toast = useToast();

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

  // Keep the newest message in view.
  const msgCount = ticket?.messages.length ?? 0;
  useEffect(() => {
    if (msgCount) threadEnd.current?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }, [msgCount]);

  useHotkeys({ r: () => replyRef.current?.focus() }, []);

  // Wraps every mutation: busy state, toast on success, error toast on failure, reload after.
  async function mutate(fn, success) {
    setBusy(true);
    setError(null);
    try {
      await fn();
      if (success) toast(success);
      onChanged();
    } catch (e) {
      toast(e.message, 'error');
    } finally {
      await load();
      setBusy(false);
    }
  }

  const changeStatus = (status) =>
    mutate(() => api(`/tickets/${id}/status`, { method: 'PATCH', body: { status } }), `Status changed to ${status}`);
  const assign = (agentId) =>
    mutate(
      () => api(`/tickets/${id}/assign`, { method: 'POST', body: { agent_id: agentId } }),
      `Assigned to ${agentId === user.id ? 'you' : names.agent(agentId)}`
    );

  const sendReply = (e) => {
    e?.preventDefault();
    if (!reply.trim() || busy) return;
    const isNote = internal && staff;
    mutate(async () => {
      await api(`/tickets/${id}/messages`, {
        method: 'POST',
        body: { text: reply, visibility: isNote ? 'internal' : 'public' },
      });
      setReply('');
      setInternal(false);
    }, isNote ? 'Internal note added' : 'Reply sent');
  };

  if (!ticket) {
    return (
      <section className="detail">
        <div className="detail-inner">
          {error ? (
            <div className="banner error">
              <Icon name="alert" /> {error}
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <Skeleton width={120} height={12} />
              <Skeleton width="60%" height={24} />
              <Skeleton height={90} />
              <Skeleton height={240} />
            </div>
          )}
        </div>
      </section>
    );
  }

  const closed = ticket.status === 'closed';
  const moves = staff ? STATUS_FLOW[ticket.status] ?? [] : [];
  // The API only accepts active agents with role 'agent' for manual assignment.
  const assignable = agents.filter((a) => a.is_active && a.role === 'agent');
  const clientName = names.client(ticket.client_id);
  const authorName = (m) => (m.author_type === 'client' ? names.client(m.author_id) : names.agent(m.author_id));

  // What the API will do to the status when this reply is sent (rules.status_after_reply).
  let replyHint = null;
  if (!internal) {
    if (staff && ticket.status !== 'pending') replyHint = 'Sending moves the ticket to pending.';
    if (!staff && ticket.status !== 'open') replyHint = 'Replying reopens this ticket.';
  } else {
    replyHint = 'Only agents and admins can see internal notes.';
  }

  return (
    <section className="detail" aria-label={`Ticket ${ticket.id}`}>
      <div className="detail-inner">
        <button className="ghost back-btn" onClick={onBack}>
          <Icon name="arrowLeft" /> All tickets
        </button>

        <div className="detail-head">
          <div style={{ minWidth: 0 }}>
            <div className="detail-sub">
              <span>#{ticket.id}</span>
              <span>·</span>
              <Avatar name={clientName} size={20} />
              <span>{clientName}</span>
              <span>·</span>
              <span>opened {timeAgo(ticket.created_at)}</span>
            </div>
            <h1>{ticket.title}</h1>
          </div>
          <div className="head-badges">
            {ticket.is_escalated && (
              <span className="tag tag-escalated">
                <Icon name="flame" size={12} /> Escalated
              </span>
            )}
            <SlaChip ticket={ticket} />
          </div>
        </div>

        <div className="detail-grid">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16, minWidth: 0 }}>
            {/* status stepper: allowed moves are clickable (staff only) */}
            <div className="card">
              <div className="stepper" role="group" aria-label="Ticket status">
                {STEPS.map((s) => {
                  const current = s === ticket.status;
                  const can = moves.includes(s) && !busy;
                  return (
                    <button
                      key={s}
                      className={`step status-${s} ${current ? 'current' : ''} ${can ? 'can' : ''}`}
                      disabled={!can}
                      onClick={() => changeStatus(s)}
                      title={can ? `Move to ${s}` : current ? 'Current status' : STEP_HELP[s]}
                      aria-current={current ? 'step' : undefined}
                    >
                      <span className="step-dot">{current ? <Icon name="check" size={13} /> : null}</span>
                      <span className="step-label">{s}</span>
                      <span className="muted" style={{ fontSize: 11, fontWeight: 400 }}>
                        {STEP_HELP[s]}
                      </span>
                    </button>
                  );
                })}
              </div>
              {staff && moves.length > 0 && (
                <div className="step-hint">Click a dashed step to move the ticket there.</div>
              )}
              {!staff && (
                <div className="step-hint">The support team updates the status. Replying reopens a solved ticket.</div>
              )}
            </div>

            {/* conversation */}
            <div className="card">
              <div className="card-head">
                <Icon name="message" /> Conversation
                <span className="count">{ticket.messages.length + 1}</span>
              </div>
              <div className="thread">
                <Message
                  name={clientName}
                  when={ticket.created_at}
                  text={ticket.description}
                  side="from-requester first"
                  label="Original request"
                />
                {ticket.messages.map((m) => (
                  <Message
                    key={m.id}
                    name={authorName(m)}
                    when={m.created_at}
                    text={m.text}
                    side={`${m.author_type === 'client' ? 'from-requester' : 'from-agent'} ${m.visibility === 'internal' ? 'internal' : ''}`}
                    internal={m.visibility === 'internal'}
                  />
                ))}
                <div ref={threadEnd} />
              </div>

              {closed ? (
                <div className="closed-note">
                  <Icon name="lock" /> This ticket is closed. Replies are turned off.
                </div>
              ) : (
                <form className={`composer ${internal ? 'internal' : ''}`} onSubmit={sendReply}>
                  {staff && (
                    <div className="composer-tabs" role="tablist" aria-label="Reply type">
                      <button type="button" role="tab" aria-selected={!internal} className={!internal ? 'active' : ''} onClick={() => setInternal(false)}>
                        <Icon name="message" size={14} /> Public reply
                      </button>
                      <button type="button" role="tab" aria-selected={internal} className={internal ? 'active' : ''} onClick={() => setInternal(true)}>
                        <Icon name="lock" size={14} /> Internal note
                      </button>
                    </div>
                  )}
                  <textarea
                    ref={replyRef}
                    value={reply}
                    onChange={(e) => setReply(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) sendReply(e);
                      if (e.key === 'Escape') e.currentTarget.blur();
                    }}
                    placeholder={internal ? 'Write a note for your team…' : staff ? `Reply to ${clientName}…` : 'Write a reply to the support team…'}
                    rows={3}
                    aria-label="Reply"
                  />
                  <div className="composer-foot">
                    {replyHint && (
                      <span className="composer-hint">
                        <Icon name={internal ? 'eye' : 'zap'} size={13} />
                        {replyHint}
                      </span>
                    )}
                    <div className="spacer" />
                    <span className="composer-hint hide-sm">
                      <Kbd>⌘</Kbd>
                      <Kbd>Enter</Kbd>
                    </span>
                    <button className="primary" type="submit" disabled={busy || !reply.trim()}>
                      <Icon name="send" size={14} />
                      {busy ? 'Sending…' : internal ? 'Add note' : 'Send'}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>

          {/* side column: properties + audit */}
          <aside className="side" style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div className="card props">
              <div className="card-head">
                <Icon name="user" /> Details
              </div>
              <div className="prop">
                <span className="prop-label">Status</span>
                <span className="prop-value">
                  <StatusPill status={ticket.status} />
                </span>
              </div>
              <div className="prop">
                <span className="prop-label">Assignee</span>
                {staff && !closed ? (
                  <>
                    <select
                      value={ticket.agent_id ?? ''}
                      disabled={busy}
                      onChange={(e) => e.target.value && assign(Number(e.target.value))}
                      aria-label="Assignee"
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
                    {user.role === 'agent' && ticket.agent_id !== user.id && (
                      <button className="ghost" style={{ alignSelf: 'flex-start', padding: '4px 8px' }} disabled={busy} onClick={() => assign(user.id)}>
                        <Icon name="user" size={14} /> Assign to me
                      </button>
                    )}
                  </>
                ) : (
                  <span className="prop-value">
                    {ticket.agent_id ? (
                      <>
                        <Avatar name={names.agent(ticket.agent_id)} size={22} /> {names.agent(ticket.agent_id)}
                      </>
                    ) : (
                      <span className="muted">Waiting for an agent</span>
                    )}
                  </span>
                )}
              </div>
              <div className="prop">
                <span className="prop-label">Priority</span>
                <span className="prop-value">
                  <PriorityTag priority={ticket.priority} />
                </span>
              </div>
              <div className="prop">
                <span className="prop-label">Due</span>
                <span className="prop-value">
                  {ticket.due_at ? new Date(ticket.due_at).toLocaleString() : '—'}
                  <SlaChip ticket={ticket} />
                </span>
              </div>
              <div className="prop">
                <span className="prop-label">Requester</span>
                <span className="prop-value">
                  <Avatar name={clientName} size={22} /> {clientName}
                </span>
              </div>
              <div className="prop">
                <span className="prop-label">Last update</span>
                <span className="prop-value">{timeAgo(ticket.updated_at)}</span>
              </div>
            </div>

            {staff && (
              <div className="card">
                <div className="card-head">
                  <Icon name="history" /> Audit trail
                  <span className="count">{audit.length}</span>
                </div>
                {audit.length === 0 ? (
                  <div className="pad muted small">No changes recorded yet.</div>
                ) : (
                  <ul className="timeline">
                    {[...audit].reverse().map((e) => (
                      <li key={e.id}>
                        <strong>{actorName(e, names)}</strong> {describe(e, names)}
                        <time dateTime={e.created_at} title={new Date(e.created_at).toLocaleString()}>
                          {timeAgo(e.created_at)}
                        </time>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </aside>
        </div>
      </div>
    </section>
  );
}

function Message({ name, when, text, side, internal, label }) {
  return (
    <article className={`msg ${side}`}>
      <Avatar name={name} size={32} />
      <div className="msg-bubble">
        <div className="msg-meta">
          <strong>{name}</strong>
          {label && <span className="tag" style={{ background: 'var(--surface-3)', color: 'var(--text-2)' }}>{label}</span>}
          {internal && (
            <span className="tag tag-internal">
              <Icon name="lock" size={10} /> Internal
            </span>
          )}
          <span className="muted" title={new Date(when).toLocaleString()}>
            {timeAgo(when)}
          </span>
        </div>
        <p>{text}</p>
      </div>
    </article>
  );
}

function actorName(e, names) {
  if (e.actor_type === 'system' || e.actor_id == null) return 'System';
  return e.actor_type === 'client' ? names.client(e.actor_id) : names.agent(e.actor_id);
}

function describe(e, names) {
  const agent = (v) => (v ? names.agent(Number(v)) : 'nobody');
  switch (e.action) {
    case 'created':
      return 'opened the ticket';
    case 'assigned':
      return e.old_value ? `reassigned it from ${agent(e.old_value)} to ${agent(e.new_value)}` : `assigned it to ${agent(e.new_value)}`;
    case 'status':
      return `moved it from ${e.old_value} to ${e.new_value}`;
    case 'escalated':
      return `escalated it (${e.old_value} → ${e.new_value})`;
    default:
      return `${e.action} ${e.old_value ?? ''} → ${e.new_value ?? ''}`;
  }
}
