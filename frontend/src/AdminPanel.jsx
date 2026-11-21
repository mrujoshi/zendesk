import { useEffect, useState } from 'react';
import { api } from './api.js';
import { Avatar, EmptyState, Icon, Skeleton, useToast } from './ui.jsx';

// Admin-only "Team" page.
//   Clients = companies (POST/GET /api/clients). They don't log in.
//   Users   = people at a client who log in and raise tickets (POST/GET /api/users). Each user only
//             ever sees their own client's tickets, so only admins create users, never open sign-up.
//   Staff   = agents and admins (POST/GET /api/agents).
export default function AdminPanel({ agents, onAgentsChanged }) {
  const [tab, setTab] = useState('users');
  const [clients, setClients] = useState(null);
  const [users, setUsers] = useState(null);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState('');
  const [clientFilter, setClientFilter] = useState('');

  const load = () =>
    Promise.all([api('/clients'), api('/users')])
      .then(([c, u]) => {
        setClients(c);
        setUsers(u);
      })
      .catch((e) => setError(e.message));

  useEffect(() => {
    load();
  }, []);

  const f = filter.trim().toLowerCase();
  const match = (...fields) => !f || fields.some((x) => x?.toLowerCase().includes(f));

  const tabs = [
    { key: 'users', label: 'Users', count: users?.length },
    { key: 'clients', label: 'Clients', count: clients?.length },
    { key: 'staff', label: 'Staff', count: agents.length },
  ];

  return (
    <main className="page">
      <div className="page-inner">
        <div className="page-head">
          <div>
            <h1>Team</h1>
            <p>Clients are companies. Users belong to one client and only see that client’s tickets.</p>
          </div>
          <div className="search" style={{ width: 260, flex: 'none' }}>
            <Icon name="search" />
            <input placeholder="Filter by name or email…" value={filter} onChange={(e) => setFilter(e.target.value)} aria-label="Filter" />
          </div>
        </div>

        {error && (
          <div className="banner error">
            <Icon name="alert" /> {error}
          </div>
        )}

        <div className="tabs page-tabs" role="tablist">
          {tabs.map((t) => (
            <button key={t.key} role="tab" aria-selected={tab === t.key} className={tab === t.key ? 'active' : ''} onClick={() => setTab(t.key)}>
              {t.label}
              {t.count != null && <span className="tab-count">{t.count}</span>}
            </button>
          ))}
        </div>

        {tab === 'users' && (
          <>
            <AddUserForm
              clients={clients ?? []}
              onCreated={(u) => {
                setClientFilter(String(u.client_id));
                load();
              }}
            />
            <div className="section-head">
              <h2>Users</h2>
              <select value={clientFilter} onChange={(e) => setClientFilter(e.target.value)} aria-label="Filter by client">
                <option value="">All clients</option>
                {(clients ?? []).map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="card">
              {!users ? (
                <LoadingRows />
              ) : (
                <PeopleTable
                  rows={users.filter((u) => (!clientFilter || String(u.client_id) === clientFilter) && match(u.name, u.email, u.client_name))}
                  columns={['Client', 'Role at client']}
                  cells={(u) => [<span className="client-chip">{u.client_name}</span>, <span className="muted">{u.category}</span>]}
                  empty={f || clientFilter ? 'No users match.' : 'No users yet. Add one above.'}
                />
              )}
            </div>
          </>
        )}

        {tab === 'clients' && (
          <>
            <AddClientForm onCreated={load} />
            <h2>Clients</h2>
            <div className="card">
              {!clients ? (
                <LoadingRows />
              ) : (
                <PeopleTable
                  rows={clients.filter((c) => match(c.name, c.email))}
                  columns={['Users', 'Tickets', '']}
                  cells={(c) => [
                    c.user_count,
                    c.ticket_count,
                    <button
                      className="ghost"
                      style={{ padding: '4px 8px', fontSize: 12 }}
                      onClick={() => {
                        setClientFilter(String(c.id));
                        setTab('users');
                      }}
                    >
                      View users
                    </button>,
                  ]}
                  empty={f ? 'No clients match.' : 'No clients yet. Add one above.'}
                />
              )}
            </div>
          </>
        )}

        {tab === 'staff' && (
          <>
            <AddAgentForm onCreated={onAgentsChanged} />
            <h2>Staff</h2>
            <div className="card">
              <PeopleTable
                rows={agents.filter((a) => match(a.name, a.email))}
                columns={['Role', 'Status']}
                cells={(a) => [
                  <span className={`role-tag role-${a.role}`}>{a.role}</span>,
                  <span className={`status-dot ${a.is_active ? '' : 'off'}`}>{a.is_active ? 'Active' : 'Disabled'}</span>,
                ]}
                empty="No staff match."
              />
            </div>
            <p className="muted small">New tickets go to active agents in turn (admins are skipped).</p>
          </>
        )}
      </div>
    </main>
  );
}

/* ------------------------------------------------------------------ tables */

function PeopleTable({ rows, columns, cells, empty }) {
  if (rows.length === 0) return <EmptyState icon="users" title={empty} />;
  return (
    <table className="table">
      <thead>
        <tr>
          <th>Name</th>
          {columns.map((c, i) => (
            <th key={i}>{c}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.id}>
            <td>
              <div className="person">
                <Avatar name={r.name} size={30} />
                <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.3, minWidth: 0 }}>
                  <span>{r.name}</span>
                  <span className="muted small">{r.email}</span>
                </div>
              </div>
            </td>
            {cells(r).map((c, i) => (
              <td key={i}>{c}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function LoadingRows() {
  return (
    <div className="pad" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <Skeleton height={16} />
      <Skeleton height={16} width="80%" />
      <Skeleton height={16} width="60%" />
    </div>
  );
}

/* ------------------------------------------------------------------ forms */

function useForm(initial, path, successMsg, onCreated) {
  const [form, setForm] = useState(initial);
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);
  const toast = useToast();
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });
  async function submit(e, body = form) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const created = await api(path, { method: 'POST', body });
      toast(successMsg(created));
      setForm(initial);
      onCreated(created);
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }
  return { form, setForm, set, submit, error, saving };
}

function FormCard({ title, error, children, onSubmit, saving, button, hint }) {
  return (
    <div className="card">
      <div className="card-head">
        <Icon name="plus" /> {title}
      </div>
      <form className="card-body form-grid" onSubmit={onSubmit}>
        {error && (
          <div className="banner error full" style={{ margin: 0 }}>
            <Icon name="alert" /> {error}
          </div>
        )}
        {children}
        <div className="full" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {hint && <span className="muted small">{hint}</span>}
          <div className="spacer" />
          <button className="primary" type="submit" disabled={saving}>
            <Icon name="plus" /> {saving ? 'Adding…' : button}
          </button>
        </div>
      </form>
    </div>
  );
}

function AddUserForm({ clients, onCreated }) {
  const { form, set, submit, error, saving } = useForm(
    { client_id: '', name: '', email: '', password: '', category: 'Employee' },
    '/users',
    (u) => `${u.name} added to ${u.client_name}`,
    onCreated
  );
  return (
    <FormCard
      title="Add a user to a client"
      error={error}
      saving={saving}
      button="Add user"
      hint="The user will only see tickets of the client you pick."
      onSubmit={(e) => submit(e, { ...form, client_id: Number(form.client_id) })}
    >
      <label className="field">
        Client
        <select required value={form.client_id} onChange={set('client_id')}>
          <option value="" disabled>
            Choose a client…
          </option>
          {clients.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </label>
      <label className="field">
        Role at client
        <input required maxLength={50} value={form.category} onChange={set('category')} placeholder="e.g. Manager, Finance" />
      </label>
      <label className="field">
        Name
        <input required maxLength={100} value={form.name} onChange={set('name')} placeholder="Full name" />
      </label>
      <label className="field">
        Email
        <input required type="email" value={form.email} onChange={set('email')} placeholder="name@company.com" />
      </label>
      <label className="field full">
        Password
        <input required type="password" minLength={8} value={form.password} onChange={set('password')} placeholder="At least 8 characters" />
      </label>
    </FormCard>
  );
}

function AddClientForm({ onCreated }) {
  const { form, set, submit, error, saving } = useForm({ name: '', email: '' }, '/clients', (c) => `Client ${c.name} created`, onCreated);
  return (
    <FormCard title="Add a client (company)" error={error} saving={saving} button="Add client" hint="Then add users for it on the Users tab." onSubmit={submit}>
      <label className="field">
        Company name
        <input required maxLength={100} value={form.name} onChange={set('name')} placeholder="e.g. Acme Corp" />
      </label>
      <label className="field">
        Contact email
        <input required type="email" value={form.email} onChange={set('email')} placeholder="support@company.com" />
      </label>
    </FormCard>
  );
}

function AddAgentForm({ onCreated }) {
  const { form, setForm, set, submit, error, saving } = useForm(
    { name: '', email: '', password: '', role: 'agent' },
    '/agents',
    (a) => `${a.name} added as ${a.role}`,
    onCreated
  );
  return (
    <FormCard title="Add an agent or admin" error={error} saving={saving} button="Add member" onSubmit={submit}>
      <label className="field">
        Name
        <input required maxLength={100} value={form.name} onChange={set('name')} placeholder="Full name" />
      </label>
      <label className="field">
        Email
        <input required type="email" value={form.email} onChange={set('email')} placeholder="name@support.com" />
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
    </FormCard>
  );
}
