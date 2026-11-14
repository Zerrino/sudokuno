#!/usr/bin/env python3
"""Crée les classements et succès Google Play Jeux de Sudokuno (API gamesConfiguration v1configuration),
puis écrit leurs identifiants dans app/src/main/res/values/games-ids.xml.

    uv run --with google-auth --with requests python android/tools/play_games.py list|create
Les icônes (android/docs/achievements, générées par achievement_icons.swift) s'ajoutent à la main dans la console :
l'API ne permet plus d'envoyer d'images.

Idempotent : un classement / succès dont le nom anglais existe déjà n'est pas recréé.
Clé du compte de service : ~/.config/play-console-mcp/service-account.json (jamais dans le dépôt).
"""
import json, os, re, sys, time
import google.auth.transport.requests as tr
from google.oauth2 import service_account

APP_ID = "772167638482"  # ID du projet Play Jeux
# Langues déclarées dans Play Jeux › Configuration › Propriétés (fr-FR refusé tant qu'il n'y est pas ajouté)
LOCALES = {"en-US"}
KEY = os.path.expanduser("~/.config/play-console-mcp/service-account.json")
XML = os.path.join(os.path.dirname(__file__), "..", "app/src/main/res/values/games-ids.xml")
creds = service_account.Credentials.from_service_account_file(
    KEY, scopes=["https://www.googleapis.com/auth/androidpublisher"])
s = tr.AuthorizedSession(creds)
base = f"https://gamesconfiguration.googleapis.com/games/v1configuration/applications/{APP_ID}"

# ressource, EN, FR, format, ordre. Depuis la version 1.0.14 tout est classé au score : les classements au temps
# (« Daily Sudoku », « Best time: … », publiés, donc impossibles à supprimer) ne sont plus utilisés par l'app.
# L'ordre de cette liste donne l'ordre d'affichage (sortRank).
LEADERBOARDS = [
    ("leaderboard_score_daily", "Daily Sudoku score", "Score du jour", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_best", "Best game", "Meilleure partie", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_total", "Total score", "Total des scores", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_F", "Best score: Easy", "Record Facile", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_M", "Best score: Medium", "Record Moyen", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_D", "Best score: Hard", "Record Difficile", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_E", "Best score: Expert", "Record Expert", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_X", "Best score: Diabolical", "Record Diabolique", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_score_L", "Best score: Legend", "Record Légende", "NUMERIC", "LARGER_IS_BETTER"),
    ("leaderboard_streak", "Longest streak", "Plus longue série", "NUMERIC", "LARGER_IS_BETTER"),
]
# ressource, EN nom, EN description, FR nom, FR description, points
ACHIEVEMENTS = [
    ("achievement_unlock_M", "Medium unlocked", "Unlock the Medium level.", "Moyen débloqué", "Débloque le niveau Moyen.", 10),
    ("achievement_unlock_D", "Hard unlocked", "Unlock the Hard level.", "Difficile débloqué", "Débloque le niveau Difficile.", 20),
    ("achievement_unlock_E", "Expert unlocked", "Unlock the Expert level.", "Expert débloqué", "Débloque le niveau Expert.", 30),
    ("achievement_unlock_X", "Diabolical unlocked", "Unlock the Diabolical level.", "Diabolique débloqué", "Débloque le niveau Diabolique.", 50),
    ("achievement_streak_7", "7-day streak", "Solve the Daily Sudoku 7 days in a row.", "Série de 7 jours", "Résous le Sudoku du jour 7 jours de suite.", 20),
    ("achievement_streak_30", "30-day streak", "Solve the Daily Sudoku 30 days in a row.", "Série de 30 jours", "Résous le Sudoku du jour 30 jours de suite.", 50),
    ("achievement_streak_100", "100-day streak", "Solve the Daily Sudoku 100 days in a row.", "Série de 100 jours", "Résous le Sudoku du jour 100 jours de suite.", 100),
    ("achievement_streak_365", "365-day streak", "Solve the Daily Sudoku every day for a year.", "Série de 365 jours", "Résous le Sudoku du jour chaque jour pendant un an.", 200),
    ("achievement_perfect", "Perfect", "Solve a puzzle with no hints and no mistakes.", "Parfait", "Résous une grille sans indice ni erreur.", 20),
    ("achievement_diabolique_first", "Diabolical!", "Solve your first Diabolical puzzle.", "Diabolique !", "Résous ta première grille Diabolique.", 50),
    ("achievement_challenge_won", "Challenge won", "Beat a friend's time on a shared puzzle.", "Défi gagné", "Bats le temps d'un ami sur une grille partagée.", 20),
    ("achievement_streak_1000", "1000-day streak", "Solve the Daily Sudoku 1000 days in a row.", "Série de 1000 jours", "Résous le Sudoku du jour 1000 jours de suite.", 200),
    ("achievement_solved_100", "100 puzzles", "Solve 100 puzzles in total.", "100 grilles", "Résous 100 grilles au total.", 50),
    ("achievement_created_1", "Puzzle maker", "Create your first puzzle with the editor.", "Créateur", "Crée ta première grille avec l'éditeur.", 5),
    ("achievement_created_5", "5 puzzles created", "Create 5 puzzles with the editor.", "5 grilles créées", "Crée 5 grilles avec l'éditeur.", 10),
    ("achievement_created_10", "10 puzzles created", "Create 10 puzzles with the editor.", "10 grilles créées", "Crée 10 grilles avec l'éditeur.", 10),
    ("achievement_created_25", "25 puzzles created", "Create 25 puzzles with the editor.", "25 grilles créées", "Crée 25 grilles avec l'éditeur.", 15),
    ("achievement_created_50", "50 puzzles created", "Create 50 puzzles with the editor.", "50 grilles créées", "Crée 50 grilles avec l'éditeur.", 20),
    ("achievement_created_100", "100 puzzles created", "Create 100 puzzles with the editor.", "100 grilles créées", "Crée 100 grilles avec l'éditeur.", 30),
    ("achievement_unlock_L", "Legend unlocked", "Unlock the Legend level.", "Légende débloquée", "Débloque le niveau Légende.", 30),
    ("achievement_legend_first", "Legendary!", "Solve one of the Legend puzzles, the hardest in the world.", "Légendaire !", "Résous une des grilles de la Légende, les plus dures du monde.", 60),
]
# Succès progressifs : nombre d'étapes (Play Jeux exige au moins 2 étapes ; 1 = succès normal).
STEPS = {"achievement_solved_100": 100, "achievement_created_5": 5, "achievement_created_10": 10,
         "achievement_created_25": 25, "achievement_created_50": 50, "achievement_created_100": 100}


