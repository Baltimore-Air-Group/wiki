/**
 * BAG ↔ BookStack client glue — section 6 of docs/bookstack-theme.md.
 *
 * The BAG core API (api.baltimoreairgroup.org) is the source of truth
 * for staff identity and permissions. This module is loaded as an ES
 * module from the custom-head override and used to gate staff-only UI.
 *
 * The gate is purely a UX guard — BookStack's own per-page RBAC still
 * governs real access. Do not treat client-side hiding as security.
 */
import { PERM_MAP } from './perm-map.js';

const API = 'https://api.baltimoreairgroup.org';

let _mePromise = null;

/**
 * Fetch the current BAG staff identity. Singleton per page load so
 * multiple callers share one request. Resolves to null on any failure.
 */
export function fetchMe() {
  if (!_mePromise) {
    _mePromise = fetch(`${API}/api/auth/me`, { credentials: 'include' })
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null);
  }
  return _mePromise;
}

/** Resolve whether the current user holds a BAG permission key. */
export async function can(key) {
  const me = await fetchMe();
  return !!me?.staff?.permissions?.includes(key);
}

/**
 * Reveal elements tagged `data-staff-only="<key>"` for which the user
 * holds the permission, by setting `data-staff-granted`. bag.css keeps
 * them hidden until then, so this fails closed.
 *
 * Skips the network call entirely when the page has no gated elements.
 */
export async function applyPermissionGates(root = document) {
  const gated = root.querySelectorAll('[data-staff-only]');
  if (gated.length === 0) {
    return;
  }

  const me = await fetchMe();
  const held = new Set(me?.staff?.permissions ?? []);

  gated.forEach((el) => {
    const key = el.getAttribute('data-staff-only');
    if (key && !(key in PERM_MAP)) {
      console.warn(`[bag] data-staff-only="${key}" is not declared in perm-map.js`);
    }
    if (key && held.has(key)) {
      el.setAttribute('data-staff-granted', '');
    } else {
      el.removeAttribute('data-staff-granted');
    }
  });
}
