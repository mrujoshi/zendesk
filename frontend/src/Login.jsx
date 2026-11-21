import { useState } from 'react';
import { api, setToken } from './api.js';

// Demo users seeded by backend-controller (password123). Agents and admins log in as user_type 'agent'.
const DEMO_ACCOUNTS = [
  { email: 'asha@demo.com', label: 'Admin Asha', role: 'admin', user_type: 'agent' },
  { email: 'priya@demo.com', label: 'Priya', role: 'agent', user_type: 'agent' },
  { email: 'rahul@demo.com', label: 'Rahul', role: 'agent', user_type: 'agent' },
  { email: 'ravi@demo.com', label: 'Ravi Customer', role: 'client', user_type: 'client' },
];

export default function Login({ onLoggedIn }) {
  const [mode, setMode] = useState('login'); // 'login' | 'signup'
  const [userType, setUserType] = useState('agent');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  async function logIn(type = userType) {
    const { token, user } = await api('/auth/login', {
      method: 'POST',
      body: { email, password, user_type: type },
    });
    setToken(token);
    onLoggedIn(user);
  }

  async function submit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      if (mode === 'signup') {
        await api('/clients', { method: 'POST', body: { name, email, password } }); // open signup
        await logIn('client');
      } else {
        await logIn();
      }
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }

  const signup = mode === 'signup';

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={submit} aria-label={signup ? 'Create account' : 'Log in'}>
        <div className="brand login-brand">Mini-Zendesk</div>
        <h1>{signup ? 'Create a client account' : 'Log in'}</h1>
        {error && <div className="banner error">{error}</div>}

        {!signup && (
          <div className="segmented" role="radiogroup" aria-label="Log in as">
            {[
              ['agent', 'Agent / Admin'],
              ['client', 'Client'],
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
        )}

        {signup && (
          <label>
            Name
            <input required maxLength={100} value={name} onChange={(e) => setName(e.target.value)} />
          </label>
        )}
        <label>
          Email
          <input type="email" required autoFocus value={email} onChange={(e) => setEmail(e.target.value)} />
        </label>
        <label>
          Password
          <input
            type="password"
            required
            minLength={signup ? 8 : 1}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        <button className="primary" type="submit" disabled={busy}>
          {busy ? 'Please wait…' : signup ? 'Create account' : 'Log in'}
        </button>
        <button
          type="button"
          className="text-btn"
          onClick={() => {
            setMode(signup ? 'login' : 'signup');
            setError(null);
          }}
        >
          {signup ? 'Back to log in' : 'New client? Create an account'}
        </button>

        {!signup && (
          <div className="demo">
            <div className="muted small">Demo accounts (password: password123)</div>
            <div className="demo-list">
              {DEMO_ACCOUNTS.map((a) => (
                <button
                  type="button"
                  key={a.email}
                  onClick={() => {
                    setEmail(a.email);
                    setPassword('password123');
                    setUserType(a.user_type);
                  }}
                >
                  {a.label} <span className={`role-tag role-${a.role}`}>{a.role}</span>
                </button>
              ))}
            </div>
          </div>
        )}
      </form>
    </div>
  );
}
