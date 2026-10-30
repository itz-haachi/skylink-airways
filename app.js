const SUPABASE_URL = 'https://fwtkhreboeccvcmpnslu.supabase.co';
const SUPABASE_KEY = 'sb_publishable_uUK4PbFJxnhZnoiYN6PEgg_TNEQqtaS';
const db = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

const fmt = t => new Date(t).toLocaleString('en-IN',
  { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });

const rupees = n => '₹' + Number(n).toLocaleString('en-IN');

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, c =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

async function currentUser() {
  const { data } = await db.auth.getSession();
  return data.session ? data.session.user : null;
}

function displayName(user) {
  const meta = user.user_metadata || {};
  return meta.first_name || user.email.split('@')[0];
}

function loginUrl(extra = '') {
  const here = window.location.pathname.split('/').pop() || 'index.html';
  return 'login.html?next=' + encodeURIComponent(here + window.location.search + extra);
}

async function requireLogin() {
  const user = await currentUser();
  if (!user) window.location.href = loginUrl();
  return user;
}

const STAR_PATH = 'M10 0 L12.2 7.8 L20 10 L12.2 12.2 L10 20 L7.8 12.2 L0 10 L7.8 7.8 Z';

async function renderHeader(activePage) {
  const user = await currentUser();

  let admin = false;
  if (user) {
    const { data } = await db.rpc('is_admin');
    admin = data === true;
  }

  const link = (href, text) =>
    `<a href="${href}"${href === activePage ? ' aria-current="page"' : ''}>${text}</a>`;

  const header = document.createElement('header');
  header.className = 'site-header';
  header.innerHTML = `
    <a class="brand" href="index.html">
      <svg viewBox="0 0 20 20" aria-hidden="true"><path d="${STAR_PATH}"/></svg>SkyLink Airways
    </a>
    <nav>
      ${link('index.html', 'Flights')}
      ${link('my-bookings.html', 'My bookings')}
      ${link('manage.html', 'Find a booking')}
      ${admin ? link('admin.html', 'Admin') : ''}
    </nav>
    <div class="account">
      ${user
        ? `<span>Signed in as <b>${esc(displayName(user))}</b></span>
           <button class="btn btn-ghost btn-small" id="signOutBtn">Sign out</button>`
        : `<a class="btn btn-primary btn-small" href="${loginUrl()}">Sign in</a>`}
    </div>`;
  document.body.prepend(header);

  if (user) {
    document.getElementById('signOutBtn').addEventListener('click', async () => {
      await db.auth.signOut();
      window.location.href = 'index.html';
    });
  }
  if (user) user.isAdmin = admin;
  return user;
}

const stars = [];

function drawStars() {
  if (document.getElementById('sky')) return;

  let seed = 7;
  const rand = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const specs = [];

  let svg = '<svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true">';

  for (let i = 0; i < 170; i++) {
    const x = rand() * 100, y = rand() * 100;
    const r = 0.5 + rand() * 1.2;
    const twinkle = rand() < 0.25 ? ' twinkle' : '';
    const delay = (rand() * 3.5).toFixed(2);
    const opacity = (0.45 + rand() * 0.55).toFixed(2);
    svg += `<circle class="star dot${twinkle}" cx="${x.toFixed(2)}%" cy="${y.toFixed(2)}%" r="${r.toFixed(2)}"
              style="opacity:${opacity};animation-delay:${delay}s"/>`;
    specs.push({ x, y, size: r * 2, centred: true });
  }

  for (let i = 0; i < 22; i++) {
    const x = rand() * 100, y = rand() * 100;
    const size = 7 + rand() * 11;
    const delay = (rand() * 3.5).toFixed(2);
    svg += `<svg class="star" x="${x.toFixed(2)}%" y="${y.toFixed(2)}%" width="${size.toFixed(1)}" height="${size.toFixed(1)}"
                 viewBox="0 0 20 20" overflow="visible">
              <path class="sparkle twinkle" d="${STAR_PATH}" style="animation-delay:${delay}s"/>
            </svg>`;
    specs.push({ x, y, size, centred: false });
  }

  svg += '</svg>';
  const sky = document.createElement('div');
  sky.id = 'sky';
  sky.innerHTML = svg;
  document.body.prepend(sky);

  sky.querySelectorAll('.star').forEach((el, i) => stars.push({ el, ...specs[i] }));

  startDimming();
  startShootingStars(sky);
}

function textRects() {
  const rects = [];
  const pad = 8;
  const add = r => {
    if (r.width && r.height) rects.push({ l: r.left - pad, r: r.right + pad, t: r.top - pad, b: r.bottom + pad });
  };

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
    acceptNode: n => n.textContent.trim() && !n.parentElement.closest('#sky, script, style')
      ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT
  });
  const range = document.createRange();
  while (walker.nextNode()) {
    range.selectNodeContents(walker.currentNode);
    for (const r of range.getClientRects()) add(r);
  }

  document.querySelectorAll('input, button, .btn').forEach(el => add(el.getBoundingClientRect()));
  return rects;
}

function dimStarsBehindText() {
  const rects = textRects();
  const w = window.innerWidth, h = window.innerHeight;

  for (const s of stars) {
    const cx = s.x / 100 * w + (s.centred ? 0 : s.size / 2);
    const cy = s.y / 100 * h + (s.centred ? 0 : s.size / 2);
    const half = s.size / 2;
    const covered = rects.some(r => cx + half > r.l && cx - half < r.r && cy + half > r.t && cy - half < r.b);
    s.el.classList.toggle('behind-text', covered);
  }
}

function startDimming() {
  let queued = false;
  const update = () => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => { queued = false; dimStarsBehindText(); });
  };

  window.addEventListener('scroll', update, { passive: true });
  window.addEventListener('resize', update);
  new MutationObserver(list => {
    if (list.some(m => !m.target.closest || !m.target.closest('#sky'))) update();
  }).observe(document.body, { childList: true, subtree: true, characterData: true, attributes: true,
                              attributeFilter: ['hidden', 'class', 'style'] });
  if (document.fonts) document.fonts.ready.then(update);
  update();
}

function startShootingStars(sky) {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const shoot = () => {
    const s = document.createElement('div');
    s.className = 'shooting';
    s.style.left = (5 + Math.random() * 60) + '%';
    s.style.top  = (15 + Math.random() * 50) + '%';
    sky.appendChild(s);
    setTimeout(() => s.remove(), 1300);
    setTimeout(shoot, 9000 + Math.random() * 9000);
  };
  setTimeout(shoot, 4000);
}

drawStars();
