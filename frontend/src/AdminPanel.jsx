import { useState } from 'react';
import { api } from './api.js';

const EMPTY = { name: '', email: '', password: '', role: 'agent' };

// Admin-only: create agents/admins (POST /api/agents) and see agents + clients (GET /api/agents, /api/clients).
export default function AdminPanel({ agents, clients, onChanged }) {
  const [form, setForm] = useState(EMPTY);
  const [error, setError] = useState(null);
  const [notice, setNotice] = useState(null);
  const [saving, setSaving] = useState(false);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function createAgent(e) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      const a = await api('/agents', { method: 'POST', body: form });
      setNotice(`Created ${a.role} ${a.name}.`);
      setForm(EMPTY);
      onChanged();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="report">
      <h1>Team</h1>
      {error && <div className="banner error">{error}</div>}
      {notice && <div className="banner info">{notice}</div>}

      <h2>Add an agent or admin</h2>
      <form className="inline-form" onSubmit={createAgent}>
        <input required maxLength={100} placeholder="Name" value={form.name} onChange={set('name')} aria-label="Name" />
        <input required type="email" placeholder="Email" value={form.email} onChange={set('email')} aria-label="Email" />
        <input
          required
          type="password"
          minLength={8}
          placeholder="Password (min 8)"
          value={form.password}
          onChange={set('password')}
          aria-label="Password"
        />
        <select value={form.role} onChange={set('role')} aria-label="Role">
          <option value="agent">Agent</option>
          <option value="admin">Admin</option>
        </select>
        <button className="primary" type="submit" disabled={saving}>
          {saving ? 'Adding…' : 'Add'}
        </button>
      </form>
      <p className="muted small">Clients sign up themselves from the login page.</p>

      <h2>Agents</h2>
      <table className="agents">
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {agents.map((a) => (
            <tr key={a.id} className={a.is_active ? '' : 'inactive'}>
              <td>{a.name}</td>
              <td>{a.email}</td>
              <td>
                <span className={`role-tag role-${a.role}`}>{a.role}</span>
              </td>
              <td>{a.is_active ? 'Active' : 'Disabled'}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="muted small">Round-robin assigns new tickets to active agents (not admins), in id order.</p>

      <h2>Clients</h2>
      {clients.length === 0 ? (
        <div className="muted">No clients yet.</div>
      ) : (
        <table className="agents">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
            </tr>
          </thead>
          <tbody>
            {clients.map((c) => (
              <tr key={c.id}>
                <td>{c.name}</td>
                <td>{c.email}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </main>
  );
}
