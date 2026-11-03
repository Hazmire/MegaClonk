"""Out-of-bounds backdrop strips for the Calvary Run stages.
Each stage gets 3 layers (far, mid, near): 2048x256 RGBA, seamless left-right, hard alpha (PSX cut-out),
flat silhouette colour with a little dithered shading and lit windows. In Godot they wrap around the arena
on open cylinders at ~90 / 140 / 210 m, behind the fog wall."""
import numpy as np, math, os
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter

W, H = 2048, 512
BASE = H - 200        # ground line: every layer has 200 px of solid hillside below it, so its foot
                     # always sits deep in the fog bank and the cut-off edge of the strip is never seen
GROUND = {}
os.makedirs('out', exist_ok=True)
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16 - 0.47

def hexc(h): h = h.lstrip('#'); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.float32)

class Layer:
    def __init__(self):
        self.im = Image.new('L', (W * 3, H), 0); self.d = ImageDraw.Draw(self.im)
        self.lights = []
    def _w(self, pts): return [[(x + W + o, y) for x, y in pts] for o in (-W, 0, W)]
    def poly(self, pts, v=255):
        for p in self._w(pts): self.d.polygon(p, fill=v)
    def rect(self, x0, y0, x1, y1, v=255): self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], v)
    def line(self, pts, w=1, v=255):
        for p in self._w(pts): self.d.line(p, fill=v, width=w)
    def ell(self, x0, y0, x1, y1, v=255):
        for o in (-W, 0, W): self.d.ellipse([x0 + W + o, y0, x1 + W + o, y1], fill=v)
    def light(self, x, y, col, w=2, h=2): self.lights.append((x % W, y, col, w, h))
    def mask(self): return np.asarray(self.im, np.float32)[:, W:2 * W] / 255.0

def profile(base, amp, seed, sigma):
    r = np.random.default_rng(seed)
    p = gaussian_filter(r.random(W), sigma, mode='wrap'); p = (p - p.min()) / max(np.ptp(p), 1e-6)
    q = gaussian_filter(r.random(W), max(sigma / 5, 1), mode='wrap'); q = (q - q.min()) / max(np.ptp(q), 1e-6)
    return base + amp * (0.8 * p + 0.2 * q)

def ridge(L, base, amp, seed, sigma=60, fuzz=True):
    p = profile(base, amp, seed, sigma); r = np.random.default_rng(seed + 1)
    pts = [(x, BASE - p[x % W] - (r.integers(0, 3) if fuzz else 0)) for x in range(0, W + 1, 2)]
    L.poly(pts + [(W, H), (0, H)])

def treeline(L, x0, x1, base, amp, seed, spiky=False, dead=False):
    r = np.random.default_rng(seed); x = x0
    while x < x1:
        w = r.integers(6, 14); h = base + r.random() * amp
        if dead:
            dead_tree(L, x, h * 1.4, seed + int(x))
            x += w * 2.2; continue
        if spiky: L.poly([(x, BASE + 2), (x + w / 2, BASE - h), (x + w, BASE + 2)])
        else: L.ell(x - 2, BASE - h, x + w + 2, BASE + h * 0.3)
        x += w * 0.65

def dead_tree(L, x, h, seed):
    r = np.random.default_rng(seed)
    def br(x0, y0, ang, ln, wd, depth):
        x1 = x0 + math.cos(ang) * ln; y1 = y0 - math.sin(ang) * ln
        L.line([(x0, y0), (x1, y1)], max(1, int(wd)))
        if depth > 0:
            for _ in range(2 + (r.random() < 0.4)): br(x1, y1, ang + (r.random() - 0.5) * 1.3, ln * (0.6 + r.random() * 0.15), wd * 0.65, depth - 1)
    br(x, BASE + 2, math.pi / 2 + (r.random() - 0.5) * 0.25, h * 0.42, 4, 4)

