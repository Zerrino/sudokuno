#!/usr/bin/env python3
"""Crée / active / liste les 3 dons de Sudokuno dans Google Play (API androidpublisher v3).

    uv run --with google-auth --with requests python android/tools/play_tips.py list|create|activate

Clé du compte de service : ~/.config/play-console-mcp/service-account.json (jamais dans le dépôt).
Les identifiants doivent rester ceux de services/TipJar.kt (et d'iOS).
"""
import json, os, sys, time
import google.auth.transport.requests as tr
from google.oauth2 import service_account

PKG = "com.alexafer.sudokuno"
KEY = os.path.expanduser("~/.config/play-console-mcp/service-account.json")
creds = service_account.Credentials.from_service_account_file(
    KEY, scopes=["https://www.googleapis.com/auth/androidpublisher"])
s = tr.AuthorizedSession(creds)
base = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}"

DESC_EN = "An optional tip to support Sudokuno. It unlocks nothing. Thank you!"
DESC_FR = "Un don facultatif pour soutenir Sudokuno. Il ne débloque rien. Merci !"
# (id, titre EN, titre FR, euros, nanos, achat multiple)
TIPS = [
    ("com.alexafer.sudokuno.tip.small", "Small coffee", "Petit café", 0, 990000000, True),
    ("com.alexafer.sudokuno.tip.medium", "Large coffee", "Grand café", 2, 990000000, False),
    ("com.alexafer.sudokuno.tip.large", "Coffee & croissant", "Café et croissant", 4, 990000000, False),
]


def call(method, url, **kw):
    for _ in range(5):
        r = s.request(method, url, **kw)
        if r.status_code not in (500, 503):
            break
        time.sleep(4)
    print(method, url.split("v3/")[-1][:90], r.status_code)
    try:
        return r.status_code, r.json()
    except Exception:
        return r.status_code, r.text


def show():
    code, res = call("GET", base + "/oneTimeProducts")
    if code != 200:
        print(res); sys.exit(1)
    for p in res.get("oneTimeProducts", []):
        print(" ", p["productId"], [o.get("state") for o in p.get("purchaseOptions", [])],
              [l["title"] for l in p.get("listings", [])])


mode = sys.argv[1] if len(sys.argv) > 1 else "list"
if mode == "create":
    for pid, en, fr, units, nanos, multi in TIPS:
        code, conv = call("POST", base + "/pricing:convertRegionPrices",
                          json={"price": {"currencyCode": "EUR", "units": str(units), "nanos": nanos}})
        if code != 200:
            print(conv); sys.exit(1)
        regional = [{"regionCode": rc, "price": v["price"], "availability": "AVAILABLE"}
                    for rc, v in conv["convertedRegionPrices"].items()]
        other = conv["convertedOtherRegionsPrice"]
        body = {
            "packageName": PKG, "productId": pid,
            "listings": [{"languageCode": "en-US", "title": en, "description": DESC_EN},
                         {"languageCode": "fr-FR", "title": fr, "description": DESC_FR}],
            "purchaseOptions": [{
                "purchaseOptionId": "standard",
                "buyOption": {"legacyCompatible": True, "multiQuantityEnabled": multi},
                "regionalPricingAndAvailabilityConfigs": regional,
                "newRegionsConfig": {"usdPrice": other["usdPrice"], "eurPrice": other["eurPrice"],
                                     "availability": "AVAILABLE"}}]}
        code, res = call("PATCH", base + f"/onetimeproducts/{pid}",
                         params={"updateMask": "listings,purchaseOptions", "allowMissing": "true",
                                 "regionsVersion.version": conv["regionVersion"]["version"]}, json=body)
        if code != 200:
            print(json.dumps(res)[:600]); sys.exit(1)
elif mode == "activate":
    for pid, *_ in TIPS:
        code, res = call("POST", base + f"/oneTimeProducts/{pid}/purchaseOptions:batchUpdateStates",
                         json={"requests": [{"activatePurchaseOptionRequest": {
                             "packageName": PKG, "productId": pid, "purchaseOptionId": "standard",
                             "latencyTolerance": "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT"}}]})
        if code != 200:
            print(json.dumps(res)[:600]); sys.exit(1)
show()
