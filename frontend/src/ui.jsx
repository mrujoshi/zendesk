// Small shared UI pieces: icons, avatar, status/priority badges, SLA chip, toasts, modal, hotkeys.
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { isActive } from './api.js';

/* ------------------------------------------------------------------ icons (inline SVG, stroke style) */

const PATHS = {
  inbox: 'M22 12h-6l-2 3h-4l-2-3H2M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z',
  plus: 'M12 5v14M5 12h14',
  search: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.35-4.35',
  sun: 'M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10zM12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42',
  moon: 'M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
  chart: 'M18 20V10M12 20V4M6 20v-6',
  users: 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
  send: 'M22 2 11 13M22 2l-7 20-4-9-9-4 20-7z',
  lock: 'M19 11H5a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7a2 2 0 0 0-2-2zM7 11V7a5 5 0 0 1 10 0v4',
  alert: 'M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0zM12 9v4M12 17h.01',
  check: 'M20 6 9 17l-5-5',
  clock: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 6v6l4 2',
  keyboard: 'M20 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2zM6 9h.01M10 9h.01M14 9h.01M18 9h.01M6 13h.01M18 13h.01M8 17h8',
  x: 'M18 6 6 18M6 6l12 12',
  eye: 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  eyeOff: 'M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24M1 1l22 22',
  flame: 'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14 0-5.5 3-7 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 1-3a2.5 2.5 0 0 0 2.5 2.5z',
  arrowLeft: 'M19 12H5M12 19l-7-7 7-7',
  chevronLeft: 'M15 18l-6-6 6-6',
  chevronRight: 'M9 18l6-6-6-6',
  refresh: 'M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15',
  message: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z',
  history: 'M3 3v5h5M3.05 13A9 9 0 1 0 6 5.3L3 8M12 7v5l4 2',
  user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
  zap: 'M13 2 3 14h9l-1 8 10-12h-9l1-8z',
  sparkles: 'M12 3l1.9 5.8L19.7 10.7l-5.8 1.9L12 18.4l-1.9-5.8-5.8-1.9 5.8-1.9zM5 3v4M3 5h4M19 17v4M17 19h4',
};

export function Icon({ name, size = 16, className = '' }) {
  return (
    <svg
      className={`icon ${className}`}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={PATHS[name]} />
    </svg>
  );
}

/* ------------------------------------------------------------------ avatar */

const AVATAR_COLORS = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6'];

export function Avatar({ name, size = 32 }) {
  const label = name || '?';
  const initials = label
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('');
  let h = 0;
  for (const c of label) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  return (
    <span
      className="avatar"
      style={{ width: size, height: size, fontSize: Math.round(size * 0.38), background: AVATAR_COLORS[h % AVATAR_COLORS.length] }}
      title={label}
      aria-hidden="true"
    >
      {initials}
    </span>
  );
}

/* ------------------------------------------------------------------ badges */

export function StatusPill({ status }) {
  return (
    <span className={`pill status-${status}`}>
      <span className="dot" />
      {status.replace(/_/g, ' ')}
    </span>
  );
}

const PRIORITY_LEVEL = { low: 1, normal: 2, high: 3, urgent: 4 };

export function PriorityTag({ priority }) {
  const level = PRIORITY_LEVEL[priority] ?? 1;
  return (
    <span className={`prio prio-${priority}`}>
      <span className="bars" aria-hidden="true">
        {[1, 2, 3, 4].map((i) => (
          <span key={i} className={i <= level ? 'on' : ''} />
        ))}
      </span>
      {priority}
    </span>
  );
}

/* ------------------------------------------------------------------ live clock + SLA chip */

export function useNow(intervalMs = 30_000) {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), intervalMs);
    return () => clearInterval(t);
  }, [intervalMs]);
  return now;
}

function duration(ms) {
  const m = Math.round(Math.abs(ms) / 60000);
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 48) return `${h}h ${m % 60 ? `${m % 60}m` : ''}`.trim();
  return `${Math.floor(h / 24)}d`;
}

export function SlaChip({ ticket }) {
  const now = useNow();
  if (!isActive(ticket) || !ticket.due_at) return null;
  const left = new Date(ticket.due_at).getTime() - now;
  const state = left < 0 ? 'over' : left < 2 * 3600_000 ? 'soon' : 'ok';
  return (
    <span className={`sla-chip sla-${state}`} title={`Due ${new Date(ticket.due_at).toLocaleString()}`}>
      <Icon name={state === 'over' ? 'alert' : 'clock'} size={12} />
      {state === 'over' ? `Overdue ${duration(left)}` : `Due in ${duration(left)}`}
    </span>
  );
}

/* ------------------------------------------------------------------ skeleton + empty state */

export function Skeleton({ width = '100%', height = 14, style }) {
  return <span className="skeleton" style={{ width, height, ...style }} />;
}

export function EmptyState({ icon = 'inbox', title, children }) {
  return (
    <div className="empty">
      <div className="empty-icon">
        <Icon name={icon} size={22} />
      </div>
      <div className="empty-title">{title}</div>
      {children && <div className="empty-text">{children}</div>}
    </div>
  );
}

/* ------------------------------------------------------------------ toasts */

const ToastContext = createContext(() => {});

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const idRef = useRef(0);

  const toast = useCallback((message, type = 'success') => {
    const id = ++idRef.current;
    setToasts((list) => [...list, { id, message, type }]);
    setTimeout(() => setToasts((list) => list.filter((t) => t.id !== id)), 3500);
  }, []);

  return (
    <ToastContext.Provider value={toast}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast-${t.type}`}>
            <Icon name={t.type === 'error' ? 'alert' : 'check'} size={16} />
            <span>{t.message}</span>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);

/* ------------------------------------------------------------------ hotkeys */

const isTyping = (el) => el && (el.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName));

/** map: { key: handler }. Ignored while typing in a field (except Escape). */
export function useHotkeys(map, deps = []) {
  useEffect(() => {
    function onKey(e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key !== 'Escape' && isTyping(document.activeElement)) return;
      const fn = map[e.key];
      if (fn) {
        e.preventDefault();
        fn(e);
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
}

/* ------------------------------------------------------------------ modal */

export function Modal({ title, onClose, children, width = 560, labelledBy }) {
  useHotkeys({ Escape: onClose }, [onClose]);
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <div
        className="modal"
        role="dialog"
        aria-modal="true"
        aria-label={labelledBy ? undefined : title}
        style={{ width: `min(${width}px, 100%)` }}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="modal-head">
          <h2>{title}</h2>
          <button className="icon-btn" onClick={onClose} aria-label="Close">
            <Icon name="x" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Kbd({ children }) {
  return <kbd className="kbd">{children}</kbd>;
}
