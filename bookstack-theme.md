# Baltimore Air Group — BookStack Theme & Integration Guide

This is the canon for the BAG-branded BookStack instance. It covers
visual identity (carrying [`docs/brand.md`](./brand.md) and
[`docs/ui-framework.md`](./ui-framework.md) into BookStack's templating
model), theme file layout, CSS overrides, and — critically — how the
BookStack frontend talks to the BAG core API for auth and permissions
without tripping CORS.

If you're adding a feature to the BookStack instance, this is the rules
file. Match it or get explicit sign-off to deviate.

---

## 1. Scope

BookStack is hosted at `wiki.baltimoreairgroup.org`. It's our internal
documentation surface — SOPs, livery install guides, training material,
fleet docs, anything that doesn't belong in code or in the ACARS spec.

It runs as a separate Laravel app, not part of the core repo. This
guide lives here because the visual identity and permission model are
shared with the core platform and must stay in sync.

**What this doc covers:**

- BAG-themed BookStack appearance (colors, fonts, headers, callouts).
- Where customizations live (theme directory, Blade overrides, asset
  pipeline).
- Calling the core BAG API from BookStack pages for permission gating.
- CORS configuration on the core API to allow those calls.

**What it does not cover:**

- Vanilla BookStack admin (RBAC, content trees, search). See the
  upstream docs.
- Hosting / Docker setup — that's in the infrastructure repo.

---

## 2. Visual identity — what carries over

Read [`brand.md`](./brand.md) first. The full identity rules apply:

- Maryland red `#ce1126`, Maryland gold `#ffcd00`, the same neutral
  scale, Inter typeface, the slogan, voice & tone.
- The logo lives at `/themes/bag/public/logo.svg`. Same image as the
  core frontend.
- **No emoji in copy**, unless the user is writing a note inside a page
  themselves. Chrome / system UI / templates stay clean.

What's BookStack-specific:

- BookStack ships its own iconography (Material Design Icons). Don't
  swap them for Lucide — pick MDI names that match the action. The
  rule is "use the platform's icon set, applied consistently."
- BookStack's `--color-primary` token controls primary buttons, link
  color, and accent strokes throughout the app. Set it once globally;
  don't override per-page.

---

## 3. Theme file layout

```
themes/bag/
├── settings.js                 # JS hook registrations (logo, footer, head)
├── public/
│   ├── logo.svg                # Identical to frontend/public/logo.svg
│   └── favicon.svg
├── styles/
│   ├── _tokens.scss            # CSS variable overrides (colors, radius, fonts)
│   ├── _components.scss        # Buttons, cards, callouts
│   ├── _typography.scss        # Headings, code, lists
│   └── bag.scss                # @import all of the above + entry point
├── partials/                   # Blade view overrides
│   ├── header.blade.php
│   ├── footer.blade.php
│   └── auth-required.blade.php
└── translations/               # If we add custom strings — keep en/ only
```

Activate with `APP_THEME=bag` in BookStack's `.env`. BookStack picks up
`themes/bag/styles/bag.scss` automatically via its asset pipeline.

**View overrides:** drop a Blade file with the same path as the
upstream view (e.g. `themes/bag/layouts/parts/header.blade.php`).
BookStack swaps it in. Don't fork views you aren't actively
customizing — every override is a future merge conflict.

---

## 4. Design tokens — BookStack mapping

BookStack uses its own SCSS variables. Map BAG tokens to them in
`_tokens.scss` so the rest of the theme inherits cleanly:

```scss
:root,
.light-mode {
  --color-primary: #ce1126;        // Maryland red
  --color-primary-light: #fbe5e8;
  --color-primary-dark:  #a30e1f;

  --color-secondary: #ffcd00;       // Maryland gold (accents)
  --color-secondary-light: #fff8d6;

  --color-link: var(--color-primary);
  --color-link-hover: var(--color-primary-dark);

  --color-positive: #2f7d3d;        // success
  --color-negative: #b91c1c;        // destructive
  --color-warning:  #b45309;

  --bg-page: #ffffff;
  --color-page-content: #1c1c20;

  --radius:    0.625rem;
  --radius-sm: 0.375rem;

  --font-body: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-heading: var(--font-body);
  --font-mono: ui-monospace, SFMono-Regular, Menlo, monospace;
}

.dark-mode {
  --color-primary: #f04254;          // softened red for dark
  --color-primary-light: #2a0d11;
  --color-primary-dark:  #ce1126;

  --bg-page: #16161a;
  --color-page-content: #f4f4f5;
}
```

