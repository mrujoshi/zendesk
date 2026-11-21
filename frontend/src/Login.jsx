import { useState } from 'react';
import { api, setToken } from './api.js';
import { Avatar, Icon } from './ui.jsx';

// Demo accounts from backend/seed.py (password123). Agents and admins log in as user_type 'agent';
// users belong to a client (company) and log in as user_type 'user'.
const DEMO_ACCOUNTS = [
  { email: 'asha@demo.com', name: 'Admin Asha', role: 'admin', user_type: 'agent' },
  { email: 'priya@demo.com', name: 'Priya Agent', role: 'agent', user_type: 'agent' },
  { email: 'aditi@acme.com', name: 'Aditi Sharma', role: 'user', client: 'Acme Corp', user_type: 'user' },
  { email: 'rohan@globex.com', name: 'Rohan Gupta', role: 'user', client: 'Globex', user_type: 'user' },
];

export default function Login({ onLoggedIn }) {
  const [userType, setUserType] = useState('agent');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(null); // which action is in flight

  async function logIn(creds) {
    const { token, user } = await api('/auth/login', { method: 'POST', body: creds });
    setToken(token);
    onLoggedIn(user);
  }

  async function submit(e) {
    e.preventDefault();
    setBusy('form');
    setError(null);
    try {
      await logIn({ email, password, user_type: userType });
    } catch (err) {
      setError(err.message);
      setBusy(null);
    }
  }

  // One click on a demo card logs straight in.
  async function quickLogin(a) {
    setBusy(a.email);
    setError(null);
    setEmail(a.email);
    setUserType(a.user_type);
    try {
      await logIn({ email: a.email, password: 'password123', user_type: a.user_type });
    } catch (err) {
      setError(err.message);
      setBusy(null);
    }
  }

  return (
    <div className="login-page">
      <aside className="login-hero">
        <div className="brand">
          <span className="brand-mark">
            <Icon name="message" size={16} />
          </span>
          Mini-Zendesk
        </div>
        <div>
          <h1>Support that keeps every customer in the loop.</h1>
          <p>One shared inbox for your team: tickets, conversations, deadlines and escalations in one place.</p>
          <ul className="hero-points">
            {[
              ['zap', 'Tickets go to agents automatically, in turn'],
              ['clock', 'Due dates by priority, overdue tickets escalate'],
              ['lock', 'Private internal notes for the team'],
              ['history', 'Every change recorded in the audit trail'],
            ].map(([icon, text]) => (
              <li key={text}>
                <span className="hp-icon">
                  <Icon name={icon} />
                </span>
                {text}
              </li>
            ))}
          </ul>
        </div>
        <div style={{ opacity: 0.6, fontSize: 12 }}>React · FastAPI · SQLite</div>
      </aside>

      <main className="login-side">
        <form className="login-card" onSubmit={submit} aria-label="Log in">
          <h2>Welcome back</h2>
          <p className="lead">Log in to your support workspace.</p>

          {error && (
            <div className="banner error" style={{ margin: 0 }}>
              <Icon name="alert" /> {error}
            </div>
          )}

          <div className="segmented" role="radiogroup" aria-label="Log in as">
              {[
                ['agent', 'Agent / Admin'],
                ['user', 'User'],
              ].map(([v, l]) => (
                <button
                  type="button"
                  key={v}
                  role="radio"
                  aria-checked={userType === v}
                  className={userType === v ? 'active' : ''}
                  onClick={() => setUserType(v)}
                >
                  {l}
                </button>
              ))}
          </div>
          <label className="field">
            Email
            <input
              type="email"
              required
              autoFocus
              autoComplete="email"
              placeholder="you@company.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </label>
          <label className="field">
            Password
            <span className="pw-wrap">
              <input
                type={showPw ? 'text' : 'password'}
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <button
                type="button"
                className="icon-btn"
                onClick={() => setShowPw((s) => !s)}
                aria-label={showPw ? 'Hide password' : 'Show password'}
              >
                <Icon name={showPw ? 'eyeOff' : 'eye'} />
              </button>
            </span>
          </label>

          <button className="primary" type="submit" disabled={Boolean(busy)}>
            {busy === 'form' ? 'Please wait…' : 'Log in'}
          </button>
          <p className="muted small" style={{ textAlign: 'center', margin: 0 }}>
            Need an account? Your admin adds users to your client (company).
          </p>

          {(
            <>
              <div className="divider">or try a demo account</div>
              <div className="demo-grid">
                {DEMO_ACCOUNTS.map((a) => (
                  <button
                    type="button"
                    key={a.email}
                    className="demo-card"
                    disabled={Boolean(busy)}
                    onClick={() => quickLogin(a)}
                    title={`Log in as ${a.name}`}
                  >
                    <Avatar name={a.name} size={30} />
                    <span className="demo-text">
                      <span className="demo-name">{busy === a.email ? 'Logging in…' : a.name}</span>
                      <span className="demo-sub">
                        <span className={`role-tag role-${a.role}`}>{a.role}</span>
                        {a.client && <span className="muted small">{a.client}</span>}
                      </span>
                    </span>
                  </button>
                ))}
              </div>
            </>
          )}
        </form>
      </main>
    </div>
  );
}
