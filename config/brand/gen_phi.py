#!/usr/bin/env python3
"""
CalTekNet contoured mark, generation 2.
- Sun radiance built on the golden angle (137.50776°) with phi-scaled ray lengths
  => uneven 'ciliary' phyllotaxis burst (phi-based recursive implosion motif).
- County-cell network: Delaunay edges over points seeded inside the state, clipped per region.
- Large C/T/N caps vs. small lowercase, contoured to the NW-SE tilt.
- Emits color SVG; grayscale + B&W derived by substitution.
"""
import math, random
import numpy as np
from scipy.spatial import Delaunay

PHI = (1 + 5 ** 0.5) / 2
GOLDEN_DEG = 360 / (PHI * PHI)        # 137.50776...
GOLDEN_RAD = math.radians(GOLDEN_DEG)
random.seed(1997); np.random.seed(1997)

# ---- state outline (local coords, before translate) ----
CA = [(8,4),(50,4),(50,47),(88,85),(86,92),(90,98),(88,106),
      (62,112),(58,106),(52,98),(38,88),(34,78),(26,62),
      (22,48),(14,36),(10,22)]
CA_D = "M " + " L ".join(f"{x},{y}" for x,y in CA) + " Z"

def in_poly(px, py, poly):
    n=len(poly); inside=False; j=n-1
    for i in range(n):
        xi,yi=poly[i]; xj,yj=poly[j]
        if ((yi>py)!=(yj>py)) and (px < (xj-xi)*(py-yi)/(yj-yi)+xi):
            inside=not inside
        j=i
    return inside

# ---- county-cell points seeded inside the state (~58 counties nod) ----
pts=[]
tries=0
while len(pts)<58 and tries<6000:
    x=random.uniform(8,90); y=random.uniform(4,112)
    if in_poly(x,y,CA):
        # light blue-noise: keep apart
        if all((x-a)**2+(y-b)**2>14 for a,b in pts):
            pts.append((x,y))
    tries+=1
pts_np=np.array(pts)
tri=Delaunay(pts_np)
edges=set()
for s in tri.simplices:
    for a,b in [(s[0],s[1]),(s[1],s[2]),(s[2],s[0])]:
        edges.add(tuple(sorted((a,b))))
county_lines=[]
for a,b in edges:
    (x1,y1),(x2,y2)=pts[a],pts[b]
    # drop very long edges (outside-ish spans) for a tidier mesh
    if (x1-x2)**2+(y1-y2)**2 < 900:
        county_lines.append((x1,y1,x2,y2))

county_svg="".join(
    f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}"/>'
    for x1,y1,x2,y2 in county_lines)
county_nodes="".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="0.7"/>' for x,y in pts)

# ---- phi sun: golden-angle rays with phi-scaled, oscillating lengths ----
SUN=(78,16)
cx,cy=SUN
N_RAYS=55
rays=[]
for i in range(N_RAYS):
    ang=i*GOLDEN_RAD
    # phi-recursive length: base damped by phi over Fibonacci-ish bands, plus golden oscillation
    band=i % 13
    length = 7.5 * (PHI ** (-(band)/6.0)) * (0.55 + 0.45*math.cos(i*GOLDEN_RAD*PHI))
    length = max(length, 1.6)
    inner = 5.6                      # start at the disc edge
    x1=cx+inner*math.cos(ang); y1=cy+inner*math.sin(ang)
    x2=cx+(inner+length)*math.cos(ang); y2=cy+(inner+length)*math.sin(ang)
    w = 0.9 if (i%2==0) else 0.55
    rays.append((x1,y1,x2,y2,w))
ray_svg="".join(
    f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke-width="{w}"/>'
    for x1,y1,x2,y2,w in rays)

# ---- phyllotaxis seed head inside the disc (water-differentiation nod) ----
seeds=[]
for n in range(1,90):
    r=0.42*math.sqrt(n)
    if r>4.9: break
    a=n*GOLDEN_RAD
    seeds.append((cx+r*math.cos(a), cy+r*math.sin(a), 0.18+0.5*(r/4.9)))
