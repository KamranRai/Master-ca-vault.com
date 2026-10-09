/* CA-Vault site behaviour. Vanilla JS, no dependencies, progressive enhancement only. */
(function () {
  'use strict';
  var d = document, w = window;
  var $ = function (s, c) { return (c || d).querySelector(s); };
  var $$ = function (s, c) { return Array.prototype.slice.call((c || d).querySelectorAll(s)); };
  var reduce = w.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var desktop = w.matchMedia('(min-width: 960px)');
  var clamp = function (v, a, b) { return Math.min(b, Math.max(a, v)); };

  /* ---------- analytics hooks (GA4 / HubSpot ready) ---------- */
  w.dataLayer = w.dataLayer || [];
  function track(name, data) {
    var e = { event: name, page_path: location.pathname };
    for (var k in data) { e[k] = data[k]; }
    w.dataLayer.push(e);
  }
  w.caVaultTrack = track;
  d.addEventListener('click', function (ev) {
    var el = ev.target.closest('[data-event]');
    if (el) { track(el.getAttribute('data-event'), { location: el.getAttribute('data-loc') || '', label: (el.textContent || '').trim().slice(0, 60) }); }
    var a = ev.target.closest('a[href^="tel:"], a[href^="mailto:"]');
    if (a) { track(a.href.indexOf('tel:') === 0 ? 'phone_click' : 'email_click', {}); }
  });
  if (location.pathname.indexOf('/pricing/') !== -1) { track('pricing_view', { location: 'page' }); }
  if (location.pathname.indexOf('/customers/') !== -1) { track('case_study_view', {}); }

  /* ---------- navigation ---------- */
  var nav = $('#site-nav'), burger = $('.burger');
  var items = $$('.nav__item.has-menu');
  function closeMenus(except) {
    items.forEach(function (it) {
      if (it !== except) { it.classList.remove('is-open'); $('button', it).setAttribute('aria-expanded', 'false'); }
    });
  }
  items.forEach(function (it) {
    var btn = $('button', it), timer;
    btn.addEventListener('click', function () {
      var open = !it.classList.contains('is-open');
      closeMenus(it);
      it.classList.toggle('is-open', open);
      btn.setAttribute('aria-expanded', String(open));
    });
    it.addEventListener('mouseenter', function () {
      if (!w.matchMedia('(min-width: 1081px) and (hover: hover)').matches) { return; }
      clearTimeout(timer); closeMenus(it); it.classList.add('is-open'); btn.setAttribute('aria-expanded', 'true');
    });
    it.addEventListener('mouseleave', function () {
      if (!w.matchMedia('(min-width: 1081px) and (hover: hover)').matches) { return; }
      timer = setTimeout(function () { it.classList.remove('is-open'); btn.setAttribute('aria-expanded', 'false'); }, 160);
    });
  });
  d.addEventListener('click', function (ev) { if (!ev.target.closest('.nav__item.has-menu')) { closeMenus(); } });
  d.addEventListener('keydown', function (ev) {
    if (ev.key !== 'Escape') { return; }
    var open = $('.nav__item.is-open');
    if (open) { closeMenus(); $('button', open).focus(); }
    else if (nav && nav.classList.contains('is-open')) { toggleNav(false); burger.focus(); }
  });
  function toggleNav(open) {
    nav.classList.toggle('is-open', open);
    burger.setAttribute('aria-expanded', String(open));
    burger.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    d.body.style.overflow = open ? 'hidden' : '';
  }
  if (burger) { burger.addEventListener('click', function () { toggleNav(!nav.classList.contains('is-open')); }); }

  /* ---------- reveal on scroll ---------- */
  var revealEls = $$('[data-reveal]');
  if ('IntersectionObserver' in w && !reduce) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('is-in'); io.unobserve(e.target); } });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });
    revealEls.forEach(function (el) { io.observe(el); });
  } else { revealEls.forEach(function (el) { el.classList.add('is-in'); }); }

  /* ---------- sticky mobile CTA ---------- */
  var sticky = $('.sticky-cta'), foot = $('.foot');
  var noSticky = /\/book-demo\//.test(location.pathname);
  $$('[data-year]').forEach(function (el) { el.textContent = new Date().getFullYear(); });

  /* ---------- scroll-driven pieces (one rAF loop) ---------- */
  var scene = $('.scene'), mess = $('.mess');
  var canLive = !reduce && w.CSS && CSS.supports && CSS.supports('transform', 'translate(calc(1px * (1 - var(--p))), 0)');
  function setLive() { if (mess) { mess.classList.toggle('is-live', canLive && desktop.matches); } }
  setLive();
  if (desktop.addEventListener) { desktop.addEventListener('change', setLive); }
  var ticking = false;
  function onScroll() {
    if (ticking) { return; }
    ticking = true;
    requestAnimationFrame(function () {
      ticking = false;
      var y = w.scrollY, vh = w.innerHeight;
      if (sticky && !noSticky) {
        var nearFoot = foot && foot.getBoundingClientRect().top < vh - 40;
        sticky.classList.toggle('is-on', y > 520 && !nearFoot);
      }
      if (scene && !reduce) { scene.style.setProperty('--p', clamp(y / 420, 0, 1).toFixed(3)); }
      if (mess && mess.classList.contains('is-live')) {
        var r = mess.getBoundingClientRect();
        var p = clamp(-r.top / (r.height - vh), 0, 1);
        var eased = clamp((p - 0.08) / 0.72, 0, 1);
        mess.style.setProperty('--p', eased.toFixed(3));
        var st = $$('.mess__status span', mess);
        if (st.length === 3) {
          st[0].classList.toggle('is-on', eased < 0.34);
          st[1].classList.toggle('is-on', eased >= 0.34 && eased < 0.9);
          st[2].classList.toggle('is-on', eased >= 0.9);
        }
      }
    });
  }
  w.addEventListener('scroll', onScroll, { passive: true });
  w.addEventListener('resize', onScroll, { passive: true });
  onScroll();

  /* ---------- hero 3D record: pointer tilt ---------- */
  if (scene && !reduce && w.matchMedia('(hover: hover) and (min-width: 1020px)').matches) {
    var hero = scene.closest('.hero') || scene;
    hero.addEventListener('pointermove', function (ev) {
      var r = hero.getBoundingClientRect();
      scene.style.setProperty('--ry', (((ev.clientX - r.left) / r.width - 0.5) * 8).toFixed(2));
      scene.style.setProperty('--rx', (((ev.clientY - r.top) / r.height - 0.5) * -6).toFixed(2));
    });
    hero.addEventListener('pointerleave', function () { scene.style.setProperty('--ry', 0); scene.style.setProperty('--rx', 0); });
  }

  /* ---------- lifecycle: stages drive the product panel ---------- */
  var life = $('.life');
  if (life) {
    var stages = $$('.life__stage', life), shots = $$('.life__shots img', life), cap = $('.life__cap', life);
    var activate = function (i) {
      stages.forEach(function (s, n) { s.classList.toggle('is-active', n === i); s.classList.toggle('is-done', n < i); });
      shots.forEach(function (img, n) { img.classList.toggle('is-active', n === i); });
      if (cap) { cap.textContent = stages[i].getAttribute('data-cap') || ''; }
    };
    if ('IntersectionObserver' in w) {
      var lio = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) { if (e.isIntersecting) { activate(stages.indexOf(e.target)); } });
      }, { rootMargin: '-45% 0px -50% 0px' });
      stages.forEach(function (s) { lio.observe(s); });
    }
    activate(0);
  }

  /* ---------- unit-price grid: quantity x unit rate x progress ---------- */
  var upc = $('.upc');
  if (upc) {
    var fmt = function (n) { return '$' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); };
    var rows = $$('tbody tr', upc);
    var calc = function () {
      var gross = 0;
      rows.forEach(function (tr) {
        var qty = parseFloat(tr.getAttribute('data-qty')), rate = parseFloat(tr.getAttribute('data-rate'));
        var pct = parseInt($('input', tr).value, 10);
        var amt = qty * rate * pct / 100;
        gross += amt;
        $('.upc__pct', tr).textContent = pct + '%';

        $('.upc__amt', tr).textContent = fmt(amt);
      });
      var hold = gross * 0.10;
      $('[data-upc="gross"]', upc).textContent = fmt(gross);
      $('[data-upc="hold"]', upc).textContent = '-' + fmt(hold);
      $('[data-upc="net"]', upc).textContent = fmt(gross - hold);
    };
    upc.addEventListener('input', calc);
    calc();
  }

  /* ---------- annotated screenshot ---------- */
  $$('.anno').forEach(function (anno) {
    var pins = $$('.anno__pin', anno), list = $$('.anno__list li', anno.parentNode);
    var pick = function (i) {
      pins.forEach(function (p, n) { p.setAttribute('aria-pressed', String(n === i)); });
      list.forEach(function (l, n) { l.classList.toggle('is-on', n === i); });
    };
    pins.forEach(function (p, i) { p.addEventListener('click', function () { pick(i); }); p.addEventListener('mouseenter', function () { pick(i); }); });
    list.forEach(function (l, i) { l.addEventListener('mouseenter', function () { pick(i); }); });
  });

  /* ---------- role tabs ---------- */
  $$('.roles').forEach(function (roles) {
    var tabs = $$('[role="tab"]', roles), panels = $$('[role="tabpanel"]', roles);
    var select = function (i, focus) {
      tabs.forEach(function (t, n) { t.setAttribute('aria-selected', String(n === i)); t.tabIndex = n === i ? 0 : -1; });
      panels.forEach(function (p, n) { p.hidden = n !== i; });
      if (focus) { tabs[i].focus(); }
    };
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { select(i); });
      t.addEventListener('keydown', function (ev) {
        var k = ev.key, n = tabs.length;
        if (k === 'ArrowDown' || k === 'ArrowRight') { ev.preventDefault(); select((i + 1) % n, true); }
        if (k === 'ArrowUp' || k === 'ArrowLeft') { ev.preventDefault(); select((i + n - 1) % n, true); }
      });
    });
    select(0);
  });

  /* ---------- proof wall ---------- */
  var proof = $('.proof');
  if (proof) {
    var q = $('.quote', proof), btns = $$('.proof__btn', proof);
    btns.forEach(function (b) {
      b.addEventListener('click', function () {
        btns.forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        $('blockquote p', q).innerHTML = '“' + b.getAttribute('data-text') + '”';
        $('.avatar', q).textContent = b.getAttribute('data-initials');
        $('figcaption span:last-child', q).innerHTML = '<strong>' + b.getAttribute('data-name') + '</strong><br>' + b.getAttribute('data-role');
        var m = $('.quote__metric', q);
        if (m) { m.hidden = !b.getAttribute('data-metric'); }
        q.classList.remove('is-swap'); void q.offsetWidth; q.classList.add('is-swap');
        track('testimonial_select', { label: b.getAttribute('data-name') });
      });
    });
  }

  /* ---------- approval mark sequence ---------- */
  var marks = $('.marks');
  if (marks) {
    var lis = $$('li', marks);
    var run = function () { lis.forEach(function (li, i) { setTimeout(function () { li.classList.add('is-on'); }, reduce ? 0 : 350 + i * 520); }); };
    if ('IntersectionObserver' in w) {
      var mio = new IntersectionObserver(function (e) { if (e[0].isIntersecting) { run(); mio.disconnect(); } }, { threshold: 0.5 });
      mio.observe(marks);
    } else { run(); }
  }

  /* ---------- forms ---------- */
  $$('form[data-form]').forEach(function (form) {
    var kind = form.getAttribute('data-form'), started = false;
    form.addEventListener('focusin', function () { if (!started) { started = true; track(kind + '_form_start', {}); } });
    form.addEventListener('submit', function (ev) {
      var ok = true, first;
      $$('[required]', form).forEach(function (f) {
        var bad = !f.value.trim() || (f.type === 'email' && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(f.value));
        f.setAttribute('aria-invalid', String(bad));
        if (bad) { ok = false; first = first || f; }
      });
      if (!ok) { ev.preventDefault(); first.focus(); return; }
      track(kind === 'demo' ? 'demo_form_submit' : 'contact_submit', {});
      /* INTEGRATION POINT: replace this block with the HubSpot Forms API submission (portal + form GUID),
         then redirect on success. Until then the form goes straight to the thank-you page. */
      ev.preventDefault();
      location.href = form.getAttribute('action');
    });
  });
})();
