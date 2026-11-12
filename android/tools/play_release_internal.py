#!/usr/bin/env python3
"""Envoie le bundle signé et le publie sur la piste de test INTERNE, en une seule modification Play.

    uv run --with google-auth --with requests python android/tools/play_release_internal.py <aab> <versionCode> <nom> [--dry]

Ne pas toucher à la Play Console pendant l'exécution (Google n'autorise qu'une modification ouverte à la fois).
Clé du compte de service : ~/.config/play-console-mcp/service-account.json (jamais dans le dépôt).
"""
import os, sys
import google.auth.transport.requests as tr
from google.oauth2 import service_account

PKG = "com.alexafer.sudokuno"
NOTES = {
    "en-US": "• New: step-by-step explanation of any solved or created puzzle, with the technique and the reason for each step\n"
             "• Puzzle editor: auto-complete, extra numbers, symmetry, explained solution\n"
             "• Leaderboards now only count perfect puzzles: no hints, no mistakes, first attempt",
    "fr-FR": "• Nouveau : explication pas à pas de toute grille terminée ou créée, avec la technique et la raison de chaque coup\n"
             "• Créateur : complétion automatique, chiffres en trop, symétrie, résolution expliquée\n"
             "• Classements : seules les grilles parfaites comptent (sans indice, sans erreur, du premier coup)",
}
aab, code, name = sys.argv[1], sys.argv[2], sys.argv[3]
dry = "--dry" in sys.argv
creds = service_account.Credentials.from_service_account_file(
    os.path.expanduser("~/.config/play-console-mcp/service-account.json"),
    scopes=["https://www.googleapis.com/auth/androidpublisher"])
s = tr.AuthorizedSession(creds)
api = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}"


def ok(r, what):
    print(what, r.status_code)
    if r.status_code >= 300:
        print(r.text[:800]); sys.exit(1)
    return r.json() if r.text else {}


edit = ok(s.post(api + "/edits", json={}), "ouverture")["id"]
upload = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PKG}/edits/{edit}/bundles?uploadType=media"
with open(aab, "rb") as f:
    ok(s.post(upload, data=f, headers={"Content-Type": "application/octet-stream"}, timeout=600), "envoi du bundle")
ok(s.put(api + f"/edits/{edit}/tracks/internal", json={"track": "internal", "releases": [{
    "name": name, "versionCodes": [code], "status": "completed",
    "releaseNotes": [{"language": l, "text": t} for l, t in NOTES.items()]}]}), "piste interne")
ok(s.post(api + f"/edits/{edit}:validate"), "validation")
if dry:
    s.delete(api + f"/edits/{edit}")
    print("essai : rien n'a été publié"); sys.exit()
ok(s.post(api + f"/edits/{edit}:commit"), "publication")
print("version interne publiée :", name, code)
