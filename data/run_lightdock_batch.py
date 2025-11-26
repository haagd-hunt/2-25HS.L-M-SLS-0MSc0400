import os
import subprocess

# Parameter
swarms = 1
glowworms = 20
steps = 50
models_to_generate = 10

# Hole alle *_u1_prepared.pdb-Dateien im aktuellen Ordner
files = [f for f in os.listdir() if f.endswith("_u1_prepared.pdb")]

for rec_file in files:
    base = rec_file.replace("_u1_prepared.pdb", "")
    lig_file = f"{base}_u2_prepared.pdb"

    if not os.path.isfile(lig_file):
        print(f"❌ Ligand fehlt zu {base}, übersprungen.")
        continue

    # Erstelle Unterordner
    run_dir = f"{base}_docking"
    os.makedirs(run_dir, exist_ok=True)

    # Kopiere PDBs in den Unterordner
    os.system(f'copy {rec_file} {run_dir}\\{rec_file}')
    os.system(f'copy {lig_file} {run_dir}\\{lig_file}')

    # Wechsle in Unterordner und führe LightDock aus
    os.chdir(run_dir)
    print(f"\n🚀 Starte LightDock für {base}...")

    try:
        subprocess.run(
            ["lightdock3_setup.py", rec_file, lig_file, str(swarms), str(glowworms)],
            check=True
        )
        subprocess.run(
            ["lightdock3.py", "setup.json", str(steps)],
            check=True
        )
        subprocess.run(
            ["lgd_generate_conformations.py", rec_file, lig_file, f"swarm_0/gso_{steps}.out", str(models_to_generate)],
            check=True
        )
        print(f"✅ Fertig: {base}")
    except subprocess.CalledProcessError:
        print(f"❌ Fehler bei {base}")

    os.chdir("..")  # Zurück zum Hauptordner
