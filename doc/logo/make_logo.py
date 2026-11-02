"""Builds the OpenShelf logo (design B) and the alternative (design A).

Outputs, next to this script:
  openshelf-logo.svg / openshelf-logo-alt-a.svg   1024x1024 sources (rounded)
  generated/icon.png                              legacy launcher icon, rounded
  generated/foreground.png                        adaptive icon foreground
  generated/background.png                        adaptive icon background
  generated/monochrome.png                        Android 13 themed icon

Adaptive icons are 108dp of which only the central 72dp are visible.
flutter_launcher_icons insets the foreground by 16% on its own, so the
foreground is the plain 1024 artwork; only the background is drawn on the
full 108dp canvas.

Run: python3 -m venv .venv && .venv/bin/pip install cairosvg pillow
     .venv/bin/python doc/logo/make_logo.py
     dart run flutter_launcher_icons
"""

import io
from pathlib import Path

import cairosvg
from PIL import Image

HERE = Path(__file__).resolve().parent
GEN = HERE / "generated"

# The whole 108dp canvas around the visible 1024 design (108dp / 72dp = 1.5).
ADAPTIVE_VIEWBOX = "-256 -256 1536 1536"


def defs(bg_a: str, bg_b: str) -> str:
    return f"""
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{bg_a}"/>
      <stop offset="1" stop-color="{bg_b}"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.25" cy="0.18" r="0.75">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.38"/>
      <stop offset="0.55" stop-color="#ffffff" stop-opacity="0.06"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="glass" x1="0" y1="0" x2="0.6" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.62"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0.16"/>
    </linearGradient>
    <linearGradient id="glassStrong" x1="0" y1="0" x2="0.5" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.92"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0.55"/>
    </linearGradient>
    <linearGradient id="shine" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.75"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="shadow" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#000000" stop-opacity="0.22"/>
      <stop offset="1" stop-color="#000000" stop-opacity="0"/>
    </linearGradient>
  </defs>"""


def background(x: float = 0, y: float = 0, size: float = 1024, rx: float = 232) -> str:
    return f"""
  <g id="background">
    <rect x="{x}" y="{y}" width="{size}" height="{size}" rx="{rx}" fill="url(#bg)"/>
    <rect x="{x}" y="{y}" width="{size}" height="{size}" rx="{rx}" fill="url(#glow)"/>
  </g>"""


def spine(
    x: float, y: float, w: float, h: float, tint: str,
    opacity: float = 0.38, rot: float = 0, cx: float | None = None, cy: float | None = None,
) -> str:
    """A standing glass book: tinted body, light edge, highlight strip, label band."""
    transform = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
    return f"""
  <g{transform}>
    <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="{tint}" fill-opacity="{opacity}"/>
    <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="url(#glass)"/>
    <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="none" stroke="#ffffff" stroke-opacity="0.85" stroke-width="5"/>
    <rect x="{x + 12}" y="{y + 14}" width="{w * 0.22}" height="{h - 28}" rx="6" fill="url(#shine)" opacity="0.7"/>
    <rect x="{x + 14}" y="{y + h * 0.16}" width="{w - 28}" height="14" rx="7" fill="#ffffff" fill-opacity="0.75"/>
    <rect x="{x + 14}" y="{y + h * 0.16 + 26}" width="{w - 28}" height="8" rx="4" fill="#ffffff" fill-opacity="0.45"/>
  </g>"""


