# tasteofafrica.app — waitlist landing page

A single static page for **Taste of Africa**, a mobile cooking game set in a busy
African restaurant. Built from the Claude Design handoff: mobile is option `1c`,
desktop is a two-column split — content left, the hero picture in a tall panel
on the right.

No build step, no framework. Open `index.html` and it works. The only
third-party request the page can ever make is the Meta pixel, and it stays
unloaded until the visitor accepts — see **Tracking** below.

---

## Where signups go

Wired to **MailerLite**, verified end to end on 2026-08-09.

```js
var WAITLIST_ENDPOINT = 'https://assets.mailerlite.com/jsonp/2565278/forms/195326870943696122/subscribe';
var WAITLIST_FORMAT = 'mailerlite';   // 'mailerlite' | 'plain'
```

Account `2565278`, form *Waitlist tasteofafrica.app*, subscribers land in the
**Waitlist** group. The endpoint answers `{"success":true}` with CORS headers, so
the page can tell a real success from a real failure — no guessing.

| meaning          | sent as                | MailerLite field |
|------------------|------------------------|------------------|
| first name       | `fields[name]`         | Name (built-in)  |
| email            | `fields[email]`        | Email            |
| country, readable| `fields[country]`      | Country (built-in) |
| ISO 3166-1 code  | `fields[country_code]` | Country code (custom) |
| iOS / Android    | `fields[platform]`     | Platform (custom) |

plus `ml-submit=1` and `anticsrf=true`, which the endpoint requires. `Country
code` and `Platform` were created by hand under *Subscribers → Fields*; delete
them and those two values are silently dropped.

**Segment on `Country code`, never on `Country`.** The readable name is sent in
whatever language the visitor was reading, so the Country column legitimately
mixes `Sénégal` and `Senegal`. The code is the stable key.

⚠️ **Double opt-in is ON.** A signup lands as *Unconfirmed* and is not on the
list until they click the confirmation email — so they will not appear under the
default "Active" filter, only under "Unconfirmed". The confirmation copy on the
page says so ("open the email we just sent and confirm"). Two consequences: the
Meta `Lead` event fires on submit, not on confirmation, so it will always read
higher than the confirmed count; and if you switch double opt-in off in
MailerLite, change `doneBody` in both languages back to a plain "you're on the
list".

Switching provider: paste another endpoint and set `WAITLIST_FORMAT` to
`'plain'`, which sends flat field names (`first`, `email`, `country`, …) as
Formspree, Buttondown, ConvertKit and Mailchimp expect.

A hidden `_gotcha` honeypot silently drops bots.

---

## The country field

262 options in a `<select>` is unusable with a thumb, so the field is a
**type-ahead**: type two letters, pick from at most 8 suggestions.

It is a **progressive enhancement, not a replacement**. The `<select>` is still
in the DOM and is still the control that submits — the script hides it and writes
`select.value` when a suggestion is chosen. So validation, the payload and the
`Intl.DisplayNames` translation all keep working untouched, and with JavaScript
off the plain dropdown is what a visitor gets.

Matching is accent- and case-blind in both directions (`senegal` finds
`Sénégal`, `SÉNÉ` finds it too, `cote` finds `Côte d'Ivoire`) via
`normalize('NFD')`. Ranking puts prefix matches above substring matches, and
**African countries above the rest within each** — that is the audience. With
nothing typed yet, the list offers African countries as a hint.

Someone who types a full name and tabs away without touching the list still gets
resolved, and so does a query with exactly one match. Anything left unresolved
clears the select and is refused by the form, with the field outlined in
`--rust` — but only after they leave it, not on the first keystroke.

Keyboard: ↓ ↑ to move, Enter to take, Escape to close. The list is a
`role="listbox"` driven by `aria-activedescendant`, the input a `role="combobox"`.

## English and French

One page, one URL, a `EN | FR` switch at the top right. **Every visible string
lives in the `T` object** at the top of the `<script>` — two flat tables, 45
keys each, kept at parity. Nothing is duplicated in the markup: elements carry

| attribute | what it sets |
|-----------|--------------|
| `data-i18n` | `textContent` |
| `data-i18n-html` | `innerHTML` (only the headline and colophon, which contain tags) |
| `data-i18n-ph` | `placeholder` |
| `data-i18n-aria` | `aria-label` |
| `data-i18n-label` | an `<optgroup>`'s `label` |

The switch also sets `<html lang>`, the `<title>` and the meta description, and
remembers the choice in `localStorage` (`toa-lang`). First visit with no stored
choice follows `navigator.language`.

**Country names are not in the table.** `Intl.DisplayNames` translates them from
their ISO codes at runtime, so 262 countries cost zero extra bytes in either
language — and the list is re-sorted alphabetically for the active language
(French starts at "Afrique du Sud", English at "Algeria"). A visitor's
already-picked country survives the switch.

