import { useEffect, useState } from 'react';
import { api, isActive, isOverdue, isStaff, PRIORITIES, timeAgo } from './api.js';

// Each tab = query params for GET /api/tickets (status/priority/escalated/agent_id), plus an optional
// client-side filter. The API takes one status at a time, so "Active" fetches all and keeps open+pending.
// Clients get the same endpoint; the API scopes it to their own tickets.
const STAFF_TABS = [
  { key: 'active', label: 'Open & pending', params: () => ({}), keep: isActive },
  { key: 'mine', label: 'My tickets', params: (u) => ({ agent_id: u.id }), keep: isActive },
  { key: 'escalated', label: 'Escalated', params: () => ({ escalated: 'true' }) },
  { key: 'solved', label: 'Solved', params: () => ({ status: 'solved' }) },
  { key: 'closed', label: 'Closed', params: () => ({ status: 'closed' }) },
  { key: 'all', label: 'All', params: () => ({}) },
];

const CLIENT_TABS = [
  { key: 'active', label: 'Open & pending', params: () => ({}), keep: isActive },
  { key: 'solved', label: 'Solved', params: () => ({ status: 'solved' }) },
  { key: 'closed', label: 'Closed', params: () => ({ status: 'closed' }) },
  { key: 'all', label: 'All', params: () => ({}) },
];

const PAGE_SIZE = 100; // API maximum
const POLL_MS = 10_000; // live updates: re-fetch the list every 10s

export default function TicketList({ user, names, selectedId, onSelect, refreshKey }) {
  const staff = isStaff(user);
  const tabs = staff ? STAFF_TABS : CLIENT_TABS;
  const [tab, setTab] = useState('active');
  const [priority, setPriority] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(null); // {items, total} ; null = loading
  const [error, setError] = useState(null);
  const [notice, setNotice] = useState(null);
  const [reload, setReload] = useState(0);

  const current = tabs.find((t) => t.key === tab);

  useEffect(() => {
    let cancelled = false;
    const params = { ...current.params(user), limit: PAGE_SIZE };
    if (priority) params.priority = priority;
    const qs = new URLSearchParams(params).toString();

    const load = () =>
      api(`/tickets?${qs}`)
        .then((data) => {
          if (!cancelled) {
            setPage(data);
            setError(null);
          }
        })
        .catch((e) => !cancelled && setError(e.message));

    setPage(null);
    load();
    const timer = setInterval(load, POLL_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, [tab, priority, user.id, refreshKey, reload]);

  // Search is client-side: the API has no text search parameter.
  const q = search.trim().toLowerCase();
  const tickets = page?.items
    .filter((t) => !current.keep || current.keep(t))
    .filter((t) => !q || t.title.toLowerCase().includes(q) || t.description.toLowerCase().includes(q));

  async function runEscalation() {
    setNotice(null);
    try {
      const { escalated } = await api('/escalations/run', { method: 'POST' });
      setNotice(escalated.length ? `Escalated #${escalated.join(', #')}` : 'Nothing overdue to escalate.');
      setReload((n) => n + 1);
    } catch (e) {
      setError(e.message);
    }
  }

  return (
    <section className="list" aria-label="Tickets">
      <div className="tabs" role="tablist">
        {tabs.map((t) => (
          <button
            key={t.key}
            role="tab"
            aria-selected={tab === t.key}
            className={tab === t.key ? 'active' : ''}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>
      <div className="filters">
        <input
          type="search"
          placeholder="Search title or description…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search tickets"
        />
        <select value={priority} onChange={(e) => setPriority(e.target.value)} aria-label="Filter by priority">
          <option value="">Any priority</option>
          {[...PRIORITIES].reverse().map((p) => (
            <option key={p.value} value={p.value}>
              {p.label}
            </option>
          ))}
        </select>
      </div>

      {user.role === 'admin' && (
        <div className="filters">
          <button className="danger" onClick={runEscalation} title="The server also runs this every 60 seconds">
            Run escalation now
          </button>
          {notice && <span className="muted small">{notice}</span>}
        </div>
      )}

      {error && <div className="banner error">{error}</div>}
      {page === null && !error && <div className="muted pad">Loading tickets…</div>}
      {tickets?.length === 0 && <div className="muted pad">No tickets match this view.</div>}
      {page && page.total > page.items.length && (
        <div className="muted small pad">
          Showing the newest {page.items.length} of {page.total}.
        </div>
      )}

      <ul className="ticket-rows">
        {tickets?.map((t) => (
          <li key={t.id}>
            <button className={`row ${t.id === selectedId ? 'selected' : ''}`} onClick={() => onSelect(t.id)}>
              <div className="row-top">
                <span className={`badge status-${t.status}`}>{t.status}</span>
                <span className={`prio prio-${t.priority}`}>{t.priority}</span>
                {t.is_escalated && <span className="badge escalated">Escalated</span>}
                {isOverdue(t) && <span className="badge breach">Overdue</span>}
                <span className="muted small right">#{t.id}</span>
              </div>
              <div className="row-subject">{t.title}</div>
              <div className="muted small">
                {staff ? `${names.client(t.client_id)} · ${names.agent(t.agent_id) ?? 'Unassigned'} · ` : ''}
                updated {timeAgo(t.updated_at)}
              </div>
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}
