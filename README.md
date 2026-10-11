# CA-Vault website

Static, dependency-free site for CA-Vault (formerly ContractComplete). 44 pages generated from templates and data.

## Build and preview

```bash
powershell -ExecutionPolicy Bypass -File build.ps1
```

```bash
powershell -ExecutionPolicy Bypass -File serve.ps1
```

`build.ps1` writes the deployable site to `dist/` (upload that folder to any static host) and fails loudly on unknown macros; it also reports broken internal links. `serve.ps1` previews `dist/` at http://localhost:4321/. No Node or Python is required.

## Structure

| Path | Purpose |
|---|---|
| `src/pages/**.html` | Hand-written pages. Front matter (`title`, `description`, `label`, optional `schema`, `noindex`) in a leading HTML comment. File path = URL. |
| `src/data/features.json` | The 11 platform feature pages (one template). |
| `src/data/solutions.json` | The 6 role pages (one template). |
| `src/data/testimonials.json` | Customer quotes, referenced by id. |
| `src/data/screenshots.json` | Product screenshots, referenced by id. |
| `src/partials/` | Header and footer. |
| `src/assets/` | `css/site.css` (design system), `js/site.js` (all behaviour), images. |
| `src/static/` | `robots.txt`, `llms.txt`, `_redirects`. |

Macros available in any page: `{{crumbs}}`, `{{cta}}` or `{{cta:Heading|Text|Button}}`, `{{quote:id}}`, `{{shot:id|caption}}`, `{{features:slug,slug}}`, `{{ph:Kind|Title|Asset needed}}`.

To add a feature or role page, add an object to the JSON file. To add any other page, drop an HTML file in `src/pages/`.

---

## 1. Sitemap

```
/
/platform/
  bid-management/  contract-administration/  document-control/  rfi-management/
  submittals/  change-orders/  site-inspections/  progress-reporting/
  progress-billing/  payment-certification/  project-budgets/
/unit-price-contracts/            (pillar)
/solutions/
  civil-engineers/  landscape-architects/  consultants/
  contractors/  owners-developers/  municipalities/
/how-it-works/
/why-ca-vault/
  vs-spreadsheets-and-email/  vs-enterprise-construction-software/
/pricing/
/product-tour/
/customers/                       (customer stories + case-study slots)
/resources/
  blog/  guides/  glossary/  help-center/
/integrations/
/security/
/about/
  contractcomplete-to-ca-vault/
/contact/
/book-demo/
  thank-you/                      (noindex)
/legal/privacy/  /legal/terms/  /legal/accessibility/
/404.html  /sitemap.xml  /robots.txt  /llms.txt
```

## 2. Implemented pages

All 44 above are implemented. Pages with full content: home, platform overview, 11 feature pages, 6 solution pages plus index, how it works, why CA-Vault and both comparisons, unit-price pillar, pricing, product tour, customers, glossary, about, transition page, book demo, thank-you. Pages that are structured shells awaiting business content: security, integrations (Procore detail), help center, blog and guides (editorial plan shown as "coming soon"), contact details, privacy, terms.

## 3. Reusable components

Navigation with mega menu, footer, page hero, breadcrumbs, CTA band, product screenshot frame, placeholder block, testimonial (with optional metric), customer name wall, ledger (line-item list), old/new flow, chain (numbered steps), cards, FAQ accordion, comparison table, pricing cards and plan table, job card, form, table of contents, takeaway box, glossary list, stamp, sticky mobile CTA.

## 4. 3D and interactive elements

| # | Element | Where | Technique |
|---|---|---|---|
| 1 | 3D project record: screenshot over a stack of document sheets, pointer tilt, sheets collapse on scroll | Home hero | CSS 3D transforms |
| 2 | Fragments converge into one record (Fragmented, Connected, Controlled) | Home problem section | Sticky section, one CSS variable driven by scroll |
| 3 | Three parties, one record diagram with line-drawing | Home | SVG stroke animation |
| 4 | Tender-to-closeout lifecycle: stages activate and swap the product screen | Home | IntersectionObserver + sticky panel |
| 5 | Unit-price grid: sliders recalculate amount, holdback and certificate | Home | Live table on a tilted sheet |
| 6 | Annotated real bid-comparison screenshot | Home | Hotspots linked to captions |
| 7 | Approval mark: Submitted, Reviewed, Approved, Certified | Home, Why section | Sequenced CSS |
| 8 | Interactive customer wall | Home proof | Buttons swap the featured quote |
| 9 | Stamp on every CTA band; tilted frames on page heroes | Site-wide | CSS |