**Why softened red in dark mode:** the same trick the core frontend
uses ([`frontend/src/index.css`](../frontend/src/index.css)) — pure
brand red on a near-black background fatigues the eye. Lighten the
hue, keep the brand-pure red for primary buttons on the light theme.

Load Inter from the same CDN the core app uses
(`https://rsms.me/inter/inter.css`) — don't self-host a different copy.

---

## 5. Components

Three patterns cover ~90% of customizations.

### 5.1 Page header strip

Replaces the default BookStack top bar with a slimmer one that mirrors
[AppLayout](../frontend/src/app/AppLayout.tsx):

```blade
{{-- themes/bag/layouts/parts/header.blade.php --}}
<header class="bag-header">
  <a href="{{ url('/') }}" class="bag-header__brand">
    <img src="{{ theme_path('public/logo.svg') }}" alt="Baltimore Air Group" />
  </a>
  <nav class="bag-header__nav">
    <a href="{{ url('/books') }}">Books</a>
    <a href="{{ url('/shelves') }}">Shelves</a>
    <a href="{{ url('/search') }}">Search</a>
  </nav>
  <div class="bag-header__user">
    @include('partials.user-menu')
  </div>
</header>
```

```scss
.bag-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1.5rem;
  border-bottom: 1px solid var(--color-border, #e4e4ea);
  background: var(--bg-page);

  &__brand img { height: 2rem; width: auto; }
  &__nav     { display: flex; gap: 0.25rem; }
  &__nav a {
    padding: 0.5rem 0.75rem;
    border-radius: var(--radius-sm);
    color: var(--color-muted, #4a4a52);
    text-decoration: none;

    &:hover, &.is-active {
      background: var(--color-primary-light);
      color: var(--color-primary);
    }
  }
  &__user { margin-left: auto; }
}
```

### 5.2 Callouts inside page content

BookStack supports custom callout blocks via the Markdown editor and
the WYSIWYG. Match the core app's `Card` aesthetic:

```scss
.callout {
  border-left: 3px solid var(--color-border);
  padding: 0.75rem 1rem;
  border-radius: var(--radius-sm);
  background: var(--bg-card, #fafafb);

  &.info     { border-color: #2563eb; background: #eff6ff; }
  &.success  { border-color: var(--color-positive); background: #ecfdf5; }
  &.warning  { border-color: var(--color-warning);  background: #fffbeb; }
  &.danger   { border-color: var(--color-negative); background: #fef2f2; }
}
```

Match the same accent colors the core uses for badges in
[`badge.tsx`](../frontend/src/components/ui/badge.tsx). Don't invent
new hues.

### 5.3 Code blocks

BookStack uses CodeMirror. Override the theme to match `Inter` body
and a near-black code background that doesn't fight `Card` containers
in the core app:

```scss
.cm-s-bookstack,
pre code {
  font-family: var(--font-mono);
  font-size: 0.875rem;
  background: #1c1c20;
  color: #f4f4f5;
  border-radius: var(--radius-sm);
}
```

---

## 6. Auth & permissions via the core API

The BAG core API (`api.baltimoreairgroup.org`) is the source of truth
for who a user is and what they can do. BookStack's own RBAC is for
**content** (books / shelves / pages) — it shouldn't try to mirror our
staff permissions.

**Pattern:** the BookStack frontend (custom JS in `themes/bag/`) calls
`/api/auth/me` with credentials. The response carries
`staff.permissions[]`. UI features (e.g. "Edit fleet docs" button) are
gated client-side on those keys. BookStack's own per-page edit perms
are unchanged — the gate is just a UX guard so unauthorized users
don't see staff-only buttons.

### 6.1 Client side — fetch in `settings.js`

```js
// themes/bag/scripts/bag.js
const API = 'https://api.baltimoreairgroup.org'

let _mePromise = null
export function fetchMe() {
  // Singleton — multiple components on a page can call this without
  // making redundant requests.
  if (!_mePromise) {
    _mePromise = fetch(`${API}/api/auth/me`, { credentials: 'include' })
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null)
  }
  return _mePromise
}

export async function can(key) {
  const me = await fetchMe()
  return !!me?.staff?.permissions?.includes(key)
}
```

Use it from Blade-injected scripts:

```html
<script type="module">
  import { can } from '{{ theme_path("scripts/bag.js") }}'
  if (await can('aircraft.manage')) {
    document.querySelectorAll('[data-staff-only="fleet"]').forEach(
      (el) => (el.hidden = false)
    )
  }
</script>
```

