import { useEffect, useMemo, useState } from 'react';
import { api, getToken, isStaff, setToken, setUnauthorizedHandler } from './api.js';
import { Avatar, Icon, Kbd, Modal, ToastProvider, useHotkeys } from './ui.jsx';
import Login from './Login.jsx';
import TicketList from './TicketList.jsx';
import TicketDetail from './TicketDetail.jsx';
import NewTicketModal from './NewTicketModal.jsx';
import Report from './Report.jsx';
import AdminPanel from './AdminPanel.jsx';

export default function App() {
  return (
    <ToastProvider>
      <Root />
    </ToastProvider>
  );
}

function Root() {
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

  if (booting) return null;
  if (!user) return <Login onLoggedIn={setUser} />;
  return <Workspace key={`${user.role}-${user.id}`} user={user} onLogout={logout} />;
}

/* ------------------------------------------------------------------ theme */

function useTheme() {
  const systemDark = () => window.matchMedia?.('(prefers-color-scheme: dark)').matches;
  const [theme, setTheme] = useState(() => document.documentElement.dataset.theme || (systemDark() ? 'dark' : 'light'));
  const toggle = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem('mz_theme', next);
    } catch {
      /* not persisted */
    }
    setTheme(next);
  };
  return [theme, toggle];
}

/* ------------------------------------------------------------------ workspace */

function Workspace({ user, onLogout }) {
  const staff = isStaff(user);
  const [agents, setAgents] = useState([]);
  const [view, setView] = useState('tickets');
  const [selectedId, setSelectedId] = useState(null);
  const [showNew, setShowNew] = useState(false);
  const [showKeys, setShowKeys] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0); // bump to make the list reload after a change
  const [error, setError] = useState(null);
  const [theme, toggleTheme] = useTheme();

  // Tickets, messages and audit rows already carry display names (client_name, user_name, agent_name,
  // author_name, actor_name). Staff also load the agent list for the assignee dropdown and for audit
  // rows that store agent ids ("assigned 2 -> 3").
  const loadAgents = () => {
    if (!staff) return;
    api('/agents')
      .then(setAgents)
      .catch((e) => setError(e.message));
  };
  useEffect(loadAgents, []);

  const names = useMemo(() => {
    const a = new Map(agents.map((x) => [x.id, x.name]));
    return { agent: (id) => (id == null ? null : a.get(Number(id)) ?? `Agent #${id}`) };
  }, [agents]);

  const refresh = () => setRefreshKey((k) => k + 1);

  const views = [
    { key: 'tickets', label: 'Tickets', icon: 'inbox' },
    ...(staff ? [{ key: 'report', label: 'Report', icon: 'chart' }] : []),
    ...(user.role === 'admin' ? [{ key: 'admin', label: 'Team', icon: 'users' }] : []),
  ];

  useHotkeys(
    {
      n: () => user.role === 'user' && setShowNew(true),
      '?': () => setShowKeys(true),
      t: toggleTheme,
      '1': () => setView('tickets'),
      '2': () => views[1] && setView(views[1].key),
      '3': () => views[2] && setView(views[2].key),
    },
    [user.role, theme, views.length]
  );

  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">
            <Icon name="message" size={16} />
          </span>
          <span className="hide-sm">Mini-Zendesk</span>
        </div>
        <nav className="nav" aria-label="Main">
          {views.map((v) => (
            <button key={v.key} className={view === v.key ? 'active' : ''} onClick={() => setView(v.key)} title={v.label}>
              <Icon name={v.icon} />
              <span>{v.label}</span>
            </button>
          ))}
        </nav>
        <div className="spacer" />
        <div className="top-actions">
          {/* POST /api/tickets is for users (people at a client) only */}
          {user.role === 'user' && (
            <button className="primary" onClick={() => setShowNew(true)} title="New ticket (N)">
              <Icon name="plus" />
              <span className="hide-sm">New ticket</span>
            </button>
          )}
          <button className="icon-btn" onClick={() => setShowKeys(true)} title="Keyboard shortcuts (?)" aria-label="Keyboard shortcuts">
            <Icon name="keyboard" size={18} />
          </button>
          <button
            className="icon-btn"
            onClick={toggleTheme}
            title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode (T)`}
            aria-label="Toggle dark mode"
          >
            <Icon name={theme === 'dark' ? 'sun' : 'moon'} size={18} />
          </button>
          <div className="me">
            <Avatar name={user.name} size={32} />
            <div className="me-text">
              <span className="me-name">{user.name}</span>
              <span className="me-sub">
                <span className={`role-tag role-${user.role}`}>{user.role}</span>
                {user.client_name && <span>{user.client_name}</span>}
              </span>
            </div>
            <button className="icon-btn" onClick={onLogout} title="Log out" aria-label="Log out">
              <Icon name="logout" size={18} />
            </button>
          </div>
        </div>
      </header>

      {error && (
        <div className="banner error" style={{ margin: 12 }}>
          <Icon name="alert" /> {error}
        </div>
      )}

      {view === 'tickets' && (
        <main className={`workspace ${selectedId ? 'has-selection' : ''}`}>
          <TicketList user={user} names={names} selectedId={selectedId} onSelect={setSelectedId} refreshKey={refreshKey} />
          {selectedId ? (
            <TicketDetail
              key={selectedId}
              id={selectedId}
              user={user}
              agents={agents}
              names={names}
              onChanged={refresh}
              onBack={() => setSelectedId(null)}
            />
          ) : (
            <section className="detail empty-state">
              <div className="empty">
                <div className="empty-icon">
                  <Icon name="message" size={22} />
                </div>
                <div className="empty-title">Pick a ticket</div>
                <div className="empty-text">
                  Choose a conversation on the left, or use <Kbd>J</Kbd> / <Kbd>K</Kbd> to move through the list.
                </div>
              </div>
            </section>
          )}
        </main>
      )}
      {view === 'report' && <Report />}
      {view === 'admin' && <AdminPanel agents={agents} onAgentsChanged={loadAgents} />}

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

      {showKeys && (
        <Modal title="Keyboard shortcuts" onClose={() => setShowKeys(false)} width={420}>
          <div className="shortcuts">
            <span><Kbd>J</Kbd> <Kbd>K</Kbd></span> Next / previous ticket
            <span><Kbd>/</Kbd></span> Search tickets
            {user.role === 'user' && (
              <>
                <span><Kbd>N</Kbd></span> New ticket
              </>
            )}
            <span><Kbd>R</Kbd></span> Focus the reply box
            <span><Kbd>⌘</Kbd> <Kbd>Enter</Kbd></span> Send reply / submit form
            <span><Kbd>1</Kbd> <Kbd>2</Kbd> <Kbd>3</Kbd></span> Switch page
            <span><Kbd>T</Kbd></span> Toggle dark mode
            <span><Kbd>Esc</Kbd></span> Close dialog / clear search
            <span><Kbd>?</Kbd></span> Show this list
          </div>
        </Modal>
      )}
    </div>
  );
}
