# tasteofafrica.app — waitlist landing page

A single static page for **Taste of Africa**, a mobile cooking game set in a busy
African restaurant. Built from the Claude Design handoff: mobile is option `1c`,
desktop is the full-bleed treatment the handoff suggested as a next step
("make the video full-bleed behind everything in 2a") rather than `2a`'s split
column.

No build step, no framework, no third-party runtime request. Open `index.html`
and it works.

---

## Before going live — one thing to fill in

The form does nothing until you paste an endpoint. Open `index.html`, find:

```js
var WAITLIST_ENDPOINT = '';
```

Create a form on [formspree.io](https://formspree.io) (free tier: 50 submissions
a month) and paste its endpoint:

```js
var WAITLIST_ENDPOINT = 'https://formspree.io/f/abcdwxyz';
```

While the constant is empty the form **refuses to submit** and says so on screen,
so a signup can never be silently dropped.

The page sends a normal `multipart/form-data` POST and expects any 2xx back, so
Buttondown (`https://buttondown.email/api/emails/embed-subscribe/<user>`),
ConvertKit and Mailchimp's embedded endpoints work the same way. Fields sent:

| field      | value                                    |
|------------|------------------------------------------|
| `first`    | first name, trimmed                      |
| `email`    | email address                            |
| `platform` | `iOS`, `Android` or `not specified`      |
| `consent`  | `yes` (the form won't submit without it) |
| `_subject` | notification subject line for Formspree  |

A hidden `_gotcha` honeypot silently drops bots.

---

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
  intro.mp4                the gameplay clip (784×470, 5 s, silent, 630 kB)
  poster.jpg               first frame — stands in until the clip plays
  og.jpg                   1200×630 social preview card
  favicon.svg              tab icon
  apple-touch-icon.png     180×180 home-screen icon
  fonts.css                @font-face declarations
  fonts/*.woff2            self-hosted Bricolage Grotesque + IBM Plex Mono
tools/fetch-fonts.mjs      regenerates assets/fonts* from Google Fonts
CNAME  robots.txt  sitemap.xml  .nojekyll
```

### Fonts

Self-hosted on purpose: no request leaves the visitor's browser for
`fonts.gstatic.com`. Bricolage Grotesque is a variable font, so **one** 41 kB
file covers weights 500–800.

To refresh them:

```bash
node tools/fetch-fonts.mjs .
```

That rewrites `assets/fonts.css` with one `@font-face` per weight — if
Bricolage still ships as a variable font, re-collapse the three identical files
into `bricolage-grotesque-latin.woff2` with `font-weight: 500 800`, as the
committed `fonts.css` does.

### Regenerating the images

`poster.jpg`, `og.jpg` and `apple-touch-icon.png` are all derived from
`assets/intro.mp4` by `tools/make-images.swift` (macOS, no dependencies):

```bash
node tools/fetch-fonts.mjs .          # only needed once, for the TTFs below
swift tools/make-images.swift assets/intro.mp4 assets tools/ttf
```

The OG card is typeset in the real Bricolage Grotesque, loaded from
`tools/ttf/*.ttf`.

---

## Design notes — where the code departs from the mockups

Three deliberate changes, all easy to revert:

1. **Desktop layout: full-bleed, not `2a`'s split column.** The clip is
   landscape (784×470, ratio 1.67). Filling `2a`'s ~400×900 column with
   `object-fit: cover` crops away about 60% of the frame — the chef's head and
   the stove both disappear. Stretched across a 16:10 window instead, the same
   cover crop loses barely 4%. So the footage fills the viewport (`position:
   fixed`) and the headline, chips and ticket float over it, gathered at the
   foot behind a vertical scrim. The form still lands above the fold.
2. **Footer contrast.** `rgba(247,242,232,.34)` on `#12100D` is roughly 3:1 —
   under the WCAG AA floor for body text. Raised to `.48`/`.55`.
3. **A pause control on the video**, and no autoplay at all when the visitor has
   `prefers-reduced-motion: reduce` set.

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