Text that depends on state as well as language — the current error message, the
"Order in, Aminata." confirmation, the country field's visible label — re-renders
through the `restate` array, so switching language mid-session never leaves a
stale sentence on screen.

Adding a third language means adding one key set to `T` and one button; nothing
else changes. If French SEO ever matters, that is the point to split into
`/fr/` pages with `hreflang` instead — a JS switch is invisible to crawlers.
For ad traffic, which is what this page is for, it does not matter.

## Tracking

The Meta pixel (`4098993507059369`) is wired in, **behind a consent bar**. Two
constants at the top of the `<script>` control it: `PIXEL_ID` and `CONSENT_KEY`.

- Nothing loads until the visitor clicks **Accept**. Before that, `fbq` does not
  exist and no request goes to `connect.facebook.net` or `facebook.com`.
- The answer is remembered in `localStorage` under `toa-pixel-consent`
  (`granted` / `denied`). To see the bar again while testing:
  `localStorage.removeItem('toa-pixel-consent')`, then reload.
- On accept: `PageView`. On a completed signup: **`Lead`** — that is the event
  Meta can optimise delivery towards, so use it as the conversion in Ads
  Manager, not link clicks.
- **Meta's `<noscript>` fallback image is deliberately left out.** It fires on
  page load with no way to ask first, which is exactly what the consent bar
  exists to prevent. The cost is that visitors with JavaScript off are not
  counted — a rounding error, and they could not submit the form anyway.

Emptying `PIXEL_ID` disables the whole thing, bar included.

## Deploying to GitHub Pages

1. Push this folder as the root of a repository.
2. **Settings → Pages → Source: Deploy from a branch**, branch `main`, folder `/`.
3. The `CNAME` file already claims `tasteofafrica.app`. At the registrar, point
   the domain at GitHub Pages:

   | type  | host  | value                                                            |
   |-------|-------|------------------------------------------------------------------|
   | A     | `@`   | `185.199.108.153` `185.199.109.153` `185.199.110.153` `185.199.111.153` |
   | AAAA  | `@`   | `2606:50c0:8000::153` `2606:50c0:8001::153` `2606:50c0:8002::153` `2606:50c0:8003::153` |
   | CNAME | `www` | `<user>.github.io.`                                              |

4. Back in **Settings → Pages**, tick **Enforce HTTPS** once the certificate is
   issued (can take up to an hour after the DNS propagates).

`.nojekyll` is present so GitHub serves the files as-is.

---

## What's in here

```
index.html                 the whole page — markup, CSS and JS
404.html                   branded not-found page
assets/
  hero.jpg                 the hero picture (960×1538, 312 kB)
  intro.mp4                the old intro clip — no longer used by the page,
                           kept because it is still useful for ad creative
  poster.jpg               its first frame — likewise unused now
  og.jpg                   1200×630 social preview card
  logo.png                 256×256 round badge — the header mark
  favicon-32/48.png        the simplified ring mark (see Logo below)
  favicon-192.png          full artwork, for Android home screens
  apple-touch-icon.png     180×180 iOS home-screen icon
  fonts.css                @font-face declarations
  fonts/*.woff2            self-hosted Bricolage Grotesque + IBM Plex Mono
logo-master.jpg            the source artwork (in tools/)
tools/fetch-fonts.mjs      regenerates assets/fonts* from Google Fonts
tools/make-logo.swift      derives every logo asset from the master
CNAME  robots.txt  sitemap.xml  .nojekyll
```

### Fonts

Self-hosted on purpose: no request leaves the visitor's browser for
`fonts.gstatic.com`, whatever they answer on the consent bar.
Bricolage Grotesque is a variable font, so **one** 41 kB
file covers weights 500–800.

To refresh them:

```bash
node tools/fetch-fonts.mjs .
```

That rewrites `assets/fonts.css` with one `@font-face` per weight — if
Bricolage still ships as a variable font, re-collapse the three identical files
into `bricolage-grotesque-latin.woff2` with `font-weight: 500 800`, as the
committed `fonts.css` does.

### Logo

The master artwork is `tools/logo-master.jpg` (1254×1254, the illustration on a
uniform cream field). Everything else derives from it:

```bash
swift tools/make-logo.swift tools/logo-master.jpg assets
```

The script finds the artwork inside the cream field on its own — it measures the
true radius rather than the bounding box, because the leaves poke out past the
ring at the lower left and a box-based crop clips them. Replace the master and
re-run; no coordinates are hard-coded.

**The illustration does not survive small sizes.** It is a face, a patterned
headwrap, a bowl of individual foods, leaves, a map and a tricolour ring — below
about 56px that is a brown smudge. So:

| size | what is shown |
|------|---------------|
| 16–48px (favicon) | the **tricolour ring alone**, no figure |
| 180px+ (home screens, OG card) | the full artwork |
| header mark | 52px mobile / 64px desktop — the floor at which the figure reads |