def call(method, url, **kw):
    for _ in range(5):
        r = s.request(method, url, **kw)
        if r.status_code not in (500, 503):
            break
        time.sleep(4)
    print(method, url.split("v1configuration/")[-1][:80], r.status_code)
    try:
        body = r.json()
    except Exception:
        body = r.text
    if r.status_code >= 300:
        print(json.dumps(body, ensure_ascii=False)[:800]); sys.exit(1)
    return body


def bundle(en, fr):
    return {"kind": "gamesConfiguration#localizedStringBundle", "translations": [
        {"kind": "gamesConfiguration#localizedString", "locale": locale, "value": value}
        for locale, value in (("en-US", en), ("fr-FR", fr)) if locale in LOCALES]}


def listing(kind):
    items, token = [], None
    while True:
        res = call("GET", f"{base}/{kind}", params={"maxResults": 200, **({"pageToken": token} if token else {})})
        items += res.get("items", [])
        token = res.get("nextPageToken")
        if not token:
            return items


def en_name(item):
    draft = item.get("draft") or item.get("published") or {}
    for t in draft.get("name", {}).get("translations", []):
        if t["locale"] == "en-US":
            return t["value"]


mode = sys.argv[1] if len(sys.argv) > 1 else "list"
existing_lb = {en_name(i): i["id"] for i in listing("leaderboards")}
existing_ach = {en_name(i): i["id"] for i in listing("achievements")}
ids = {}
for rank, (res, en, fr, fmt, order) in enumerate(LEADERBOARDS, 1):
    if en in existing_lb:
        ids[res] = existing_lb[en]
    elif mode == "create":
        body = {"kind": "gamesConfiguration#leaderboardConfiguration", "token": res, "scoreOrder": order,
                "draft": {"kind": "gamesConfiguration#leaderboardConfigurationDetail", "name": bundle(en, fr),
                          "scoreFormat": {"numberFormatType": fmt, **({"numDecimalPlaces": 0} if fmt == "NUMERIC" else {})}, "sortRank": rank}}
        ids[res] = call("POST", f"{base}/leaderboards", json=body)["id"]
for rank, (res, en, den, fr, dfr, pts) in enumerate(ACHIEVEMENTS, 1):
    if en in existing_ach:
        ids[res] = existing_ach[en]
    elif mode == "create":
        steps = STEPS.get(res)
        body = {"kind": "gamesConfiguration#achievementConfiguration", "token": res,
                "achievementType": "INCREMENTAL" if steps else "STANDARD", "initialState": "REVEALED",
                **({"stepsToUnlock": steps} if steps else {}),
                "draft": {"kind": "gamesConfiguration#achievementConfigurationDetail", "name": bundle(en, fr),
                          "description": bundle(den, dfr), "pointValue": pts, "sortRank": rank}}
        ids[res] = call("POST", f"{base}/achievements", json=body)["id"]

for k, v in ids.items():
    print(f"  {k:32} {v}")

if mode == "create":
    xml = open(XML, encoding="utf-8").read()
    xml = re.sub(r'(name="game_services_project_id"[^>]*>)[^<]*<', rf"\g<1>{APP_ID}<", xml)
    for k, v in ids.items():
        if f'name="{k}"' in xml:
            xml = re.sub(rf'(name="{k}"[^>]*>)[^<]*<', rf"\g<1>{v}<", xml)
        else:  # nouvelle ressource
            xml = xml.replace("</resources>", f'    <string name="{k}" translatable="false">{v}</string>\n</resources>')
    open(XML, "w", encoding="utf-8").write(xml)
    print("games-ids.xml mis à jour")
