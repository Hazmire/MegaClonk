#!/usr/bin/env python3
"""Renders the weapon effect boards from the UI handoff (docs/ui_handoff/mockups/W-*.dc.html) into the looping previews
shown in Unlocks > Weapons. The stage of each board (720x640, stepped CSS animation, pixel stand-ins) is scaled to the
Polaroid (460x408, the 0.6389 scale the mockup itself uses) and sampled at 12 fps for one full loop.
Output: assets/ui/weapon_previews/<weapon id>.png (sprite sheet) and previews.json.
usage: python3 tools/weapon_preview_from_mockups.py [sword bow ...]"""
import json, sys, math
from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image
import io
ROOT = Path(__file__).resolve().parent.parent
BOARDS = {"sword": 0, "firestaff": 1, "lightning": 2, "bow": 6, "revolver": 7, "scythes": 9, "aura": 10, "shotgun": 15}
FILES = {"sword": "W-Sword", "firestaff": "W-Firestaff", "lightning": "W-Lightning", "bow": "W-Bow", "revolver": "W-Revolver", "scythes": "W-Scythes", "aura": "W-Aura", "shotgun": "W-Shotgun"}
W, H, FPS, COLUMNS = 460, 408, 12, 6
LOOP_SECONDS = {"aura": 3.6}  # the board also has a 14 s decorative spin; the 3.6 s smoke/pulse cycle is the loop (the spin steps once at the seam)
OUT = ROOT / "assets/ui/weapon_previews"
PREP = """() => {
  const stage=[...document.querySelectorAll('div')].find(d=>d.style.width==='720px'&&d.style.height==='640px');
  if(!stage) return null;
  const wrap=document.createElement('div');
  wrap.style.cssText='position:fixed;left:0;top:0;width:460px;height:408px;overflow:hidden;z-index:99999;background:#0E0F0E';
  stage.style.border='none';stage.style.transform='scale(0.6389)';stage.style.transformOrigin='0 0';stage.style.position='absolute';stage.style.left='0';stage.style.top='0';
  wrap.appendChild(stage);document.body.appendChild(wrap);
  const ms=document.getAnimations().map(a=>{const t=a.effect.getTiming();return (t.duration||0)});
  return Math.max(...ms,0);
}"""
SEEK = "(t)=>{document.getAnimations().forEach(a=>{a.pause();a.currentTime=t});}"
def main():
    names = sys.argv[1:] or list(BOARDS)
    OUT.mkdir(parents=True, exist_ok=True)
    meta_path = OUT / "previews.json"
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1400, "height": 900})
        for name in names:
            page.goto((ROOT / f"docs/ui_handoff/mockups/{FILES[name]}.dc.html").as_uri())
            page.wait_for_timeout(300)
            duration = page.evaluate(PREP)
            if not duration:
                print("no stage in", name); continue
            duration = LOOP_SECONDS.get(name, duration / 1000.0) * 1000.0
            count = max(1, round(duration / 1000.0 * FPS))
            frames = []
            for i in range(count):
                page.evaluate(SEEK, i * 1000.0 / FPS)
                page.wait_for_timeout(30)
                png = page.screenshot(clip={"x": 0, "y": 0, "width": W, "height": H})
                frames.append(Image.open(io.BytesIO(png)).convert("RGB"))
            rows = math.ceil(count / COLUMNS)
            sheet = Image.new("RGB", (W * COLUMNS, H * rows))
            for i, f in enumerate(frames):
                sheet.paste(f, ((i % COLUMNS) * W, (i // COLUMNS) * H))
            sheet.save(OUT / f"{BOARDS[name]}.png", optimize=True)
            meta[str(BOARDS[name])] = {"name": name, "frames": count, "columns": COLUMNS, "fps": FPS, "w": W, "h": H, "source": f"{FILES[name]}.dc.html"}
            print(f"{name}: {count} frames, loop {duration/1000:.2f}s")
        browser.close()
    meta_path.write_text(json.dumps(meta, indent="\t", sort_keys=True))
main()