def poles(L, x0, x1, gap, h, seed, sag=8, lean=0.0):
    r = np.random.default_rng(seed); tops = []; x = x0
    while x <= x1:
        hh = h * (1 + (r.random() - 0.5) * 0.2); lx = lean * (r.random() - 0.3) * 10
        L.line([(x, BASE + 2), (x + lx, BASE - hh)], 3); L.line([(x + lx - 9, BASE - hh + 5), (x + lx + 9, BASE - hh + 5)], 2)
        tops.append((x + lx, BASE - hh + 5)); x += gap
    for (ax, ay), (bx, by) in zip(tops, tops[1:]):
        for dy in (0, 4):
            L.line([(ax + (bx - ax) * t, ay + dy + (by - ay) * t + sag * math.sin(math.pi * t)) for t in np.linspace(0, 1, 14)], 1)

def barn(L, x, s=1.0, win=None):
    w = 70 * s; h1 = 30 * s; h2 = 52 * s
    L.poly([(x, BASE + 2), (x, BASE - h1), (x + w * 0.2, BASE - h2 * 0.85), (x + w / 2, BASE - h2), (x + w * 0.8, BASE - h2 * 0.85), (x + w, BASE - h1), (x + w, BASE + 2)])
    for k in range(9): L.rect(x + 6 * s + k * 7 * s, BASE - h1 + 4, x + 7.5 * s + k * 7 * s, BASE - 4, 0)

def house(L, x, s=1.0, lit=True, tilt=0.0):
    w = 46 * s; h = 26 * s; rh = 16 * s
    pts = [(x, BASE + 2), (x, BASE - h), (x + w / 2, BASE - h - rh), (x + w, BASE - h), (x + w, BASE + 2)]
    if tilt:
        cx, cy = x + w / 2, BASE
        pts = [(cx + (px - cx) * math.cos(tilt) - (py - cy) * math.sin(tilt), cy + (px - cx) * math.sin(tilt) + (py - cy) * math.cos(tilt)) for px, py in pts]
    L.poly(pts)
    L.rect(x + w * 0.62, BASE - h - rh * 0.9, x + w * 0.72, BASE - h - rh * 0.3)          # chimney
    if lit: L.light(x + w * 0.25, BASE - h * 0.55, '#E8C27A', 4, 4)

def church(L, x, s=1.0, lit=True):
    L.rect(x, BASE - 34 * s, x + 50 * s, BASE + 2); L.poly([(x - 3, BASE - 34 * s), (x + 25 * s, BASE - 52 * s), (x + 53 * s, BASE - 34 * s)])
    L.rect(x + 18 * s, BASE - 70 * s, x + 32 * s, BASE - 34 * s); L.poly([(x + 16 * s, BASE - 70 * s), (x + 25 * s, BASE - 104 * s), (x + 34 * s, BASE - 70 * s)])
    L.line([(x + 25 * s, BASE - 104 * s), (x + 25 * s, BASE - 116 * s)], 2); L.line([(x + 20 * s, BASE - 111 * s), (x + 30 * s, BASE - 111 * s)], 2)
    if lit: L.light(x + 24 * s, BASE - 22 * s, '#E8C27A', 3, 6)

def silo(L, x, s=1.0):
    L.rect(x, BASE - 70 * s, x + 18 * s, BASE + 2); L.ell(x, BASE - 79 * s, x + 18 * s, BASE - 61 * s)

def water_tower(L, x, s=1.0, text=False):
    leg = 60 * s; tw = 40 * s; th = 24 * s; top = BASE - leg - th
    for lx in (x - 16 * s, x + 16 * s): L.line([(lx, BASE + 2), (x + (lx - x) * 0.6, BASE - leg)], 3)
    L.line([(x - 12 * s, BASE - leg * 0.5), (x + 12 * s, BASE - leg * 0.5)], 2)
    L.rect(x - tw / 2, top + 6 * s, x + tw / 2, top + th); L.poly([(x - tw / 2, top + 7 * s), (x, top - 8 * s), (x + tw / 2, top + 7 * s)])

def mast(L, x, h, seed=0):
    L.line([(x, BASE + 2), (x, BASE - h)], 3)
    for k in range(5):
        y = BASE - h * (k + 1) / 5; L.line([(x, y), (x - 20 + k * 3, BASE)], 1); L.line([(x, y), (x + 20 - k * 3, BASE)], 1)
    for k in (1.0, 0.6, 0.3): L.light(x - 1, BASE - h * k, '#FF3A2A', 3, 3)

