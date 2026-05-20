# BAG theme for BookStack

The Baltimore Air Group theme for `wiki.baltimoreairgroup.org`. Built
from [`bookstack-theme.md`](../../bookstack-theme.md) and BookStack's own
theme system ([visual](../../dev/docs/visual-theme-system.md) /
[logical](../../dev/docs/logical-theme-system.md)).

## Activate

Set this in BookStack's `.env`, then reload:

```env
APP_THEME=bag
```

BookStack then overrides views with the files under `themes/bag/` and
serves `themes/bag/public/` at the `/theme/bag/` URL path.

## What ships here

| Path | Role |
| ---- | ---- |
| `layouts/parts/custom-head.blade.php` | Override — keeps admin head content, adds Inter, `bag.css`, gating script. |
| `layouts/parts/header.blade.php` | Override — upstream header verbatim + `bag-header` class + "Back to BAG" link. |
| `layouts/parts/footer.blade.php` | Override — persistent BAG brand line. |
| `public/styles/bag.css` | Tokens, callouts, code blocks, staff-gating CSS. Served at `/theme/bag/styles/bag.css`. |
| `public/scripts/bag.js` | `fetchMe()` / `can()` / `applyPermissionGates()` against the core API. |
| `public/scripts/perm-map.js` | BAG permission → BookStack UI map (theme guide §6.3). |
| `public/logo.svg`, `public/favicon.svg` | Brand source assets (see "Logo" below). |

## Access model

Read and write access are **not** set by this theme — see
[`SETUP.md`](./SETUP.md):

- **Read** — fully public. A BookStack admin setting (`app-public`),
  plus view permissions on the Public role.
- **Write** — enforced by BookStack RBAC. A "Wiki Editor" role is
  granted at login via OIDC group sync from the BAG `wiki-write` group,
  so the BAG web app controls who can edit. BookStack natively shows or
  hides edit controls per role — the theme does nothing here.

## Staff-only UI (cosmetic only)

For **non-content staff links** that BookStack's RBAC has no opinion
about — the staff org-chart link, the Discord ops shelf (theme guide
§6.3) — tag the element with `data-staff-only="<bag-permission-key>"`.
`bag.css` hides it; `bag.js` reveals it when `GET /api/auth/me` confirms
the permission. Keys are catalogued in `perm-map.js`.

This is a UX guard, **not** enforcement, and is **not** used for wiki
read or write — those are handled per the Access model above.

## Where this differs from `bookstack-theme.md`

The theme guide is the design canon, but a few of its mechanics don't
match real BookStack. This implementation follows BookStack; the guide
should be corrected:

1. **No SCSS pipeline.** BookStack does not compile theme stylesheets.
   The guide's `themes/bag/styles/*.scss` + "asset pipeline" do not
   exist. Styles ship as plain CSS at `public/styles/bag.css`, linked
   from the `custom-head` override. Edit it directly — there is no build.
2. **Browser assets must live under `public/`.** The guide puts scripts
   at `themes/bag/scripts/`; BookStack only serves files under
   `themes/bag/public/`, at `/theme/bag/...`. `theme_path()` returns a
   server filesystem path — never use it as an `href`/`src`.
3. **No `settings.js` hook file.** BookStack's logical hooks are PHP
   (`functions.php` + the `Theme::` facade), not JS. Logo/footer/head
   are done via view overrides, which is what this theme does.
4. **View paths.** Overrides mirror `resources/views/`, so the header is
   `layouts/parts/header.blade.php`, not the guide's `partials/`.
5. **SVG isn't served as an image.** BookStack runs theme `public/`
   files through `WebSafeMimeSniffer`, which does not allow-list
   `image/svg+xml` — `/theme/bag/logo.svg` comes back as
   `application/octet-stream` and will not render in `<img>`. CSS/JS are
   fine. For the header logo, upload it via **Admin → Settings →
   Customization** (BookStack stores it properly), or supply a
   PNG/WebP (those types *are* allow-listed). `logo.svg` here is the
   editable brand source.
6. **CSP.** The inline gating script carries `{{ $cspNonce }}` — required
   by BookStack's `strict-dynamic` CSP. The Inter CDN (`rsms.me`) loads
   under the default `style-src`; if an admin restricts CSS sources
   (`app.css_sources` / `ALLOWED_CSS_SOURCES`), add `https://rsms.me`.

## Not in this repo

Two integration pieces live in the **core platform repo**, not here:

- **OIDC provider** — for the RBAC-enforced write model, BAG core must
  act as an OIDC provider and emit a `groups` claim containing
  `wiki-write`. See [`SETUP.md`](./SETUP.md) §2c.
- Theme guide §6.2 (CORS allow-list, `Domain=.baltimoreairgroup.org`
  session cookie) edits `api/src/index.ts`, `wrangler.toml` and
  `api/src/lib/session.ts`. These only matter for the cosmetic
  `/api/auth/me` staff-link gate; the browser side (`bag.js`) is here,
  the server side is not.

## Version control

`themes/.gitignore` was updated to track `themes/bag/` (BookStack ignores
`themes/` by default). The rest of `themes/` stays ignored.

Tracks BookStack 26.x. After a major BookStack upgrade, re-check the
three overrides (header, footer, custom-head) against upstream.
