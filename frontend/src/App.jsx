import { useEffect, useMemo, useState } from 'react';
import { api, getToken, isStaff, setToken, setUnauthorizedHandler } from './api.js';
import Login from './Login.jsx';
import TicketList from './TicketList.jsx';
import TicketDetail from './TicketDetail.jsx';
import NewTicketModal from './NewTicketModal.jsx';
import Report from './Report.jsx';
import AdminPanel from './AdminPanel.jsx';

export default function App() {
  const [user, setUser] = useState(null);
  const [booting, setBooting] = useState(Boolean(getToken()));

  useEffect(() => {
    setUnauthorizedHandler(() => setUser(null));
    if (getToken()) {
      api('/auth/me')
        .then(setUser)
        .catch(() => setToken(null))
        .finally(() => setBooting(false));
    }
  }, []);

  async function logout() {
    await api('/auth/logout', { method: 'POST' }).catch(() => {}); // revoke server-side; ignore if already expired
    setToken(null);
    setUser(null);
  }

  if (booting) return <div className="muted pad">Loading…</div>;
  if (!user) return <Login onLoggedIn={setUser} />;
  return <Workspace key={`${user.role}-${user.id}`} user={user} onLogout={logout} />;
}

function Workspace({ user, onLogout }) {
  const staff = isStaff(user);
  const [agents, setAgents] = useState([]);
  const [clients, setClients] = useState([]);
  const [view, setView] = useState('tickets');
  const [selectedId, setSelectedId] = useState(null);
  const [showNew, setShowNew] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0); // bump to make the list reload after a change
  const [error, setError] = useState(null);

  // Tickets only carry client_id / agent_id, so staff load both lists once to show names.
  // Clients can't list agents (403), so for them agent names fall back to "Support agent".
  const loadPeople = () => {
    if (!staff) return;
    Promise.all([api('/agents'), api('/clients')])
      .then(([a, c]) => {
        setAgents(a);
        setClients(c);
      })
      .catch((e) => setError(e.message));
  };
  useEffect(loadPeople, []);

  const names = useMemo(() => {
    const a = new Map(agents.map((x) => [x.id, x.name]));
    const c = new Map(clients.map((x) => [x.id, x.name]));
    return {
      agent: (id) => (id == null ? null : a.get(id) ?? (user.role !== 'client' && id === user.id ? user.name : 'Support agent')),
      client: (id) => (user.role === 'client' && id === user.id ? user.name : c.get(id) ?? `Client #${id}`),
    };
  }, [agents, clients, user]);

  const refresh = () => setRefreshKey((k) => k + 1);

  const views = [
    { key: 'tickets', label: staff ? 'Tickets' : 'My requests' },
    ...(staff ? [{ key: 'report', label: 'Daily report' }] : []),
    ...(user.role === 'admin' ? [{ key: 'admin', label: 'Team' }] : []),
  ];

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">Mini-Zendesk</div>
        <nav className="nav" aria-label="Main">
          {views.map((v) => (
            <button key={v.key} className={view === v.key ? 'active' : ''} onClick={() => setView(v.key)}>
              {v.label}
            </button>
          ))}
        </nav>
        <div className="spacer" />
        {/* POST /api/tickets is client-only in the contract */}
        {user.role === 'client' && (
          <button className="primary" onClick={() => setShowNew(true)}>
            + New ticket
          </button>
        )}
        <div className="me">
          <span>{user.name}</span>
          <span className={`role-tag role-${user.role}`}>{user.role}</span>
          <button className="link-btn" onClick={onLogout}>
            Log out
          </button>
        </div>
      </header>

      {error && <div className="banner error">{error}</div>}

      {view === 'tickets' && (
        <main className="workspace">
          <TicketList user={user} names={names} selectedId={selectedId} onSelect={setSelectedId} refreshKey={refreshKey} />
          {selectedId ? (
            <TicketDetail key={selectedId} id={selectedId} user={user} agents={agents} names={names} onChanged={refresh} />
          ) : (
            <section className="detail empty-state">Select a ticket to see the conversation.</section>
          )}
        </main>
      )}
      {view === 'report' && <Report />}
      {view === 'admin' && <AdminPanel agents={agents} clients={clients} onChanged={loadPeople} />}

      {showNew && (
        <NewTicketModal
          user={user}
          onClose={() => setShowNew(false)}
          onCreated={(t) => {
            setShowNew(false);
            setView('tickets');
            setSelectedId(t.id);
            refresh();
          }}
        />
      )}
    </div>
  );
}