def pylon(L, x, s=1.0):
    h = 110 * s
    L.line([(x - 18 * s, BASE + 2), (x - 3 * s, BASE - h)], 2); L.line([(x + 18 * s, BASE + 2), (x + 3 * s, BASE - h)], 2)
    for yv in (0.62, 0.8): L.line([(x - 26 * s, BASE - h * yv), (x + 26 * s, BASE - h * yv)], 2)
    for k in range(6): L.line([(x - 15 * s + k * 2 * s, BASE - k * h / 6), (x + 15 * s - k * 2 * s, BASE - (k + 1) * h / 6)], 1)

def tipple(L, x, s=1.0):
    top = BASE - 90 * s
    L.rect(x, top, x + 64 * s, top + 34 * s); L.poly([(x - 4, top), (x + 32 * s, top - 20 * s), (x + 68 * s, top)])
    for k in range(5): L.line([(x + 4 * s + k * 14 * s, top + 34 * s), (x + 4 * s + k * 14 * s, BASE + 2)], 3)
    L.line([(x + 64 * s, top + 12 * s), (x + 210 * s, BASE - 6)], 6); L.line([(x + 64 * s, top + 20 * s), (x + 210 * s, BASE)], 2)
    hx = x - 46 * s
    L.line([(hx, BASE + 2), (hx + 14 * s, BASE - 110 * s)], 3); L.line([(hx + 30 * s, BASE + 2), (hx + 14 * s, BASE - 110 * s)], 3)
    L.ell(hx + 3 * s, BASE - 122 * s, hx + 25 * s, BASE - 100 * s); L.ell(hx + 6 * s, BASE - 119 * s, hx + 22 * s, BASE - 103 * s, 0)
    L.poly([(x + 160 * s, BASE + 2), (x + 200 * s, BASE - 40 * s), (x + 250 * s, BASE + 2)])            # slag heap

def stacks(L, x, n, s=1.0):
    for i in range(n): L.rect(x + i * 24 * s, BASE - (130 + i * 18) * s, x + i * 24 * s + 11 * s, BASE + 2); L.light(x + i * 24 * s + 4 * s, BASE - (130 + i * 18) * s + 3, '#FF3A2A', 3, 3)

def tall_sign(L, x, h, w, sh, col, txt_col=None):
    L.line([(x, BASE + 2), (x, BASE - h)], 4); L.rect(x - w / 2, BASE - h - sh, x + w / 2, BASE - h)
    L.light(x - w / 2 + 3, BASE - h - sh + 3, col, int(w - 6), int(sh - 6))

def block(L, x, w, h, seed, lit=0.2):
    L.rect(x, BASE - h, x + w, BASE + 2); r = np.random.default_rng(seed)
    L.rect(x - 2, BASE - h - 4, x + w + 2, BASE - h)
    for yy in range(int(BASE - h + 8), int(BASE - 10), 10):
        for xx in range(int(x + 5), int(x + w - 5), 9):
            if r.random() < lit: L.light(xx, yy, '#F2A64A' if r.random() < 0.85 else '#C8D8D0', 4, 5)

def courthouse(L, x, s=1.0):
    L.rect(x, BASE - 60 * s, x + 170 * s, BASE + 2); L.poly([(x - 6, BASE - 60 * s), (x + 85 * s, BASE - 90 * s), (x + 176 * s, BASE - 60 * s)])
    for k in range(9): L.rect(x + 8 * s + k * 18 * s, BASE - 56 * s, x + 12 * s + k * 18 * s, BASE - 6, 0)
    L.rect(x + 60 * s, BASE - 130 * s, x + 110 * s, BASE - 84 * s); L.ell(x + 56 * s, BASE - 170 * s, x + 114 * s, BASE - 110 * s)
    L.line([(x + 85 * s, BASE - 170 * s), (x + 85 * s, BASE - 186 * s)], 2)
    L.light(x + 79 * s, BASE - 118 * s, '#F4E6C8', int(12 * s), int(10 * s))