### 6.2 Server side — CORS on the core API

The BAG API currently locks CORS to a single origin (`APP_ORIGIN`).
For BookStack to call it from the browser with cookies, the API has to
allow `wiki.baltimoreairgroup.org` as well.

In [`api/src/index.ts`](../api/src/index.ts):

```ts
const ALLOWED_ORIGINS = new Set<string>()
// Populated at request time from env so prod / dev configs differ
// without code changes.
function isAllowedOrigin(origin: string, c: Context<{ Bindings: Env }>) {
  if (origin === c.env.APP_ORIGIN) return true
  // Comma-separated list in wrangler.toml: e.g.
  //   EXTRA_ALLOWED_ORIGINS = "https://wiki.baltimoreairgroup.org"
  const extras = (c.env.EXTRA_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
  return extras.includes(origin)
}

app.use(
  '/api/*',
  cors({
    origin: (origin, c) => (isAllowedOrigin(origin, c) ? origin : null),
    credentials: true,
    allowHeaders: ['content-type', 'authorization'],
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  }),
)
```

In `wrangler.toml`:

```toml
[env.production.vars]
APP_ORIGIN              = "https://baltimoreairgroup.org"
EXTRA_ALLOWED_ORIGINS   = "https://wiki.baltimoreairgroup.org"
```

**The non-obvious bits:**

- **Single origin per response.** `Access-Control-Allow-Origin: *` is
  forbidden with `credentials: true`. The handler returns the exact
  origin string from the request, not a wildcard. The allowlist gates
  which origins get reflected.
- **Subdomain cookies.** The session cookie is currently set with
  `Domain=` unset, which means it's host-only. For BookStack to send
  the cookie to `api.baltimoreairgroup.org`, the cookie needs
  `Domain=.baltimoreairgroup.org` so it applies to all subdomains.
  Update [`api/src/lib/session.ts`](../api/src/lib/session.ts) when
  enabling BookStack:

  ```ts
  setCookie(c, COOKIE, id, {
    httpOnly: true,
    secure: isHttps,
    sameSite: 'Lax',      // Lax is fine across subdomains
    path: '/',
    domain: '.baltimoreairgroup.org',  // ← share across wiki + app + api
    maxAge: ttl,
  })
  ```

  In dev (different hostnames or none), leave `domain` unset — Lax
  cookies work fine for same-host requests.
- **Preflight.** Any non-simple request (anything but plain `GET` /
  `POST` with no custom headers) triggers a CORS preflight (`OPTIONS`).
  The `allowMethods` list already covers everything we need.

### 6.3 Permission map — BAG → BookStack

| BAG permission         | BookStack hidden / shown                            |
| ---------------------- | --------------------------------------------------- |
| `roles.read`           | Show "Staff org chart" book link in the sidebar.    |
| `aircraft.manage`      | Show edit links on Fleet book pages.                |
| `routes.manage`        | Show edit links on Route catalog pages.             |
| `tickets.manage`       | Show "Internal support runbook" shelf.              |
| `discord.manage`       | Show Discord ops shelf.                             |
| *(no perm)*            | Member-only books still behind BookStack's own RBAC.|

The map lives in `themes/bag/scripts/perm-map.js` as a single object.
Don't sprinkle permission keys through templates — keep them keyed by
a CSS class (`data-staff-only="aircraft.manage"`) and let one JS pass
toggle visibility.

---

## 7. What NOT to do

- Don't re-implement BAG auth inside BookStack. Use the core
  `/api/auth/me` endpoint — single source of truth.
- Don't widen `EXTRA_ALLOWED_ORIGINS` to a regex or wildcard. Explicit
  hostnames only. Every entry is a place a cookie can leak.
- Don't add a separate "BAG menu" inside BookStack chrome — link to
  the main app via a small "Back to BAG" header link. BookStack is
  *a* surface, not the home base.
- Don't fork BookStack core. Theme overrides and the public API only.
  Forking forfeits security updates.

---

## 8. Versioning

This guide tracks BookStack 24.x. When BookStack ships a major release:

1. Check the upstream theme changelog for renamed CSS variables or
   moved Blade paths.
2. Re-test the four overrides we ship (header, footer, head, auth-required).
3. Bump the BookStack version pin in `infrastructure/bookstack/Dockerfile`.
4. Update this doc's version line below.

Last reviewed against: **BookStack 24.05** · 2026-05-17.
