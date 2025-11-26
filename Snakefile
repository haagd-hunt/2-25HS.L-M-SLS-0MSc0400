configfile: "config.yaml"

# Define final target outputs: for each complex and each step count, a completion marker file
rule all:
    input:
        expand("complexes/{complex}/{complex}_rec.pdb", complex=config["complexes"]),
        expand("complexes/{complex}/{complex}_lig.pdb", complex=config["complexes"]),
        expand("complexes/{complex}/models_done_{steps}.txt",
               complex=config["complexes"],
               steps=config["steps"])
# 1. Fix the receptor PDB file
rule fix_receptor:
    conda: "envs/pdbfixer.yaml"
    input: "data/{complex}_u1.pdb"
    output: "complexes/{complex}/{complex}_rec.pdb"

    log: "logs/pdbfixer_{complex}_rec.log"
    shell:
        "python scripts/fix_pdb.py {input} {output} 2> {log}"

# 2. Fix the ligand PDB file
rule fix_ligand:
    conda: "envs/pdbfixer.yaml"
    input: "data/{complex}_u2.pdb"
    output: "complexes/{complex}/{complex}_lig.pdb"
    log: "logs/pdbfixer_{complex}_lig.log"
    shell:
        "python scripts/fix_pdb.py {input} {output} 2> {log}"

rule lightdock_setup:
    conda: ""
    "envs/lightdock.yaml"
    threads: 1
    input:"complexes/{wildcards.complex}/{wildcards.complex}_rec.pdb","complexes/{wildcards.complex}/{wildcards.complex}_lig.pdb"
    output:"complexes/{complex}/setup.json"
    params:
        glowworms = lambda wildcards: config["glowworms"]
  
    log:"logs/lightdock_setup_{complex}.log"
    shell:
        """
        if not exist complexes\\{wildcards.complex} mkdir complexes\\{wildcards.complex}
        python miniforge3\\envs\\lightdock_env\\Scripts\\lightdock3_setup.py ^
            complexes\\{wildcards.complex}\\{wildcards.complex}_rec.pdb ^
            complexes\\{wildcards.complex}\\{wildcards.complex}_lig.pdb ^
            -g {params.glowworms} --noxt --noh --now > {log} 2>&1
        """

# 4. LightDock Simulation: run the GSO algorithm
rule lightdock_run:
    conda: "envs/lightdock.yaml"
    threads: 1
    input:"complexes/{complex}/setup.json"
    output:"complexes/{complex}/swarm_0/gso_{steps}.out"
    params:
        models = lambda wildcards: config["models"],
        steps = lambda wildcards: config["steps"]
    log:"logs/lightdock_run_{complex}_{steps}.log"
    shell:
        """
        cd complexes\\{wildcards.complex} && lightdock3.py setup.json {params.steps} -c 1 \
            > ..\\..\\logs\\lightdock_run_{wildcards.complex}_{params.steps}.log 2>&1
        """
        # This runs the simulation for the specified number of steps.
        # Output appears in swarm_0 (gso_{steps}.out). We assume one swarm for simplicity.

# 5. LightDock Model Generation: create PDB models from the docking results
rule lightdock_generate:
    conda: "envs/lightdock.yaml"
    threads: 1
    input:"complexes/{complex}/swarm_0/gso_{steps}.out","complexes/{complex}/{complex}_rec.pdb","complexes/{complex}/{complex}_lig.pdb"
    output:"complexes/{complex}/models_done_{steps}.txt"
    params:
        models = lambda wildcards: config["models"],
        steps = lambda wildcards: config["steps"]
    log:"logs/lightdock_generate_{complex}_{steps}.log"
    shell:
        """
        cd complexes\\{wildcards.complex}\\swarm_0 && lgd_generate_conformations.py \
            ..\\{wildcards.complex}_rec.pdb ..\\{wildcards.complex}_lig.pdb gso_{params.steps}.out {params.models} \
            >> ..\\..\\logs\\lightdock_generate_{wildcards.complex}_{params.steps}.log 2>&1
        copy NUL ..\\models_done_{params.steps}.txt
        """