def open_book(cx: float, base: float, half_w: float, height: float, sag: float = 26, ribbon: str | None = None) -> str:
    """An open book seen from the front: two curved pages meeting at the spine,
    faint text lines and an optional ribbon bookmark."""
    l, r, top = cx - half_w, cx + half_w, base - height

    def page(edge: float, inner: float) -> str:
        return (f"M{cx},{base} C{cx + inner * 0.35},{base - sag} {edge - inner * 0.25},{base - sag} {edge},{base - sag * 0.3} "
                f"L{edge},{top} C{edge - inner * 0.25},{top - sag} {cx + inner * 0.35},{top - sag} {cx},{top + sag * 0.15} Z")

    out = ""
    for edge, inner in ((l, -half_w), (r, half_w)):
        out += f'\n  <path d="{page(edge, inner)}" fill="url(#glassStrong)" stroke="#ffffff" stroke-width="6" stroke-linejoin="round"/>'
    out += f'\n  <path d="M{cx},{top + sag * 0.15} L{cx},{base}" stroke="#ffffff" stroke-opacity="0.9" stroke-width="5"/>'
    for i in range(4):
        y = top + height * (0.28 + i * 0.16)
        for side in (-1, 1):
            x1 = cx + side * half_w * 0.18
            x2 = cx + side * half_w * (0.78 if i < 3 else 0.55)
            out += (f'\n  <path d="M{x1},{y + 6} Q{(x1 + x2) / 2},{y - 10} {x2},{y}" '
                    f'stroke="#0b1f33" stroke-opacity="0.18" stroke-width="10" stroke-linecap="round" fill="none"/>')
    if ribbon:
        rx = cx + half_w * 0.45
        out += (f'\n  <path d="M{rx - 18},{top - sag * 0.6} L{rx + 18},{top - sag * 0.6} L{rx + 18},{top + height * 0.42} '
                f'L{rx},{top + height * 0.34} L{rx - 18},{top + height * 0.42} Z" fill="{ribbon}"/>')
    return out


def shelf(x1: float, x2: float, y: float, h: float = 30) -> str:
    return f"""
  <rect x="{x1}" y="{y + h}" width="{x2 - x1}" height="46" fill="url(#shadow)"/>
  <rect x="{x1}" y="{y}" width="{x2 - x1}" height="{h}" rx="{h / 2}" fill="url(#glassStrong)" stroke="#ffffff" stroke-width="4"/>"""


def artwork_b() -> str:
    """B: one large open glass book, a row of spines shining through behind it."""
    out = ""
    for i, (h, tint) in enumerate([(250, "#99f6e4"), (300, "#ccfbf1"), (230, "#a7f3d0"), (280, "#99f6e4"), (260, "#ccfbf1")]):
        x = 262 + i * 104
        out += (f'\n  <rect x="{x}" y="{560 - h}" width="84" height="{h}" rx="14" fill="{tint}" fill-opacity="0.22" '
                f'stroke="#ffffff" stroke-opacity="0.45" stroke-width="4"/>')
    out += '\n  <rect x="232" y="556" width="560" height="14" rx="7" fill="#ffffff" fill-opacity="0.45"/>'
    out += open_book(512, 800, 290, 290, sag=34, ribbon="#f59e0b")
    return out


def artwork_a() -> str:
    """A: glass shelf with three books and an open book on display."""
    out = shelf(212, 812, 716)
    out += spine(252, 392, 92, 324, "#a5f3fc")
    out += spine(356, 436, 76, 280, "#c4b5fd")
    out += spine(444, 372, 100, 344, "#f9a8d4", rot=-9, cx=494, cy=716)
    out += open_book(668, 712, 132, 210, sag=22, ribbon="#fbbf24")
    return out


B_COLORS = ("#14b8a6", "#0f4c5c")
A_COLORS = ("#4f46e5", "#06b6d4")


def svg(colors: tuple[str, str], bg: str, art: str, viewbox: str = "0 0 1024 1024") -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}" width="1024" height="1024">'
            f'{defs(*colors)}{bg}\n  <g id="artwork">{art}\n  </g>\n</svg>\n')


def png(content: str, size: int = 1024) -> Image.Image:
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=content.encode(), output_width=size, output_height=size))).convert("RGBA")


def main() -> None:
    GEN.mkdir(exist_ok=True)
    (HERE / "openshelf-logo.svg").write_text(svg(B_COLORS, background(), artwork_b()))
    (HERE / "openshelf-logo-alt-a.svg").write_text(svg(A_COLORS, background(), artwork_a()))

    png(svg(B_COLORS, background(), artwork_b())).save(GEN / "icon.png")

    # Adaptive layers: the background fills the whole 108dp canvas.
    png(svg(B_COLORS, "", artwork_b())).save(GEN / "foreground.png")
    png(svg(B_COLORS, background(-256, -256, 1536, 0), "", ADAPTIVE_VIEWBOX)).convert("RGB").save(GEN / "background.png")

    # Themed icon: the launcher tints a single-colour silhouette.
    fg = Image.open(GEN / "foreground.png")
    mono = Image.new("RGBA", fg.size, (255, 255, 255, 0))
    mono.putalpha(fg.getchannel("A"))
    mono.save(GEN / "monochrome.png")
    print("written:", sorted(p.name for p in GEN.iterdir()))


if __name__ == "__main__":
    main()
