# tasteofafrica.app — waitlist landing page

A single static page for **Taste of Africa**, a mobile cooking game set in a busy
African restaurant. Built from the Claude Design handoff: mobile is option `1c`,
desktop is a two-column split — content left, the hero picture in a tall panel
on the right.

No build step, no framework. Open `index.html` and it works. The only
third-party request the page can ever make is the Meta pixel, and it stays
unloaded until the visitor accepts — see **Tracking** below.

---

## Before going live — one thing to fill in

The form does nothing until you paste an endpoint. Open `index.html`, find:

```js
var WAITLIST_ENDPOINT = '';
var WAITLIST_FORMAT = 'mailerlite';   // 'mailerlite' | 'plain'
```

**MailerLite** — create an embedded form, then
*Forms → Embedded forms → your form → Overview → "Embed form to your website" →
HTML tab*. Inside that snippet is a `<form action="…">`; that URL is the
endpoint. Keep `WAITLIST_FORMAT` as `'mailerlite'` so the payload is namespaced
the way MailerLite expects (`fields[name]`, `fields[email]`, plus `ml-submit`
and `anticsrf`).

**Formspree, Buttondown, ConvertKit, Mailchimp** — paste their endpoint and set
`WAITLIST_FORMAT` to `'plain'`, which sends flat field names.

Whichever you pick, **send one real test signup and confirm it lands** before
spending on ads. These embedded endpoints sometimes answer without CORS headers,
in which case the browser reports a failure even though the subscriber was
created — the page would then show an error to a visitor who did get added.
That is the one failure mode worth checking by hand.

While the constant is empty the form **refuses to submit** and says so on screen,
so a signup can never be silently dropped.

The page sends a normal `multipart/form-data` POST and expects any 2xx back, so
Buttondown (`https://buttondown.email/api/emails/embed-subscribe/<user>`),
ConvertKit and Mailchimp's embedded endpoints work the same way. Fields sent:

| meaning          | `plain`        | `mailerlite`            |
|------------------|----------------|-------------------------|
| first name       | `first`        | `fields[name]`          |
| email            | `email`        | `fields[email]`         |
| country, readable| `country`      | `fields[country]`       |
| ISO 3166-1 code  | `country_code` | `fields[country_code]`  |
| iOS / Android    | `platform`     | `fields[platform]`      |
| consent ticked   | `consent`      | — (the form won't submit without it either way) |

Both the country name and its code are sent on purpose: a column full of `SN` is
useless without a lookup table, and a column full of names is awkward to group
by. The name is always sent in the language the visitor was reading.

If the receiving end is MailerLite rather than Formspree, `country`,
`country_code` and `platform` each need a matching **custom field** created
there first, or they are silently dropped.

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

| token       | value     | used for                        |
|-------------|-----------|---------------------------------|
| `--ink`     | `#12100D` | page background                 |
| `--ink-warm`| `#16120E` | text on the ticket              |
| `--cream`   | `#F7F2E8` | text on the dark background     |
| `--paper`   | `#FBF6EC` | the waitlist ticket             |
| `--amber`   | `#E8A33D` | logo mark, accents              |
| `--rust`    | `#B4451F` | the primary button              |

Type: **Bricolage Grotesque** (display, 500/700/800) and **IBM Plex Mono**
(labels, 400/500/600).
