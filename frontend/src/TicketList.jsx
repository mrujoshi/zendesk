import { useEffect, useRef, useState } from 'react';
import { api, isActive, isStaff, PRIORITIES, timeAgo } from './api.js';
import { Avatar, EmptyState, Icon, Kbd, PriorityTag, Skeleton, SlaChip, StatusPill, useHotkeys, useNow, useToast } from './ui.jsx';

// Each tab = query params for GET /api/tickets (status/priority/escalated/agent_id), plus an optional
// filter applied in the browser. The API takes one status at a time, so "Active" fetches all and keeps
// open+pending. Users get the same endpoint; the API only returns their own client's tickets.
const STAFF_TABS = [
  { key: 'active', label: 'Open & pending', params: () => ({}), keep: isActive },
  { key: 'mine', label: 'Mine', params: (u) => ({ agent_id: u.id }), keep: isActive },
  { key: 'escalated', label: 'Escalated', params: () => ({ escalated: 'true' }) },
  { key: 'solved', label: 'Solved', params: () => ({ status: 'solved' }) },
  { key: 'closed', label: 'Closed', params: () => ({ status: 'closed' }) },
  { key: 'all', label: 'All', params: () => ({}) },
];

const USER_TABS = [
  { key: 'active', label: 'Open & pending', params: () => ({}), keep: isActive },
  { key: 'mine', label: 'Raised by me', params: () => ({}), keep: (t, u) => t.user_id === u.id },
  { key: 'solved', label: 'Solved', params: () => ({ status: 'solved' }) },
  { key: 'closed', label: 'Closed', params: () => ({ status: 'closed' }) },
  { key: 'all', label: 'All', params: () => ({}) },
];

const PAGE_SIZE = 100; // API maximum
const POLL_MS = 10_000; // live updates: re-fetch the list every 10s

