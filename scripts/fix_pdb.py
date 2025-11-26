from pdbfixer import PDBFixer
from openmm.app import PDBFile
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

fixer = PDBFixer(filename=input_file)
fixer.removeHeterogens(keepWater=False)
fixer.findMissingResidues()
fixer.findMissingAtoms()
fixer.addMissingAtoms()
fixer.addMissingHydrogens()
PDBFile.writeFile(fixer.topology, fixer.positions, open(output_file, "w"))