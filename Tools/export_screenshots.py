# Extrait les captures App Store d'un .xcresult : python3 Tools/export_screenshots.py <xcresult> <dossier-sortie>
import json, os, shutil, subprocess, sys, tempfile
res, out = sys.argv[1], sys.argv[2]
tmp = tempfile.mkdtemp()
subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", res, "--output-path", tmp], check=True, capture_output=True)
os.makedirs(out, exist_ok=True)
for t in json.load(open(os.path.join(tmp, "manifest.json"))):
    for a in t["attachments"]:
        n = a.get("suggestedHumanReadableName", "")
        if n[:2].isdigit():
            shutil.copy(os.path.join(tmp, a["exportedFileName"]), os.path.join(out, n.split("_")[0] + ".png"))
print("\n".join(sorted(os.listdir(out))))
