import { useState } from 'react';
import { api, PRIORITIES } from './api.js';

// Clients only (POST /api/tickets). The requester is the logged-in client.
export default function NewTicketModal({ user, onClose, onCreated }) {
  const [form, setForm] = useState({ title: '', description: '', priority: 'normal' });
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const ticket = await api('/tickets', { method: 'POST', body: form });
      onCreated(ticket);
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form className="modal" onSubmit={submit} onClick={(e) => e.stopPropagation()} aria-label="New ticket">
        <h2>New ticket</h2>
        <div className="muted small">
          Submitting as {user.name}. It will be auto-assigned to the next agent (round-robin).
        </div>
        {error && <div className="banner error">{error}</div>}
        <label>
          Title
          <input required maxLength={200} value={form.title} onChange={set('title')} autoFocus />
        </label>
        <label>
          Description
          <textarea required rows={5} value={form.description} onChange={set('description')} />
        </label>
        <label>
          Priority
          <select value={form.priority} onChange={set('priority')}>
            {PRIORITIES.map((p) => (
              <option key={p.value} value={p.value}>
                {p.label} ({p.sla} SLA)
              </option>
            ))}
          </select>
        </label>
        <div className="modal-actions">
          <button type="button" onClick={onClose}>
            Cancel
          </button>
          <button className="primary" type="submit" disabled={saving}>
            {saving ? 'Creating…' : 'Create ticket'}
          </button>
        </div>
      </form>
    </div>
  );
}
