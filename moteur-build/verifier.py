#!/usr/bin/env python3
"""
Vérifie un moteur compilé avec la page app/test-moteur.html, dans un vrai navigateur (Chromium, sans écran).

Usage : python3 moteur-build/verifier.py <dossier-app-avec-moteur>
Sortie : la liste des contrôles ; code de retour 1 si un contrôle échoue.
"""
import functools, http.server, sys, threading
from playwright.sync_api import sync_playwright

app = sys.argv[1]
Handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=app)
Handler.log_message = lambda *a: None
http.server.SimpleHTTPRequestHandler.extensions_map[".wasm"] = "application/wasm"
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
threading.Thread(target=srv.serve_forever, daemon=True).start()

with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_page()
    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.goto("http://127.0.0.1:8765/test-moteur.html")
    pg.click("#go")
    pg.wait_for_function("document.querySelector('#go').disabled === false && document.querySelector('#verdict').textContent.length > 0",
                         timeout=600000)
    ok = True
    for li in pg.query_selector_all("#checks li"):
        good = li.get_attribute("class") == "ok"
        ok &= good
        print(("OK   " if good else "ÉCHEC") + "  " + li.inner_text().replace("\n", " — ")[2:])
    print("\n" + pg.inner_text("#verdict"))
    if errors: print("Erreurs JavaScript :", errors); ok = False
    if not ok:
        print("\n--- Journal technique ---\n" + pg.text_content("#raw")[-4000:])
    b.close()
srv.shutdown()
sys.exit(0 if ok else 1)