seed_svg="".join(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{rr:.2f}"/>' for x,y,rr in seeds)

# ---- assemble color SVG ----
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 134" width="600" height="670">
  <defs>
    <path id="ca" d="{CA_D}"/>
    <clipPath id="caClip"><use href="#ca"/></clipPath>
    <linearGradient id="valleyGold" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#E8B83A"/><stop offset="100%" stop-color="#D99E2B"/>
    </linearGradient>
    <radialGradient id="sunCore" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#FFF1A8"/><stop offset="60%" stop-color="#FFD500"/>
      <stop offset="100%" stop-color="#F2A900"/>
    </radialGradient>
  </defs>

  <rect width="120" height="134" fill="#0E0D0B"/>

  <g transform="translate(8,7)">
    <!-- region fills -->
    <g clip-path="url(#caClip)">
      <rect x="0" y="0" width="100" height="44" fill="#3E6B35"/>
      <rect x="0" y="44" width="100" height="42" fill="url(#valleyGold)"/>
      <polygon points="46,60 100,60 100,120 30,120 40,92" fill="#8A5A33"/>
      <!-- county-cell network, tinted, clipped to state -->
      <g stroke="#0E0D0B" stroke-width="0.35" stroke-opacity="0.45" fill="none">{county_svg}</g>
      <g fill="#FFD500" fill-opacity="0.55">{county_nodes}</g>
    </g>
    <use href="#ca" fill="none" stroke="#FFD500" stroke-width="2" stroke-linejoin="round"/>

    <!-- PHI SUN : golden-angle ciliary radiance -->
    <g stroke="#FFD500" stroke-linecap="round" opacity="0.92">{ray_svg}</g>
    <circle cx="{cx}" cy="{cy}" r="5.6" fill="url(#sunCore)" stroke="#F2A900" stroke-width="0.4"/>
    <g fill="#F2A900" fill-opacity="0.55">{seed_svg}</g>

    <!-- words: LARGE caps, small lowercase on shared baseline, contoured -->
    <g font-family="Cinzel, Georgia, serif" font-weight="700">
      <g transform="translate(14,30) rotate(10)">
        <text font-size="27" fill="#FFD500">C</text>
        <text x="18" y="0" font-size="13" fill="#F2EDE3">al</text>
      </g>
      <g transform="translate(20,57) rotate(22)">
        <text font-size="25" fill="#1A1206">T</text>
        <text x="15" y="0" font-size="12" fill="#1A1206">ek.</text>
      </g>
      <g transform="translate(28,80) rotate(30)">
        <text font-size="25" fill="#FFD500">N</text>
        <text x="17" y="0" font-size="12" fill="#F2EDE3">et</text>
      </g>
    </g>

    <!-- LA sister-city globe at the southern tip -->
    <g transform="translate(72,102)">
      <circle r="10" fill="#0B2E4A" stroke="#FFD500" stroke-width="1.1"/>
      <clipPath id="gC"><circle r="10"/></clipPath>
      <g clip-path="url(#gC)" stroke="#7FC4E8" stroke-width="0.4" fill="none" opacity="0.8">
        <line x1="-10" y1="0" x2="10" y2="0"/><line x1="-10" y1="-4.5" x2="10" y2="-4.5"/><line x1="-10" y1="4.5" x2="10" y2="4.5"/>
        <g><ellipse rx="2.7" ry="10"/><ellipse rx="6.4" ry="10"/><ellipse rx="9" ry="10"/>
          <animateTransform attributeName="transform" type="scale" values="1 1;0.15 1;1 1" dur="6s" repeatCount="indefinite"/></g>
      </g>
      <circle cx="-1.3" cy="3" r="1.1" fill="#FFD500" stroke="#0E0D0B" stroke-width="0.3"/>
      <g stroke="#FFD500" stroke-width="0.5" fill="none" opacity="0.9">
        <path d="M -1.3,3 Q -6,-3 -8,-4.5"/><path d="M -1.3,3 Q 4.5,-2 7,-5.5"/>
        <path d="M -1.3,3 Q 5.5,1 8.5,-1.3"/><path d="M -1.3,3 Q -4.5,6 -8,5.5"/>
      </g>
      <text y="15.5" text-anchor="middle" font-family="'Space Mono',Menlo,monospace" font-size="3.2" letter-spacing="0.6" fill="#9C8F76">L A &#183; SISTER CITIES</text>
    </g>
  </g>
</svg>'''
open('caltek-phi.svg','w').write(svg)
print("rays:",N_RAYS,"county edges:",len(county_lines),"seeds:",len(seeds),
      "golden angle:",round(GOLDEN_DEG,3))