No WebGL and no animation library. Everything degrades to a static layout without JavaScript, on small screens, and under `prefers-reduced-motion`.

## 5. Placeholders (each is visible on the page with the asset needed)

| Location | What is needed |
|---|---|
| Home, product tour | CA-Vault-branded 2-minute explainer and 3-minute chaptered tour videos |
| Feature pages: document control, submittals, site inspections; How it works: tender, inspect | Current product screenshots of those screens (2000px WebP) |
| Feature pages: RFIs, submittals, change orders, inspections, budgets | A customer quote specific to that feature |
| Solutions: owners, municipalities | A customer story from that audience |
| Customers | Three approved case studies |
| Customer wall (home, customers) | Verified official logos and permission for each named organisation |
| Pricing | Confirmation of onboarding time and which plans include guided onboarding |
| Book demo | HubSpot portal ID and form GUID; optional meetings link |
| Guides | Final downloadable checklists/templates and their forms |
| Help center | Final help URL and migrated articles |
| Integrations | Confirmed Procore scope, setup steps and logo permission |
| Security | Verified hosting, encryption, authentication, backup, data ownership and any certifications actually held |
| About | Team, location, dated milestones |
| Transition page | Login/URL changes, subscription handling, redirect date, support contact |
| Contact | Email, phone, hours, address |
| Privacy, terms, accessibility | Legally reviewed documents |

## 6. SEO implementation

- Unique title, meta description, canonical, Open Graph and Twitter tags on every page.
- JSON-LD generated at build: Organization (all pages), WebSite (home), SoftwareApplication (home, platform, features), BreadcrumbList (all inner pages), FAQPage (auto-extracted from any FAQ accordion on the page), Article (pillar, comparisons, glossary).
- One H1 per page, ordered headings, direct-answer paragraph near the top of each feature page, FAQs, tables, breadcrumbs, internal link network (feature to related features to pricing/demo; role to features to proof to demo).
- `sitemap.xml` generated on build, `robots.txt`, and `llms.txt` for AI retrieval.
- Clean directory URLs; thank-you and 404 are `noindex`.

## 7. Performance strategy

No framework, one CSS file (56 KB) and one deferred JS file (12 KB), both unminified for now. Hero image uses `fetchpriority="high"`; every other image is lazy-loaded with explicit dimensions to prevent layout shift. 3D is CSS transforms only. Scroll effects run in one `requestAnimationFrame` loop writing a single CSS variable. Still to do at deploy: minify CSS/JS, self-host the two fonts, generate 800/1200px image variants with `srcset`, enable compression and long cache headers. Core Web Vitals have not been measured; run Lighthouse on the deployed URL.

## 8. Mobile and responsive strategy

Mobile order is headline, value proposition, CTA, product. The 3D scene flattens, floating cards become a grid, the sticky convergence section becomes a static before/after, the lifecycle shows screenshots inline, tables scroll inside their own container, the nav becomes a full-screen panel, and a sticky "Book a Demo" bar appears after the first screen. Breakpoints at 520, 620, 760, 900, 960, 1020 and 1080px.

## 9. CRO strategy

Primary CTA "Book a Free Demo" in the nav, hero, every CTA band and the mobile sticky bar; secondary "Watch Product Tour". Intent-specific CTA labels throughout, no "Learn more" or "Submit". Proof placed beside the feature it supports. Pricing is published. Demo form has five required fields and two optional ones, and leads to a thank-you page with next steps.

## 10. Analytics and event plan

`site.js` pushes to `window.dataLayer` (GA4 / GTM / HubSpot ready). No tracking script is installed yet.

| Event | Trigger |
|---|---|
| `demo_cta_click` (with `location`) | Any demo CTA |
| `demo_form_start`, `demo_form_submit` | Demo form focus / valid submit |
| `contact_form_start`, `contact_submit` | Contact form |
| `product_tour_start` | Tour CTAs |
| `pricing_view`, `pricing_cta_click` | Pricing page load / plan buttons |
| `case_study_view` | Customers page load |
| `login_click`, `phone_click`, `email_click` | Respective links |
| `testimonial_select` | Customer wall |