def headframe(L, x, s=1.0):
    h = 150 * s
    L.line([(x - 26 * s, BASE + 2), (x, BASE - h)], 4); L.line([(x + 26 * s, BASE + 2), (x, BASE - h)], 4); L.line([(x + 70 * s, BASE + 2), (x + 3, BASE - h * 0.9)], 3)
    for k in range(1, 4): L.line([(x - 26 * s + k * 6 * s, BASE - k * h / 4.5), (x + 26 * s - k * 6 * s, BASE - k * h / 4.5)], 2)
    L.ell(x - 18 * s, BASE - h - 18 * s, x + 18 * s, BASE - h + 18 * s); L.ell(x - 14 * s, BASE - h - 14 * s, x + 14 * s, BASE - h + 14 * s, 0)
    L.line([(x - 16 * s, BASE - h), (x + 16 * s, BASE - h)], 2); L.line([(x, BASE - h - 16 * s), (x, BASE - h + 16 * s)], 2)

def fence(L, x0, x1, h=14, gap=22, broken=0.0, seed=0):
    r = np.random.default_rng(seed); x = x0
    while x < x1:
        if r.random() > broken: L.line([(x, BASE + 2), (x + r.normal(0, 1.5), BASE - h)], 2)
        x += gap
    for y in (BASE - h * 0.75, BASE - h * 0.35):
        L.line([(x0, y), (x1, y + r.normal(0, 1))], 1)

def chainlink(L, x0, x1, h=40):
    for x in range(int(x0), int(x1), 40): L.line([(x, BASE + 2), (x, BASE - h)], 2)
    L.line([(x0, BASE - h), (x1, BASE - h)], 1)
    for x in range(int(x0), int(x1), 6): L.line([(x, BASE - h), (x + 6, BASE)], 1, 120)

