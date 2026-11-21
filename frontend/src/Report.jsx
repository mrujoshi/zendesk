import { useEffect, useState } from 'react';
import { api } from './api.js';

const today = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
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

  const perAgent = report?.open_per_agent ?? [];
  const maxLoad = Math.max(1, ...perAgent.map((a) => a.open));

  return (
    <main className="report">
      <div className="report-head">
        <h1>How are we doing?</h1>
        <label>
          Day
          <input type="date" value={day} max={today()} onChange={(e) => setDay(e.target.value)} />
        </label>
      </div>

      {error && <div className="banner error">{error}</div>}
      {!report && !error && <div className="muted pad">Loading report…</div>}

      {report && (
        <>
          <div className="stats">
            <Stat label="Created that day" value={report.created} />
            <Stat label="Solved that day" value={report.solved} />
            <Stat label="Open & pending (now)" value={report.open} />
            <Stat label="Escalated (total)" value={report.escalated} warn={report.escalated > 0} />
          </div>

          <h2>Open load per agent</h2>
          {perAgent.length === 0 ? (
            <div className="muted">No open tickets assigned.</div>
          ) : (
            <table className="agents">
              <thead>
                <tr>
                  <th>Agent</th>
                  <th>Open & pending</th>
                </tr>
              </thead>
              <tbody>
                {perAgent.map((a) => (
                  <tr key={a.agent_id}>
                    <td>{a.name}</td>
                    <td>
                      <div className="load">
                        <div className="load-bar" style={{ width: `${(a.open / maxLoad) * 100}%` }} />
                        <span>{a.open}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </>
      )}
    </main>
  );
}

function Stat({ label, value, warn }) {
  return (
    <div className={`stat ${warn ? 'warn' : ''}`}>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}
