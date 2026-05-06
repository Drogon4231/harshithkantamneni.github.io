/* ============================================================
   Motion choreography
   - Layer 1: ambient hero parallax (cursor-driven)
   - Layer 2: lab card 3D tilt (cursor-driven, hover only)
   - Layer 3: scroll reveal (intersection observer)
   - Theme toggle (persists to localStorage)
   ============================================================ */

(function () {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- Mobile menu (auto-injected from nav-links) ---------- */
  function injectMobileMenu() {
    const nav = document.querySelector('.site-header nav');
    if (!nav) return;
    const navLinks = nav.querySelector('.nav-links');
    const themeToggle = nav.querySelector('.theme-toggle');
    if (!navLinks || !themeToggle) return;
    if (nav.querySelector('.mobile-menu')) return;

    const details = document.createElement('details');
    details.className = 'mobile-menu';
    const summary = document.createElement('summary');
    summary.textContent = 'Menu';
    summary.setAttribute('aria-label', 'Open navigation menu');
    const panel = document.createElement('ul');
    panel.className = 'mobile-menu-panel';
    navLinks.querySelectorAll('li').forEach(li => panel.appendChild(li.cloneNode(true)));
    details.appendChild(summary);
    details.appendChild(panel);
    nav.insertBefore(details, themeToggle);
  }
  injectMobileMenu();

  /* ---------- Theme toggle ---------- */
  const root = document.documentElement;

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme);
    const label = document.getElementById('theme-label');
    if (label) label.textContent = theme === 'dark' ? 'light' : 'dark';
  }

  // Restore on load
  const saved = localStorage.getItem('theme') || 'dark';
  applyTheme(saved);

  window.toggleTheme = function () {
    const current = root.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    applyTheme(next);
    localStorage.setItem('theme', next);
  };

  /* ---------- Layer 1: Hero ambient parallax ---------- */
  if (!reduceMotion) {
    const heroes = document.querySelectorAll('.hero');
    heroes.forEach(hero => {
      const layer1 = hero.querySelector('.hero-parallax-layer-1');
      const layer2 = hero.querySelector('.hero-parallax-layer-2');
      if (!layer1 && !layer2) return;

      let rafId = null;
      hero.addEventListener('mousemove', (e) => {
        if (rafId) return;
        rafId = requestAnimationFrame(() => {
          const rect = hero.getBoundingClientRect();
          const cx = (e.clientX - rect.left) / rect.width - 0.5;
          const cy = (e.clientY - rect.top) / rect.height - 0.5;

          if (layer1) {
            layer1.style.transform = `translate3d(${cx * 16}px, ${cy * 16}px, 0)`;
          }
          if (layer2) {
            layer2.style.transform = `translate3d(${cx * 28}px, ${cy * 28}px, 0)`;
          }
          rafId = null;
        });
      });

      hero.addEventListener('mouseleave', () => {
        if (layer1) layer1.style.transform = '';
        if (layer2) layer2.style.transform = '';
      });
    });
  }

  /* ---------- Layer 2: Lab card tilt ---------- */
  if (!reduceMotion) {
    const tiltCards = document.querySelectorAll('.tilt-card');
    tiltCards.forEach(card => {
      let rafId = null;

      card.addEventListener('mouseenter', () => {
        card.style.transition = 'box-shadow 200ms ease, transform 0ms';
      });

      card.addEventListener('mousemove', (e) => {
        if (rafId) return;
        rafId = requestAnimationFrame(() => {
          const rect = card.getBoundingClientRect();
          const x = e.clientX - rect.left;
          const y = e.clientY - rect.top;
          const cx = (x / rect.width - 0.5) * 2;
          const cy = (y / rect.height - 0.5) * 2;

          const tiltX = -cy * 5;
          const tiltY = cx * 5;

          card.style.transform =
            `perspective(1200px) rotateX(${tiltX}deg) rotateY(${tiltY}deg) translateZ(0)`;
          rafId = null;
        });
      });

      card.addEventListener('mouseleave', () => {
        card.style.transition = 'transform 400ms cubic-bezier(0.32, 0.72, 0, 1), box-shadow 200ms ease';
        card.style.transform = 'perspective(1200px) rotateX(0) rotateY(0) translateZ(0)';
      });
    });
  }

  /* ---------- Layer 3: Scroll reveal ---------- */
  if (!reduceMotion && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -8% 0px' });

    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
  } else {
    // Reduced motion: just show everything
    document.querySelectorAll('.reveal').forEach(el => el.classList.add('in-view'));
  }
})();
