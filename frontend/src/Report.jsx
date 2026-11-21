import { useEffect, useState } from 'react';
import { api } from './api.js';
import { Avatar, EmptyState, Icon, Skeleton } from './ui.jsx';

const ymd = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const today = () => ymd(new Date());
const shift = (day, n) => {
  const [y, m, d] = day.split('-').map(Number);
  return ymd(new Date(y, m - 1, d + n));
};

// GET /api/reports/daily?day=YYYY-MM-DD -> {date, created, solved, open, escalated, open_per_agent}
export default function Report() {
  const [day, setDay] = useState(today());
  const [report, setReport] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    api(`/reports/daily?day=${day}`).then(setReport).catch((e) => setError(e.message));
  }, [day]);

  const perAgent = [...(report?.open_per_agent ?? [])].sort((a, b) => b.open - a.open);
  const maxLoad = Math.max(1, ...perAgent.map((a) => a.open));
  const isToday = day === today();

  const pretty = new Date(`${day}T00:00:00`).toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });

  return (
    <main className="page">
      <div className="page-inner">
        <div className="page-head">
          <div>
            <h1>Daily report</h1>
            <p>{isToday ? `Today, ${pretty}` : pretty}</p>
          </div>
          <div className="date-nav">
            <button className="icon-btn" onClick={() => setDay(shift(day, -1))} aria-label="Previous day">
              <Icon name="chevronLeft" />
            </button>
            <input type="date" value={day} max={today()} onChange={(e) => e.target.value && setDay(e.target.value)} aria-label="Day" />
            <button className="icon-btn" onClick={() => setDay(shift(day, 1))} disabled={isToday} aria-label="Next day">
              <Icon name="chevronRight" />
            </button>
            {!isToday && (
              <button className="ghost" onClick={() => setDay(today())}>
                Today
              </button>
            )}
          </div>
        </div>

        {error && (
          <div className="banner error">
            <Icon name="alert" /> {error}
          </div>
        )}

        <div className="stats">
          <Stat icon="plus" color="var(--brand)" label="Created that day" value={report?.created} />
          <Stat icon="check" color="var(--ok)" label="Solved that day" value={report?.solved} />
          <Stat icon="inbox" color="var(--st-pending)" label="Open & pending now" value={report?.open} />
          <Stat icon="flame" color="var(--escalated)" label="Escalated (all time)" value={report?.escalated} />
        </div>

        <h2>Open tickets per agent</h2>
        <div className="card">
          {!report && !error && (
            <div className="pad" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <Skeleton height={16} />
              <Skeleton height={16} width="80%" />
              <Skeleton height={16} width="60%" />
            </div>
          )}
          {report && perAgent.length === 0 && (
            <EmptyState icon="users" title="No open work assigned">
              Every agent’s queue is empty right now.
            </EmptyState>
          )}
          {perAgent.length > 0 && (
            <div className="agent-rows">
              {perAgent.map((a) => (
                <div className="agent-row" key={a.agent_id}>
                  <div className="agent-name">
                    <Avatar name={a.name} size={28} />
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.name}</span>
                  </div>
                  <div className="bar-track" title={`${a.open} open`}>
                    <div className="bar-fill" style={{ width: `${(a.open / maxLoad) * 100}%` }} />
                  </div>
                  <div className="agent-count">{a.open}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </main>
  );
}

function Stat({ icon, color, label, value }) {
  return (
    <div className="card stat" style={{ '--c': color }}>
      <div className="stat-icon">
        <Icon name={icon} size={18} />
      </div>
      <div>
        <div className="stat-value">{value ?? <Skeleton width={40} height={26} />}</div>
        <div className="stat-label">{label}</div>
      </div>
    </div>
  );
}
