import os
from pdbfixer import PDBFixer
from openmm.app import PDBFile

def preprocess_pdb(filename, output_name):
    fixer = PDBFixer(filename=filename)
    fixer.findMissingResidues()
    fixer.findMissingAtoms()
    fixer.addMissingAtoms()
    fixer.addMissingHydrogens()
    fixer.removeHeterogens(True)
    PDBFile.writeFile(fixer.topology, fixer.positions, open(output_name, 'w'))
    print(f"✔ {filename} → {output_name}")

def run_batch_fix():
    for file in os.listdir():
        if file.endswith("_u1.pdb") or file.endswith("_u2.pdb"):
            output_file = file.replace(".pdb", "_prepared.pdb")
            preprocess_pdb(file, output_file)

if __name__ == "__main__":
    run_batch_fix()
