// Single place where the UI talks to the backend (backend-controller, see its CONTRACT.md).
// Every request goes through here.

const TOKEN_KEY = 'mz_token';

export function getToken() {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setToken(token) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* storage unavailable - session just won't persist across reloads */
  }
}

// App registers this so any 401 (expired/invalid session) sends the user back to the login page.
let onUnauthorized = () => {};
export function setUnauthorizedHandler(fn) {
  onUnauthorized = fn;
}

export async function api(path, { method = 'GET', body } = {}) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(`/api${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new Error('Cannot reach the server. Is the backend running?');
  }

  const data = await res.json().catch(() => null);
  if (!res.ok) {
    if (res.status === 401 && path !== '/auth/login') {
      setToken(null);
      onUnauthorized();
    }
    // Controller errors are always { "error": "code", "message": "text" }
    const err = new Error(data?.message || `Request failed (${res.status})`);
    err.status = res.status;
    err.code = data?.error;
    throw err;
  }
  return data;
}

// Mirrors constants.py in backend-controller (SLA is in hours unless SLA_UNIT=minutes).
export const PRIORITIES = [
  { value: 'low', label: 'Low', sla: '48h' },
  { value: 'normal', label: 'Normal', sla: '24h' },
  { value: 'high', label: 'High', sla: '4h' },
  { value: 'urgent', label: 'Urgent', sla: '1h' },
];

// Mirrors ALLOWED_TRANSITIONS in constants.py. The API enforces it; the UI only uses it to build the dropdown.
export const STATUS_FLOW = {
  open: ['pending', 'solved'],
  pending: ['open', 'solved'],
  solved: ['open', 'closed'],
  closed: [],
};

export const isStaff = (user) => user?.role === 'agent' || user?.role === 'admin';
export const isActive = (t) => t.status === 'open' || t.status === 'pending';
export const isOverdue = (t) => isActive(t) && t.due_at && new Date(t.due_at).getTime() < Date.now();

export function timeAgo(iso) {
  const secs = Math.round((Date.now() - new Date(iso).getTime()) / 1000);
  const future = secs < 0;
  const s = Math.abs(secs);
  const str =
    s < 60 ? `${s}s` : s < 3600 ? `${Math.floor(s / 60)}m` : s < 86400 ? `${Math.floor(s / 3600)}h` : `${Math.floor(s / 86400)}d`;
  return future ? `in ${str}` : `${str} ago`;
}
