import { useState } from 'react';
import { api, PRIORITIES } from './api.js';
import { Icon, Kbd, Modal, useToast } from './ui.jsx';

const TITLE_MAX = 200;

// Clients only (POST /api/tickets). The requester is the logged-in client.
export default function NewTicketModal({ user, onClose, onCreated }) {
  const [form, setForm] = useState({ title: '', description: '', priority: 'normal' });
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e?.preventDefault();
    if (saving || !form.title.trim() || !form.description.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const ticket = await api('/tickets', { method: 'POST', body: form });
      toast(`Ticket #${ticket.id} created`);
      onCreated(ticket);
    } catch (err) {
      setError(err.message);
      setSaving(false);
    }
  }

  const submitOnCmdEnter = (e) => {
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) submit(e);
  };

  return (
    <Modal title="New ticket" onClose={onClose}>
      <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }} onKeyDown={submitOnCmdEnter}>
        <p className="muted" style={{ margin: '-8px 0 0' }}>
          Tell us what’s wrong, {user.name.split(' ')[0]}. Your ticket goes straight to the next available agent.
        </p>
        {error && (
          <div className="banner error" style={{ margin: 0 }}>
            <Icon name="alert" /> {error}
          </div>
        )}
        <label className="field">
          <span className="label-row">
            Subject
            <span className="char-count">
              {form.title.length}/{TITLE_MAX}
            </span>
          </span>
          <input
            required
            maxLength={TITLE_MAX}
            value={form.title}
            onChange={set('title')}
            placeholder="e.g. Can't log in after password reset"
            autoFocus
          />
        </label>
        <label className="field">
          Description
          <textarea
            required
            rows={5}
            value={form.description}
            onChange={set('description')}
            placeholder="What happened, what you expected, and any steps to reproduce…"
          />
        </label>
        <div className="field" role="radiogroup" aria-label="Priority">
          Priority
          <div className="choice-group">
            {PRIORITIES.map((p) => (
              <button
                type="button"
                key={p.value}
                role="radio"
                aria-checked={form.priority === p.value}
                className={`choice ${form.priority === p.value ? 'active' : ''}`}
                onClick={() => setForm({ ...form, priority: p.value })}
              >
                <span className={`prio prio-${p.value}`}>{p.label}</span>
                <small>Within {p.sla}</small>
              </button>
            ))}
          </div>
        </div>
        <div className="modal-actions">
          <span className="composer-hint hide-sm">
            <Kbd>⌘</Kbd>
            <Kbd>Enter</Kbd> to submit
          </span>
          <button type="button" className="ghost" onClick={onClose}>
            Cancel
          </button>
          <button className="primary" type="submit" disabled={saving || !form.title.trim() || !form.description.trim()}>
            {saving ? 'Creating…' : 'Create ticket'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