To wire up: `video_start`, `video_complete`, `product_tour_complete` and `resource_download`, once the videos and downloads exist. Forms currently validate and redirect to the thank-you page without sending data anywhere; the integration point is marked in `site.js`.

## 11. ContractComplete to CA-Vault migration

`src/static/_redirects` holds a first-pass 301 map from the known ContractComplete URLs. Before launch: export all indexed URLs and backlink targets from Search Console, extend the map, audit blog posts individually (keep, rewrite, redirect, remove, consolidate), add the new property to Search Console, submit the sitemap, use the change-of-address tool, and monitor 404s and rankings. Confirm the canonical host (`https://www.ca-vault.com` is set in `build.ps1`).

## 12. Assumptions

- "AI focused" was read as AI-search readiness (AEO/GEO: structured data, direct answers, `llms.txt`). No AI product features are claimed, because none were supplied.
- Fonts are Nunito and JetBrains Mono, chosen to match the product UI in the screenshots.
- The Login link points to `app.contractcomplete.com`.
- The transparent logo PNG and the favicon were derived from the supplied JPG; an official SVG should replace them.
- Customer organisations are shown as text names, not logos.
- The milestone order on the About page is inferred and undated.

## 13. Claims that need business verification

- "Since 2015" and "Formerly ContractComplete" wording.
- "Under 60 minutes" onboarding (historical ContractComplete claim).
- All seven testimonial excerpts: they were collected through an automated summary of contractcomplete.com, so check each word-for-word against the source and confirm permission to reuse under the CA-Vault name. Note the old homepage spells one company "About & Associates"; this site uses "Aboud & Associates".
- The twelve customer organisation names.
- Pricing, taken from ca-vault.com on 2026-10-08: currency is not stated there; the three FAQ answers on upgrades, projects and annual billing are inferences from the plan table.
- Feature descriptions drawn from the old site and screenshots: bid exports to PDF/Excel, submission-requirement enforcement, ActionBox reminders, mobile signing, RFI image markup, submittal forwarding, iOS/Android apps, Procore integration.
- The pricing page lists "subcontracts" and "progress draws", terms not used elsewhere on this site; align terminology.

## 14. Missing assets before launch

Official logo SVG and favicon set; branded videos; the missing screenshots listed in section 5; customer logos and approvals; case studies; legal documents; contact details; security facts; HubSpot and GA4 IDs; a social share image (currently the dashboard screenshot); the final redirect map.

---

## Deploying to GitHub Pages

GitHub Pages serves this repository from the `docs/` folder (Settings > Pages > Branch `main`, folder `/docs`). Because a project site lives under `/Master-ca-vault.com/`, it needs its own build with a base path. After any change in `src/`, run this from PowerShell and commit the result:

```
powershell -ExecutionPolicy Bypass -File build.ps1 -Base "/Master-ca-vault.com" -OutDir docs -Site "https://kamranrai.github.io/Master-ca-vault.com"
```

Once a custom domain (for example www.ca-vault.com) is attached, drop `-Base` and `-Site` so URLs are served from the root.

---

## Version 2 additions

- Light/dark switch in the header (choice saved in the browser; light is the default).
- Site search: the header search button opens a search bar. The index (`search.json`) is generated by `build.ps1` from every page's title, description and headings.
- Header logo rebuilt as mark + wordmark so the helmet mark spans both the name and "Formerly ContractComplete". Files: `ca-vault-mark.png`, `ca-vault-wordmark.png`, `ca-vault-wordmark-light.png` (for dark backgrounds), all derived from the supplied JPG.
- Twelve customer logos (`src/assets/img/customers/`) on the home page, customers page, demo page and in the trust row above every call-to-action band.
- "What does CA mean" explainer on the home and About pages, plus the footer, glossary, platform FAQ and transition FAQ. Wording: Contract Administration, also called Construction Administration.
- Statistics (`src/partials/stats.html`) with sources shown: Capterra 4.8/5 from 21 reviews and 5.0/5 support (checked 2026-10-11), "$5,000 saved on first three bids" and "100s of businesses" (both from contractcomplete.com).
- Real portraits for Mario Patitucci and Mark Garon-Nielsen, taken from the ContractComplete testimonials page. Other customers keep initials because no portrait is published there.
- Social links in the footer (LinkedIn, Facebook, Instagram).

Still to verify: Capterra lists the company as founded in 2013, while this site says "since 2015"; permission to display each customer logo and portrait.