def render(L, col, name, shade=0.12, light_ok=True):
    """Flat colour + a little dithered vertical shading; lit windows on top; hard alpha."""
    m = L.mask() > 0.5
    # solid land under the ground line: a gentle hillside profile, then solid to the bottom of the strip
    seed = sum(ord(ch) * (i + 1) for i, ch in enumerate(name))
    land = profile(0, 10, seed, 40)
    rows = np.arange(H)[:, None]
    m |= rows >= (BASE - land[None, :]).astype(int)
    # the ground line used for placement: per column, top of the solid run down to the bottom; median
    solid_top = np.array([H - np.argmin(m[::-1, x]) if not m[:, x].all() else 0 for x in range(0, W, 8)])
    GROUND[name] = int(H - np.median(solid_top))
    yy = np.arange(H)[:, None] * np.ones((1, W))
    c = hexc(col)[None, None, :] * (1 + shade * (1 - yy / H)[..., None] * 0.6)
    c = c + np.tile(BAYER, (H // 4, W // 4))[..., None] * 10
    rgba = np.zeros((H, W, 4), np.uint8)
    rgba[..., :3] = np.clip(c, 0, 255).astype(np.uint8); rgba[..., 3] = m * 255
    if light_ok:
        for x, y, lc, w, h in L.lights:
            x0, y0 = int(x), int(y)
            for xx in range(x0, x0 + w):
                rgba[max(y0, 0):max(y0, 0) + h, xx % W, :3] = hexc(lc).astype(np.uint8); rgba[max(y0, 0):max(y0, 0) + h, xx % W, 3] = 255
    Image.fromarray(rgba, 'RGBA').save(f'out/{name}.png')
    return rgba


# ---------------------------------------------------------------- hints of the other stages (far layer)
def on_crest(prof, x, fn):
    """Run a draw call with the ground line moved up to the ridge crest at x (hints stand on the far ridge)."""
    global BASE
    keep = BASE; BASE = int(keep - prof[int(x) % W] + 3)
    try: fn()
    finally: BASE = keep

def plume(L, x, h, w0=10, lean=0.25, seed=0):
    """A billowing smoke column: overlapping puffs that widen and drift as they rise."""
    r = np.random.default_rng(seed)
    for k in range(22):
        t = k / 21; y = BASE - 4 - t * h; cx = x + t * h * lean + math.sin(t * 6 + seed) * 5
        rw = w0 * 0.5 + t * h * 0.16 + r.uniform(0, 3); rh = rw * 0.7
        L.ell(cx - rw, y - rh, cx + rw, y + rh)

def town_lights(L, x0, x1, seed, n=40, y0=BASE - 30, y1=BASE - 6, col='#E8B85A'):
    r = np.random.default_rng(seed)
    for _ in range(n): L.light(r.uniform(x0, x1), r.uniform(y0, y1), col, 2, 2)

def town_far(L, x0, x1, seed, hmin=12, hmax=34, lit=0.12):
    r = np.random.default_rng(seed); x = x0
    while x < x1:
        w = r.integers(10, 26); h = r.integers(hmin, hmax); block(L, x, w, h, seed + int(x), lit); x += w + r.integers(0, 3)

# ---------------------------------------------------------------- lightning reveal strips (drawn only in a flash)
def figure(L, x, s, lean=0.0, head=1.0):
    """A standing person, thin, arms at their sides, seen from far away."""
    h = 26 * s
    L.poly([(x - 2.4 * s, BASE + 2), (x - 1.6 * s + lean, BASE - h * 0.82), (x + 1.6 * s + lean, BASE - h * 0.82), (x + 2.4 * s, BASE + 2)])
    L.ell(x - 2.2 * s * head + lean * 1.1, BASE - h - 1, x + 2.2 * s * head + lean * 1.1, BASE - h * 0.8)
    L.line([(x - 2.0 * s + lean, BASE - h * 0.78), (x - 2.6 * s + lean * 0.5, BASE - h * 0.35)], max(1, int(s)))
    L.line([(x + 2.0 * s + lean, BASE - h * 0.78), (x + 2.6 * s + lean * 0.5, BASE - h * 0.35)], max(1, int(s)))

def giant(L, x, s, lean=0.0):
    """Something far too tall: thin legs, a long body hunched forward, head hanging below the shoulders,
    arms hanging almost to the ground."""
    h = 210 * s; hip = BASE - h * 0.46; sh = BASE - h * 0.86
    lw = max(2, int(5 * s))
    L.line([(x - 9 * s, BASE + 2), (x - 4 * s, BASE - h * 0.24), (x - 3 * s, hip)], lw)
    L.line([(x + 9 * s, BASE + 2), (x + 5 * s, BASE - h * 0.25), (x + 3 * s, hip)], lw)
    L.poly([(x - 8 * s, hip), (x + 8 * s, hip), (x + 14 * s + lean, sh), (x + 2 * s + lean * 1.4, sh - 12 * s), (x - 12 * s + lean, sh + 2 * s)])
    L.ell(x + lean * 1.5 + 4 * s, sh + 2 * s, x + lean * 1.5 + 14 * s, sh + 16 * s)          # a small head, hanging forward and low
    L.line([(x - 10 * s + lean, sh + 4 * s), (x - 16 * s + lean * 0.5, BASE - h * 0.45), (x - 14 * s, BASE - h * 0.12)], max(2, int(4 * s)))
    L.line([(x + 13 * s + lean, sh + 4 * s), (x + 22 * s + lean * 0.5, BASE - h * 0.45), (x + 20 * s, BASE - h * 0.14)], max(2, int(4 * s)))

def hopper(L, x, y, w, h, ang):
    c, s_ = math.cos(ang), math.sin(ang)
    pts = [(-w / 2, 0), (w / 2, 0), (w / 2 - 4, -h), (-w / 2 + 4, -h)]
    L.poly([(x + px * c - py * s_, y + px * s_ + py * c) for px, py in pts])

def tilted_block(L, x, w, h, ang, sink, seed):
    c, s_ = math.cos(ang), math.sin(ang); y = BASE + sink
    pts = [(0, 0), (w, 0), (w, -h), (0, -h)]
    L.poly([(x + px * c - py * s_, y + px * s_ + py * c) for px, py in pts])
    return [(x + px * c - py * s_, y + px * s_ + py * c) for px, py in [(w * 0.3, -h), (w * 0.7, -h)]]

def kneeler(L, x, y, s):
    L.poly([(x - 3 * s, y), (x + 3 * s, y), (x + 2 * s, y - 6 * s), (x - 1 * s, y - 7 * s)])
    L.ell(x - 1.5 * s, y - 9.5 * s, x + 1.8 * s, y - 6.2 * s)

def reveals():
    r = np.random.default_rng(700)
    # 1. Hollow: hundreds of townsfolk standing still in the fog, all facing in; two giants among them
    L = Layer()
    for row, (sc, n) in enumerate([(1.4, 260), (2.1, 150), (3.0, 70)]):
        for _ in range(n): figure(L, r.uniform(0, W), sc * r.uniform(0.85, 1.15), lean=r.normal(0, 0.6))
    giant(L, 620, 1.05, lean=8); giant(L, 1480, 0.85, lean=-6)
    render(L, '#050505', 'r1_reveal', shade=0.0, light_ok=False)
    # 2. Route 9: a derailed coal train strewn through the fog, something crouched over the tipple
    L = Layer()
    for k in range(16):
        hopper(L, 200 + k * 62 + r.normal(0, 6), BASE - r.uniform(0, 10), 52, 26, r.normal(0, 0.45) + (0.9 if k % 5 == 3 else 0))
    L.rect(150, BASE - 40, 200, BASE + 2); L.rect(150, BASE - 52, 170, BASE - 40)      # locomotive on its side
    tipple(L, 1350, 1.2)
    hx = 1420   # something crouched over the tipple: a long bent back, head hanging, arms reaching down
    L.poly([(hx + 150, BASE + 2), (hx + 170, BASE - 120), (hx + 120, BASE - 215), (hx + 30, BASE - 238), (hx - 60, BASE - 215), (hx - 90, BASE - 190), (hx + 60, BASE - 175), (hx + 120, BASE - 90), (hx + 120, BASE + 2)])
    L.ell(hx - 120, BASE - 210, hx - 62, BASE - 150)
    L.line([(hx - 70, BASE - 205), (hx - 150, BASE - 110), (hx - 140, BASE + 2)], 8); L.line([(hx - 40, BASE - 200), (hx - 60, BASE - 120), (hx - 20, BASE - 96)], 7)
    for _ in range(90): figure(L, r.uniform(0, W), r.uniform(1.4, 2.4), lean=r.normal(0, 0.6))
    render(L, '#050505', 'r2_reveal', shade=0.0, light_ok=False)
    # 3. Downtown: the rest of the town sinking at wrong angles, figures standing on the rooftops
    L = Layer(); x = 0
    while x < W:
        w = r.uniform(40, 90); h = r.uniform(70, 170); ang = r.normal(0, 0.22); sink = r.uniform(0, 60)
        tops = tilted_block(L, x, w, h, ang, sink, int(x))
        for tx, ty in tops:
            if r.random() < 0.7:
                L.line([(tx, ty), (tx, ty - 14)], 2); L.ell(tx - 2, ty - 19, tx + 2, ty - 14)
        x += w + r.uniform(-10, 20)
    giant(L, 1020, 1.1, lean=10)
    render(L, '#050505', 'r3_reveal', shade=0.0, light_ok=False)
    # 4. Sinkhole: the pit walls tower above you, terrace above terrace of kneeling robed figures
    L = Layer()
    for t in range(7):
        y = BASE - t * 34; prof = profile(0, 6, 710 + t, 40)
        L.poly([(x_, y - prof[x_ % W]) for x_ in range(0, W + 1, 4)] + [(x_, y - prof[x_ % W] + 6) for x_ in range(W, -1, -4)])   # a thin ledge
        if t == 0: L.rect(0, y, W, BASE + 2)
        sc = 1.9 - t * 0.18
        for k in range(int(90 + t * 25)):
            xk = r.uniform(0, W); kneeler(L, xk, y - prof[int(xk) % W] + 1, sc)
    for k in range(12):   # timber props holding the walls
        xk = r.uniform(0, W); L.line([(xk, BASE + 2), (xk + r.normal(0, 6), BASE - 210)], 3)
    render(L, '#050505', 'r4_reveal', shade=0.0, light_ok=False)

# ============================================================== stage 1: Calvary Run Hollow
def s1():
    far = Layer(); ridge(far, 70, 110, 11, 90)
    mid = Layer(); ridge(mid, 18, 40, 12, 50); treeline(mid, 0, W, 16, 24, 13)
    church(mid, 380, 1.4); barn(mid, 1160, 1.4); silo(mid, 1270, 1.2); silo(mid, 1298, 1.4); mast(mid, 1700, 200)
    house(mid, 820, 1.3); house(mid, 1540, 1.2); barn(mid, 60, 0.9)
    near = Layer()
    poles(near, 0, W, 170, 120, 14, sag=14)
    for i, x in enumerate((120, 640, 1010, 1430, 1890)): dead_tree(near, x, 140 + (i % 3) * 30, 15 + i)
    fence(near, 0, W, 16, 26, 0.15, 16)
    for x in (300, 330, 950, 1650): near.ell(x, BASE - 18, x + 26, BASE + 2)                       # round hay bales
    pf = profile(70, 110, 11, 90); hx = 1010
    on_crest(pf, hx, lambda: (plume(far, hx + 40, 110, 12, 0.3, 11), tipple(far, hx - 60, 0.55), town_far(far, hx, hx + 150, 12, 10, 24, 0.0), town_lights(far, hx, hx + 150, 13, 30, BASE - 24, BASE - 2)))
    render(far, '#6A7268', 's1_far'); render(mid, '#3E463C', 's1_mid'); render(near, '#1E241C', 's1_near')

# ============================================================== stage 2: Route 9 & the Tipple
def s2():
    far = Layer(); ridge(far, 60, 90, 21, 90); stacks(far, 1500, 3, 1.0)
    mid = Layer(); ridge(mid, 10, 24, 22, 60)
    tipple(mid, 520, 1.0); tall_sign(mid, 1080, 120, 50, 26, '#D8B04A'); tall_sign(mid, 1330, 70, 44, 22, '#FF4A3A')
    mid.rect(1250, BASE - 38, 1420, BASE + 2)                                                       # motel row
    for k in range(7): mid.light(1260 + k * 22, BASE - 26, '#E8C27A' if k % 3 else '#2A2420', 8, 10)
    mid.rect(1060, BASE - 30, 1150, BASE + 2); mid.rect(1040, BASE - 42, 1170, BASE - 36)           # gas canopy
    mid.light(1046, BASE - 36, '#FFF2C8', 118, 2)
    for x in (120, 300, 1800): pylon(mid, x, 1.0)
    for k in range(9): mid.rect(1500 + k * 34, BASE - 22, 1528 + k * 34, BASE + 2)                  # hopper cars
    near = Layer()
    chainlink(near, 0, W, 46)
    for i, x in enumerate((240, 760, 1600)): dead_tree(near, x, 120, 25 + i)
    for x in (900, 1960): near.poly([(x, BASE + 2), (x + 50, BASE - 34), (x + 120, BASE + 2)])     # slag
    pf = profile(60, 90, 21, 90)
    on_crest(pf, 300, lambda: (barn(far, 300, 0.7), silo(far, 360, 0.6), silo(far, 374, 0.7), church(far, 190, 0.6, False)))   # the farm ridge behind you
    on_crest(pf, 1000, lambda: (town_far(far, 880, 1200, 21, 12, 30, 0.0), courthouse(far, 980, 0.55), town_lights(far, 880, 1200, 22, 50, BASE - 30, BASE - 2)))
    render(far, '#6E5A44', 's2_far'); render(mid, '#3A2A20', 's2_mid'); render(near, '#16100C', 's2_near')

# ============================================================== stage 3: town under a red sky
def s3():
    far = Layer(); ridge(far, 50, 80, 31, 90)
    r = np.random.default_rng(32); x = 0
    while x < W:   # distant skyline
        w = r.integers(30, 70); h = r.integers(40, 100) + (60 if r.random() < 0.1 else 0)
        block(far, x, w, h, 100 + x, 0.12); x += w + r.integers(0, 6)
    mid = Layer()
    courthouse(mid, 900, 1.0); water_tower(mid, 600, 1.2); church(mid, 1500, 1.1, True); mast(mid, 1800, 210)
    x = 0
    while x < W:
        if 860 < x < 1100 or 560 < x < 660 or 1480 < x < 1580: x += 40; continue
        w = int(r.integers(40, 90)); h = int(r.integers(40, 80)); block(mid, x, w, h, 300 + x, 0.25); x += w + int(r.integers(4, 18))
    near = Layer()
    xs_ = [40, 250, 520, 1000, 1180, 1460, 1720, 1890]
    for i, x in enumerate(xs_): house(near, x, 1.3 + (i % 3) * 0.3, lit=(i % 2 == 0), tilt=0.0)
    for x in (170, 430, 940, 1390, 1650): near.line([(x, BASE + 2), (x, BASE - 90)], 3); near.line([(x, BASE - 90), (x + 22, BASE - 90)], 2); near.light(x + 18, BASE - 88, '#FFB04A', 6, 3)
    for k in range(6):                                                                              # barricade line
        bx = 700 + k * 40; near.rect(bx, BASE - 20, bx + 30, BASE - 14); near.line([(bx + 2, BASE + 2), (bx + 6, BASE - 20)], 2); near.line([(bx + 28, BASE + 2), (bx + 24, BASE - 20)], 2)
    for i, x in enumerate((520, 1350, 1950)): dead_tree(near, x, 150, 35 + i)
    plume(far, 990, 210, w0=26, lean=0.18, seed=31)
    for k in range(10): far.light(970 + k * 5, BASE - 6 - (k % 3), '#FF8A3A', 4, 3)                 # the sinkhole's glow under the smoke
    render(far, '#5A1A14', 's3_far'); render(mid, '#2A0C0A', 's3_mid'); render(near, '#0E0404', 's3_near')

# ============================================================== final: the sinkhole rim
def s4():
    far = Layer(); ridge(far, 40, 70, 41, 90)
    headframe(far, 700, 0.9); stacks(far, 1300, 2, 1.1); church(far, 1700, 0.9)
    mid = Layer()
    p = profile(14, 26, 42, 40)
    mid.poly([(x, BASE - p[x % W]) for x in range(0, W + 1, 2)] + [(W, H), (0, H)])                       # broken rim
    for i, x in enumerate(range(60, W, 260)): house(mid, x, 1.8, lit=(i % 3 == 0), tilt=(0.28 if i % 2 else -0.22))   # houses sliding in
    poles(mid, 0, W, 150, 110, 43, sag=20, lean=1.0)
    near = Layer()
    rr_ = np.random.default_rng(46); x = 0
    while x < W:                                                                                    # broken mine timbers, leaning
        h = rr_.uniform(18, 70); lean = rr_.uniform(-8, 8)
        near.poly([(x, BASE + 2), (x + 8, BASE + 2), (x + 8 + lean, BASE - h), (x + lean, BASE - h)])
        if rr_.random() < 0.35: near.line([(x + lean, BASE - h), (x + rr_.uniform(30, 70), BASE - h + rr_.uniform(-14, 20))], 5)
        x += rr_.uniform(40, 130)
    p2 = profile(4, 14, 47, 20); near.poly([(x_, BASE - p2[x_ % W]) for x_ in range(0, W + 1, 2)] + [(W, H), (0, H)])
    for x in range(30, W, 97): near.light(x, BASE - 8, '#FFC060', 2, 5)                             # candles on the rim
    for i, x in enumerate((300, 1100, 1700)): dead_tree(near, x, 160, 45 + i)
    pf = profile(40, 70, 41, 90)
    on_crest(pf, 1000, lambda: (town_far(far, 860, 1180, 41, 14, 40, 0.0), courthouse(far, 960, 0.6), town_lights(far, 860, 1180, 42, 80, BASE - 40, BASE - 2)))
    on_crest(pf, 420, lambda: (barn(far, 410, 0.5), silo(far, 455, 0.42)))                     # the farm, far away where you started
    render(far, '#2A1614', 's4_far'); render(mid, '#140A08', 's4_mid'); render(near, '#060303', 's4_near')

for f in (s1, s2, s3, s4): f()
import json; json.dump({'height_px': H, 'width_px': W, 'ground_px_from_bottom': GROUND}, open('out/strips.json', 'w'), indent=1)
print('ok')
