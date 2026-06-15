#!/usr/bin/env python3
"""
CTN docx/xlsx to eXeLearning iDevice injector
Watches /mnt/ctn-media/docx-inbox/ for new .docx/.xlsx files,
converts to HTML, injects as Text iDevices into target .elpx

Install: apt install pandoc
         pip3 install watchdog openpyxl python-docx
Run:     python3 docx_to_elpx.py --elpx /path/to/file.elpx --watch
"""
import os, sys, subprocess, zipfile, shutil, time, json, re, argparse, random, string
from pathlib import Path

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    HAS_WATCHDOG = True
except ImportError:
    HAS_WATCHDOG = False

INBOX  = Path("/mnt/ctn-media/docx-inbox")
OUTBOX = Path("/mnt/ctn-media/elpx-out")

def docx_to_html(path):
    r = subprocess.run(["pandoc", str(path), "-t", "html", "--no-highlight"],
                       capture_output=True, text=True)
    return r.stdout

def xlsx_to_html(path):
    import openpyxl
    wb = openpyxl.load_workbook(path)
    ws = wb.active
    out = "<table border='1' cellpadding='6' style='border-collapse:collapse;width:100%;'>"
    for i, row in enumerate(ws.iter_rows(values_only=True)):
        style = "background:#1B2A4A;color:white;" if i == 0 else ""
        out += f"<tr style='{style}'>"
        tag = "th" if i == 0 else "td"
        for cell in row:
            out += f"<{tag}>{str(cell) if cell is not None else ''}</{tag}>"
        out += "</tr>"
    return out + "</table>"

def inject_into_elpx(elpx_path, html, title):
    tmp = Path("/tmp/ctn_elpx_inject")
    if tmp.exists():
        shutil.rmtree(tmp)
    tmp.mkdir()
    with zipfile.ZipFile(elpx_path) as z:
        z.extractall(tmp)
    xml = (tmp / "content.xml").read_text()
    root_id = re.search(r'<odeNavStructure>\s*<odePageId>(.*?)</odePageId>', xml).group(1)
    count   = len(re.findall(r'<odeNavStructure>', xml))
    ts   = int(time.time() * 1000)
    rand = ''.join(random.choices(string.ascii_lowercase + string.digits, k=9))
    pid  = f"page-{ts}-{rand}"
    blk  = f"block-{ts}-{rand}b"
    dev  = f"idevice-{ts}-{rand}i"
    jprops = json.dumps({"ideviceId": dev, "textTextarea": html})
    def cdata(s):
        return "<![CDATA[" + s + "]]>"
    new_nav = (
        f"<odeNavStructure>\n"
        f"  <odePageId>{pid}</odePageId>\n"
        f"  <odeParentPageId>{root_id}</odeParentPageId>\n"
        f"  <pageName>{title}</pageName>\n"
        f"  <odeNavStructureOrder>{count}</odeNavStructureOrder>\n"
        f"  <odeNavStructureProperties>\n"
        f"    <odeNavStructureProperty><key>titlePage</key><value>{title}</value></odeNavStructureProperty>\n"
        f"    <odeNavStructureProperty><key>visibility</key><value>true</value></odeNavStructureProperty>\n"
        f"  </odeNavStructureProperties>\n"
        f"  <odePagStructures>\n"
        f"    <odePagStructure>\n"
        f"      <odePageId>{pid}</odePageId>\n"
        f"      <odeBlockId>{blk}</odeBlockId>\n"
        f"      <blockName>Text</blockName><iconName></iconName>\n"
        f"      <odePagStructureOrder>0</odePagStructureOrder>\n"
        f"      <odePagStructureProperties>\n"
        f"        <odePagStructureProperty><key>visibility</key><value>true</value></odePagStructureProperty>\n"
        f"      </odePagStructureProperties>\n"
        f"      <odeComponents><odeComponent>\n"
        f"          <odePageId>{pid}</odePageId><odeBlockId>{blk}</odeBlockId>\n"
        f"          <odeIdeviceId>{dev}</odeIdeviceId>\n"
        f"          <odeIdeviceTypeName>text</odeIdeviceTypeName>\n"
        f"          <htmlView>{cdata('<div class=\"exe-text-template\">' + html + '</div>')}</htmlView>\n"
        f"          <jsonProperties>{cdata(jprops)}</jsonProperties>\n"
        f"          <odeComponentsOrder>0</odeComponentsOrder>\n"
        f"          <odeComponentsProperties></odeComponentsProperties>\n"
        f"      </odeComponent></odeComponents>\n"
        f"    </odePagStructure>\n"
        f"  </odePagStructures>\n"
        f"</odeNavStructure>"
    )
    xml = xml.replace("</odeNavStructures>", new_nav + "\n</odeNavStructures>")
    (tmp / "content.xml").write_text(xml)
    OUTBOX.mkdir(parents=True, exist_ok=True)
    out = OUTBOX / Path(elpx_path).name
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zout:
        for f in tmp.rglob('*'):
            if f.is_file():
                zout.write(f, f.relative_to(tmp))
    shutil.rmtree(tmp)
    print(f"[CTN] '{title}' injected -> {out}")
    return out

class Handler(FileSystemEventHandler):
    def __init__(self, elpx):
        self.elpx = elpx
    def on_created(self, evt):
        p = Path(evt.src_path)
        if p.suffix == '.docx':
            inject_into_elpx(self.elpx, docx_to_html(p), p.stem)
        elif p.suffix in ('.xlsx', '.xls'):
            inject_into_elpx(self.elpx, xlsx_to_html(p), p.stem)

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--elpx', required=True, help='Target .elpx file')
    ap.add_argument('--file', help='One-shot: convert single file')
    ap.add_argument('--watch', action='store_true', help='Watch inbox folder for new files')
    args = ap.parse_args()
    if args.file:
        p = Path(args.file)
        html = docx_to_html(p) if p.suffix == '.docx' else xlsx_to_html(p)
        inject_into_elpx(args.elpx, html, p.stem)
    elif args.watch and HAS_WATCHDOG:
        INBOX.mkdir(parents=True, exist_ok=True)
        obs = Observer()
        obs.schedule(Handler(args.elpx), str(INBOX), recursive=False)
        obs.start()
        print(f"[CTN] Watching {INBOX} for .docx/.xlsx...")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            obs.stop()
        obs.join()
    else:
        print("Use --file FILE or --watch (requires watchdog package).")
