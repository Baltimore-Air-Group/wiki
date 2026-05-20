# BAG wiki — instance setup

Access configuration for `wiki.baltimoreairgroup.org`. Two decisions:

- **Reading** — fully public, no login.
- **Writing** — enforced by BookStack's own RBAC, with membership driven
  by a BAG group via OIDC group sync.

The theme under `themes/bag/` only *styles* the instance. Access is set
here: BookStack's `.env`, the admin Settings UI, and BookStack roles.
None of this lives in committed files — `.env` and admin settings are
per-deployment — so this is a runbook, not code.

---

## 1. Public read

BookStack is private by default: a visitor with no account gets a login
screen. To open reading to everyone:

1. Sign in as an admin → **Settings → Features** → enable
   **"Allow public viewing"**. (This is the `app-public` setting; there
   is no `.env` variable for it.)
2. A built-in **"Public"** role now applies to logged-out visitors.
   Go to **Settings → Roles → Public** and grant view permissions
   (View on Shelves, Books, Chapters, Pages).
3. Public viewing is also gated per content item. New content inherits
   *default permissions* — make sure the Public role has "View" in the
   default set (**Settings → Roles → Public**, content permissions), or
   set it per shelf/book for anything that should be readable.
4. Search-engine indexing: `ALLOW_ROBOTS` defaults to follow the
   `app-public` setting, so the site will be indexable once public. Set
   `ALLOW_ROBOTS=false` in `.env` to opt out.

Result: anyone can read every page granted to the Public role; the login
button still works for editors.

---

## 2. Write — BAG-controlled, RBAC-enforced

**Model.** BookStack's own RBAC enforces who can edit — server-side, not
hideable. BAG stays in control by owning a group (`wiki-write`);
BookStack maps that group to an editor role each time a user logs in,
via OIDC group sync. No client-side button-hiding is involved.

### 2a. Point BookStack auth at BAG (OIDC)

In BookStack's `.env`:

```env
AUTH_METHOD=oidc
OIDC_NAME="Baltimore Air Group"
OIDC_CLIENT_ID=<issued by BAG core>
OIDC_CLIENT_SECRET=<issued by BAG core>
OIDC_ISSUER=https://api.baltimoreairgroup.org
OIDC_ISSUER_DISCOVER=true        # BAG serves /.well-known/openid-configuration
OIDC_EXTERNAL_ID_CLAIM=sub

# Group sync — this is what makes write BAG-controlled:
OIDC_USER_TO_GROUPS=true
OIDC_GROUPS_CLAIM=groups
OIDC_REMOVE_FROM_GROUPS=true

# Required: BAG only returns the groups claim when this scope is requested.
OIDC_ADDITIONAL_SCOPES=groups
```

If BAG core does **not** serve a discovery document, set
`OIDC_ISSUER_DISCOVER=false` and provide the endpoints manually:
`OIDC_AUTH_ENDPOINT`, `OIDC_TOKEN_ENDPOINT`, `OIDC_USERINFO_ENDPOINT`,
and `OIDC_PUBLIC_KEY`.

### 2b. Create the editor role in BookStack

**Settings → Roles → Create New Role:**

- **Display name:** `Wiki Editor` (anything readable)
- **External Authentication ID:** `wiki-write` — this *must* equal the
  BAG group name
- **Permissions:** Pages create + edit (add Chapters/Books create+edit,
  and delete, as the team wants)

How the match works (`app/Access/GroupSyncService.php`): the groups in a
user's OIDC token are matched to roles by the role's **External
Authentication ID** when set, otherwise by display name (lowercased,
spaces → hyphens). Setting it explicitly to `wiki-write` makes the link
unambiguous and survives renaming the role.

With `OIDC_REMOVE_FROM_GROUPS=true`, a user who loses the BAG group also
loses the Wiki Editor role — on their next login (see caveat below).

### 2c. What BAG core must provide (core platform repo, not this one)

- **An OIDC provider:** discovery document plus authorize / token /
  userinfo / JWKS endpoints. BookStack is the relying party.
- **A `groups` claim** in the ID token (or userinfo response) — an array
  that includes `wiki-write` for every member your web controller
  authorizes to edit the wiki.
- **Register BookStack as a client**, redirect URI:
  `https://wiki.baltimoreairgroup.org/oidc/callback`

The BAG web controller that grants and revokes the `wiki-write` group
*is* the "separate BAG-controlled wiki-write permission." Nothing in
BookStack decides who gets it — BookStack only enforces it.

---

## Timing caveat

Group sync runs **at login**. If BAG revokes `wiki-write`, the user keeps
edit access until their next BookStack login or session expiry. For
tighter revocation, shorten `SESSION_LIFETIME` in `.env`. The BookStack
role remains the enforcement point regardless.

---

## Relationship to the theme's client-side gate

`themes/bag/public/scripts/bag.js` + `perm-map.js` remain a **cosmetic**
layer for **non-content staff links only** (theme guide §6.3: the staff
org-chart link, the Discord ops shelf — things BookStack's RBAC has no
opinion about).

Wiki **read** and **write** are *not* gated there: read is public (§1),
write is the RBAC role (§2). Do **not** add a `wiki.write` key to
`perm-map.js` — that would imply client-side enforcement, which this
explicitly is not.