The ring's three colours (`#E8A526` amber, `#B14110` rust, `#44691A` green) were
sampled off the master, and land within a few points of the page's own `--amber`
and `--rust`. If the logo ever changes, re-sample them: the arc angles and
colours are the `arcs` array in `make-logo.swift`.

The header mark is an `<img>` on a transparent-cornered round badge. The artwork
has a cream field and a white keyline drawn around the figure — it is designed to
sit on light, so dropping it straight onto `#12100D` would show that keyline as a
cut-out halo. The cream disc is what makes it sit correctly on the dark page.

### Regenerating the images

`hero.jpg` and `og.jpg` are both derived from `tools/hero-master.png` by
`tools/make-images.swift` (macOS, no dependencies):

```bash
node tools/fetch-fonts.mjs .          # only needed once, for the TTFs below
swift tools/make-images.swift tools/hero-master.png assets tools/ttf
```

The OG card is typeset in the real Bricolage Grotesque, loaded from
`tools/ttf/*.ttf`.

---

## Design notes — where the code departs from the mockups

Three deliberate changes, all easy to revert:

1. **The hero is a picture, not the video, and it drives the layout.** The
   artwork (`tools/hero-master.png`, 960×1538) is portrait. Full-bleed across a
   16:10 window, a cover crop keeps two faces and throws away the queue of
   waiting customers — the whole subject of the shot. So it gets a tall panel:
   `clamp(320px, 30vw, 440px)`, one viewport high and `sticky`, which keeps
   about 75% of its width at 1280px. Two consequences worth knowing:
   the panel is capped at `100dvh` because a grid row would otherwise stretch
   it to the full scroll height and the crop would eat the scene; and the left
   column only splits into headline-beside-ticket above **1250px**, below which
   it cannot carry both and stacks them instead.

   The master is only 960px wide, which is thin for a panel on a 2× display —
   if a larger export exists, drop it in and re-run `make-images.swift`.
2. **Footer contrast.** `rgba(247,242,232,.34)` on `#12100D` is roughly 3:1 —
   under the WCAG AA floor for body text. Raised to `.48`/`.55`.
3. **No dish chips, and no country blocks.** A "one country, one menu" section
   with three flagged countries was mocked up and rejected: pinning the page to
   Senegal, Cameroon and Côte d'Ivoire recreates the promise-break it was meant
   to fix, for every *other* country advertised to. The lede paragraph carries
   the journey in prose instead, naming both the countries and the dishes — at
   which point a 12-chip list repeated it word for word, pushed the submit
   button below the fold on a 1280×760 laptop, and was removed.

   Matching an ad to the page is better done with a campaign parameter
   (`?c=cm` → lead with Cameroon, pre-fill the country field), which serves all
   262 countries already in the form. **Not built yet.**

Faithful to the mockups: the recipe chips (Thieboudienne / Mafé / Poulet DG /
Ndolé) appear on desktop only — mobile option `1c` doesn't have them. Deleting
the `.chips { display: none; }` rule brings them back on mobile.

Breakpoint: **900px**. Below it, the stacked mobile layout (`1c`); above it, the
split screen (`2a`).

---

## Tokens

The page is **light**: a warm sand ground, a cream ticket, white input fields.
Three steps of warmth carry the hierarchy, so nothing needs a heavy shadow.

| token       | value     | used for                             |
|-------------|-----------|--------------------------------------|
| `--page`    | `#F2EADC` | page background — warm sand          |
| `--paper`   | `#FBF6EC` | the waitlist ticket                  |
| `--ink`     | `#16120E` | headings and primary text            |
| `--cream`   | `#F7F2E8` | text laid **over the photograph** only |
| `--amber`   | `#E8A33D` | accents over imagery only            |
| `--rust`    | `#B4451F` | the primary button, and links        |

**`--amber` is not a text colour on this page.** At `#E8A33D` on sand it fails
contrast badly, so links use `--rust`; amber survives only where it sits on the
photograph (the "THE LUNCH RUSH" caption).

Every small-text colour was measured rather than eyeballed, and raised until it
cleared the 4.5:1 AA floor: the colophon, the launch badge, the inactive
language button, the ticket header and the field labels all sat between 3.4:1
and 4.1:1 at first pass. The field labels had been under the floor since the
original dark design.

Two things the light theme forced, beyond swapping colours:

1. **The desktop caption moved to the right of the panel.** The panel's left
   edge now fades into the sand page instead of into near-black, so an amber
   caption placed there had nothing to sit on.
2. **The logo badge gained a hairline ring.** Its own field is cream, which
   melts into a sand page without one.

`assets/og.jpg` is deliberately left dark — it is a social preview card laid
over the photograph, not a page, and dark cards read better in a feed.

Type: **Bricolage Grotesque** (display, 500/700/800) and **IBM Plex Mono**
(labels, 400/500/600).
