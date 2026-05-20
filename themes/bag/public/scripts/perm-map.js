/**
 * BAG permission map — section 6.3 of docs/bookstack-theme.md.
 *
 * Single source of truth for which BAG core permission unlocks which
 * piece of BookStack UI. Do NOT sprinkle permission keys through Blade
 * templates: mark elements with `data-staff-only="<key>"` and let
 * bag.js toggle them in one pass.
 *
 * Keys must match the permission strings returned by the core API at
 * GET /api/auth/me under `staff.permissions[]`.
 *
 * SCOPE: this map gates non-content staff links only (org chart,
 * Discord shelf). It is a cosmetic UX guard, not enforcement.
 * Do NOT add a `wiki.write` key here — wiki write is enforced by a
 * BookStack RBAC role synced from the BAG `wiki-write` group. See
 * ../../SETUP.md.
 */
export const PERM_MAP = {
  'roles.read':      'Staff org chart book link in the sidebar.',
  'aircraft.manage': 'Edit links on Fleet book pages.',
  'routes.manage':   'Edit links on Route catalog pages.',
  'tickets.manage':  'Internal support runbook shelf.',
  'discord.manage':  'Discord ops shelf.',
};
