import { useState } from 'react';
import { api } from './api.js';
import { Avatar, EmptyState, Icon, useToast } from './ui.jsx';

const EMPTY = { name: '', email: '', password: '', role: 'agent' };

// Admin-only: create agents/admins (POST /api/agents) and see agents + clients (GET /api/agents, /api/clients).
export default function AdminPanel({ agents, clients, onChanged }) {
  const [form, setForm] = useState(EMPTY);
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);
  const [filter, setFilter] = useState('');
  const toast = useToast();

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function createAgent(e) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const a = await api('/agents', { method: 'POST', body: form });
      toast(`${a.name} added as ${a.role}`);
      setForm(EMPTY);
      onChanged();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  const f = filter.trim().toLowerCase();
  const match = (p) => !f || p.name.toLowerCase().includes(f) || p.email.toLowerCase().includes(f);

  return (
    <main className="page">
      <div className="page-inner">
        <div className="page-head">
          <div>
            <h1>Team</h1>
            <p>
              {agents.filter((a) => a.is_active).length} active staff · {clients.length} clients
            </p>
          </div>
          <div className="search" style={{ width: 260, flex: 'none' }}>
            <Icon name="search" />
            <input placeholder="Filter people…" value={filter} onChange={(e) => setFilter(e.target.value)} aria-label="Filter people" />
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <Icon name="plus" /> Add an agent or admin
          </div>
          <form className="card-body form-grid" onSubmit={createAgent}>
            {error && (
              <div className="banner error full" style={{ margin: 0 }}>
                <Icon name="alert" /> {error}
              </div>
            )}
            <label className="field">
              Name
              <input required maxLength={100} value={form.name} onChange={set('name')} placeholder="Full name" />
            </label>
            <label className="field">
              Email
              <input required type="email" value={form.email} onChange={set('email')} placeholder="name@company.com" />
            </label>
            <label className="field">
              Password
              <input required type="password" minLength={8} value={form.password} onChange={set('password')} placeholder="At least 8 characters" />
            </label>
            <div className="field">
              Role
              <div className="segmented">
                {['agent', 'admin'].map((r) => (
                  <button type="button" key={r} className={form.role === r ? 'active' : ''} onClick={() => setForm({ ...form, role: r })}>
                    {r === 'agent' ? 'Agent' : 'Admin'}
                  </button>
                ))}
              </div>
            </div>
            <div className="full" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span className="muted small">New tickets go to active agents in turn (admins are skipped). Clients sign up from the login page.</span>
              <div className="spacer" />
              <button className="primary" type="submit" disabled={saving}>
                <Icon name="plus" /> {saving ? 'Adding…' : 'Add member'}
              </button>
            </div>
          </form>
        </div>

        <div className="two-col">
          <section>
            <h2>Staff</h2>
            <div className="card">
              <table className="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Role</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {agents.filter(match).map((a) => (
                    <tr key={a.id} className={a.is_active ? '' : 'inactive'}>
                      <td>
                        <div className="person">
                          <Avatar name={a.name} size={30} />
                          <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.3, minWidth: 0 }}>
                            <span>{a.name}</span>
                            <span className="muted small">{a.email}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span className={`role-tag role-${a.role}`}>{a.role}</span>
                      </td>
                      <td>
                        <span className="status-dot">{a.is_active ? 'Active' : 'Disabled'}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section>
            <h2>Clients</h2>
            <div className="card">
              {clients.filter(match).length === 0 ? (
                <EmptyState icon="users" title={f ? 'No matches' : 'No clients yet'}>
                  {f ? 'Try a different name or email.' : 'Clients appear here after they sign up.'}
                </EmptyState>
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Joined</th>
                    </tr>
                  </thead>
                  <tbody>
                    {clients.filter(match).map((c) => (
                      <tr key={c.id}>
                        <td>
                          <div className="person">
                            <Avatar name={c.name} size={30} />
                            <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.3, minWidth: 0 }}>
                              <span>{c.name}</span>
                              <span className="muted small">{c.email}</span>
                            </div>
                          </div>
                        </td>
                        <td className="muted small">{c.created_at ? new Date(c.created_at).toLocaleDateString() : '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </section>
        </div>
      </div>
    </main>
  );
}