export default function TicketList({ user, names, selectedId, onSelect, refreshKey }) {
  const staff = isStaff(user);
  const tabs = staff ? STAFF_TABS : USER_TABS;
  const [tab, setTab] = useState('active');
  const [priority, setPriority] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(null); // {items, total} ; null = loading
  const [loadedAt, setLoadedAt] = useState(null);
  const [error, setError] = useState(null);
  const [reload, setReload] = useState(0);
  const searchRef = useRef(null);
  const toast = useToast();
  const now = useNow(5_000);

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
            setLoadedAt(Date.now());
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
    .filter((t) => !current.keep || current.keep(t, user))
    .filter((t) => !q || t.title.toLowerCase().includes(q) || t.description.toLowerCase().includes(q));

  // Keyboard: J/K move through the visible list, / focuses search.
  const move = (dir) => {
    if (!tickets?.length) return;
    const i = tickets.findIndex((t) => t.id === selectedId);
    const next = tickets[Math.min(tickets.length - 1, Math.max(0, i === -1 ? 0 : i + dir))];
    onSelect(next.id);
    document.getElementById(`ticket-row-${next.id}`)?.scrollIntoView({ block: 'nearest' });
  };
  useHotkeys(
    {
      j: () => move(1),
      k: () => move(-1),
      '/': () => searchRef.current?.focus(),
    },
    [tickets, selectedId]
  );

  async function runEscalation() {
    try {
      const { escalated } = await api('/escalations/run', { method: 'POST' });
      toast(escalated.length ? `Escalated ticket #${escalated.join(', #')}` : 'Nothing overdue right now');
      setReload((n) => n + 1);
    } catch (e) {
      toast(e.message, 'error');
    }
  }

  const ago = loadedAt ? Math.max(0, Math.round((now - loadedAt) / 1000)) : null;

  return (
    <section className="list" aria-label="Tickets">
      <div className="list-head">
        <h2>{staff ? 'Tickets' : `${user.client_name} tickets`}</h2>
        {tickets && <span className="count">{tickets.length}</span>}
        <span className="live" title="The list refreshes every 10 seconds">
          <span className="live-dot" />
          {ago === null ? 'Live' : ago < 5 ? 'Live · just now' : `Live · ${ago}s ago`}
        </span>
        <button className="icon-btn" title="Refresh now" aria-label="Refresh" onClick={() => setReload((n) => n + 1)}>
          <Icon name="refresh" size={15} />
        </button>
      </div>

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
        <div className="search">
          <Icon name="search" />
          <input
            ref={searchRef}
            type="search"
            placeholder="Search tickets…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Escape') {
                setSearch('');
                e.currentTarget.blur();
              }
            }}
            aria-label="Search tickets"
          />
          {!search && <Kbd>/</Kbd>}
        </div>
        <select value={priority} onChange={(e) => setPriority(e.target.value)} aria-label="Filter by priority">
          <option value="">All priorities</option>
          {[...PRIORITIES].reverse().map((p) => (
            <option key={p.value} value={p.value}>
              {p.label}
            </option>
          ))}
        </select>
      </div>

      {user.role === 'admin' && (
        <div className="admin-strip">
          <Icon name="flame" size={14} />
          <span className="muted">Overdue tickets escalate every 60 s.</span>
          <button className="danger" style={{ marginLeft: 'auto', padding: '4px 10px', fontSize: 12 }} onClick={runEscalation}>
            Run now
          </button>
        </div>
      )}

      {error && (
        <div className="banner error" style={{ margin: '0 12px 12px' }}>
          <Icon name="alert" /> {error}
        </div>
      )}

      <ul className="ticket-rows">
        {page === null &&
          !error &&
          [0, 1, 2, 3, 4].map((i) => (
            <li key={i} className="skeleton-row">
              <Skeleton width={34} height={34} style={{ borderRadius: '50%' }} />
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
                <Skeleton width="40%" height={12} />
                <Skeleton width="85%" height={14} />
                <Skeleton width="60%" height={11} />
              </div>
            </li>
          ))}

        {tickets?.length === 0 && (
          <EmptyState icon={q ? 'search' : 'inbox'} title={q ? 'No matches' : 'All clear'}>
            {q
              ? `Nothing in this view matches “${search.trim()}”.`
              : user.role === 'user'
                ? 'No tickets here. Press N to raise one.'
                : 'No tickets in this view right now.'}
          </EmptyState>
        )}

        {tickets?.map((t) => {
          const raisedBy = t.user_id === user.id && !staff ? 'You' : t.user_name ?? t.client_name;
          return (
            <li key={t.id}>
              <button
                id={`ticket-row-${t.id}`}
                className={`row ${t.id === selectedId ? 'selected' : ''}`}
                onClick={() => onSelect(t.id)}
                aria-current={t.id === selectedId}
              >
                <Avatar name={t.user_name ?? t.client_name} size={34} />
                <div className="row-body">
                  <div className="row-top">
                    <StatusPill status={t.status} />
                    <PriorityTag priority={t.priority} />
                    {t.is_escalated && <span className="tag tag-escalated">Escalated</span>}
                    <span className="row-id">#{t.id}</span>
                  </div>
                  <div className="row-title">
                    <Highlight text={t.title} q={q} />
                  </div>
                  <div className="row-meta">
                    <span>{raisedBy}</span>
                    {staff && (
                      <>
                        <span className="sep" />
                        <span className="client-chip">{t.client_name}</span>
                      </>
                    )}
                    <span className="sep" />
                    <span>{t.agent_name ?? (staff ? 'Unassigned' : 'Waiting for an agent')}</span>
                    <span className="sep" />
                    <span>{timeAgo(t.updated_at)}</span>
                    <SlaChip ticket={t} />
                  </div>
                </div>
              </button>
            </li>
          );
        })}
      </ul>

      <div className="list-foot">
        {page && page.total > page.items.length && <span>Newest {page.items.length} of {page.total}</span>}
        <span>
          <Kbd>J</Kbd>
          <Kbd>K</Kbd> navigate
        </span>
        <span>
          <Kbd>?</Kbd> shortcuts
        </span>
      </div>
    </section>
  );
}

function Highlight({ text, q }) {
  if (!q) return text;
  const i = text.toLowerCase().indexOf(q);
  if (i === -1) return text;
  return (
    <>
      {text.slice(0, i)}
      <mark>{text.slice(i, i + q.length)}</mark>
      {text.slice(i + q.length)}
    </>
  );
}
