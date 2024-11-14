# Automated Relaxation of Materials with DFTB+
This repository contains scripts written by A. Davies and T. Kelsey to automate the relaxation of structures using the package, DFTB+. The current form of these scripts is written to work on the UWyo ARCC HPC, MedicineBow. If the HPC environment changes, be sure to follows the changes in [If the HPC environment changes...](#if-the-hpc-environment-changes). Be sure to copy all files in [bin](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/bin) into your personal bin and make them executable.

This script is currently *only* written to work with the 3ob-3-1 parameter set. If you would like to run a calculation using a different parameter set or using extended tight-binding, you will need to edit **auto-relax.sh** yourself. 

The primary automation is done by the bash script, **auto-relax.sh**. The structure in question is iteratively relaxed over four sequences starting from a SCC (eV)/Force (eV/Å) tolerance of 1e-1. The second sequence uses a SCC/Force tolerance of 1e-2. The third sequence uses a SCC/Force tolerance of 1e-3. The final sequence uses a SCC tolerance of 1e-5 and a Force tolerance of 1e-4. After each sequence is complete, a directory will be made titled **{TOL}-Outputs**. For instance, the directory containing the 1e-1 tolerance results is called **1e-1-Outputs**. The results stored in each directory are:
- charges.bin
- {TOL}.gen
- detailed.out
- submit_{COF}-scc-{TOL}
- {COF}-scc-{TOL}.log

**auto-relax.sh** also automatically calculates desired properties of the final structure. These properties are, including their output filename:
- The atomic densities ({COF}.densities)
- The cohesive energy and enthalpy of formation (Energies.dat)
- Pore diameters, surface areas, and volumes ({COF}.res, {COF}.sa, and {COF}.vol)

For a finished calculation, the final directory (1e-4-Outputs) will contain:
- charges.bin
- 1e-4-Out.gen
- 1e-4-Out.xyz
- charges.dat 
- detailed.out
- detailed.xml 
- eigenvec.bin
- {COF}-scc-1e-4.log
- band.out 
- {COF}-Out-POSCAR
- {COF}.densities
- Energies.dat
- {COF}.res
- {COF}.sa
- {COF}.vol
- OUTPUT.zeo

A file called **{BASH-JOBNAME}.out** will contain a "status" report and SLURM JOBID for each sequence of the calculation.

This script can be executed by running the following command: 

<code>auto-relax.sh relax.in</code>. 

*PLEASE* use a submit script to submit this job to your queue manager. *DO NOT RUN IT IN COMMAND LINE VIA A LOG IN NODE.* [An example submit script](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/bin/submit_auto-relax) has been provided for your guidance.

**auto-relax.sh** automatically generates the following files based on the user input into **relax.in**:
1. dftb_in.hsd 
2. submit_{COF}-scc-{TOL}
This means that the only files the user must support are the initial structure file and **relax.in**. The other necessary files will be generated by either **auto-relax.sh** or by DFTB+ for the following runs. 

An example calculation, along with output files, has been included in the directory [example](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/submit_auto-relax/example/).

## Use

Be sure to copy all of the files in [bin](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/submit_auto-relax/bin/) into your local bin. Make each file an executable by running the following command:

<code>chmod u+x {FILENAME}</code> 

In your calculation directory, be sure to have your relax.in instruction file and your initial geometry file. Use the [submit script](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/bin/submit_auto-relax) to run **auto-relax.sh** with the following command:

<code>submit_auto-relax relax.in {BASH-JOBNAME}</code>

A file called {BASH-JOBNAME}.out will be generated that keeps a status of the automated calculation. When you check your queue, you will usually have two calculations running: your **{BASH-JOBNAME}** calculation and the iteration of DFTB+ calculation submitted by auto-relax.

## Dependencies

All files that **auto-relax.sh** depends on are located in [bin](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/submit_auto-relax/bin/). As mentioned above, be sure to copy these into your local bin and make them executable. 

The Python files contain additional dependencies. **aseconvert.py** requires the [ASE Python package](https://wiki.fysik.dtu.dk/ase/install.html) installed, **gen-to-POSCAR.py** requires the [pandas](https://pandas.pydata.org/docs/getting_started/install.html) package, and **atomdensities.py** requires the [numpy](https://numpy.org/install/) and [ASE](https://wiki.fysik.dtu.dk/ase/install.html) packages. Please see each of these packages to follow their installation instructions if you do not have these packages installed on your HPC account. It is recommended to use pip install for each of these packages.

## Relax.in

 [An example relax.in](https://github.com/ADavies2/Auto-DFTB-Relax/tree/main/submit_auto-relax/example/relax.in) has been provided for your guidance. **relax.in** should contain 5 lines with only the information that you desire on them. Do not include comments on each line as the current version of auto-relax.sh does not know how to interpret these.

- The COF_NAME must be the name of your COF with word separations made only by hyphens or underscores, no spaces.
- The INITIAL_TOLERANCE may be any setting between 1e-1 and 1e-4. If 1e-4 is given, **auto-relax.sh** will automatically set Forces = 1e-4 and SCC = 1e-5. 
- The INITIAL_STRUCTURE_FILE is the filename that contains your initial structure coordinates. POSCAR or .gen file types are recommended against .xyz types as DFTB+ does not read extended .xyz formats, meaning that the simulation cell parameters will not be included. 
- If the user has a previously converged charges.bin file for this system, they can initialize the DFTB+ calculation from that charges.bin file by setting RESTART to yes. If the user does not have a charges.bin file (i.e., this is a calculation from scratch), set RESTART to no.
- Give the desired partition name for the DFTB+ calculations to run on (mb, teton, inv-desousa, etc.) DFTB+ will not run on moran nodes.
- STACKING_CONFIGURATION will specify if the simulation cell angles will be fixed during the relaxation. Use this setting if you do not want the layers of your system to "slip", which is typically for AB-Stagg, ABC, or AA-Eclipse geometries. If you are modelling one of these three configurations, specify on this line either AB-Stagg, ABC, or AA-Eclipsed. If you are not running one of these three geometries or do not want the simulation cell angles fixed, leave this line empty or type None.

## If the HPC environment changes...

If you would like to run this script on a different HPC enviornment, you will need to change the following lines within **auto-relax.sh**

- Line 128: <code>Prefix = "/project/design-lab/software/DFTB+/3ob-3-1/"</code>
    - Update the path to correctly point to your Slater-Koster files. 
- Lines 199-202: <code>module load miniconda3/24.3.0 ... conda deactivate</code>
    - Update the lines from 199-202 to correctly load and execute DFTB+. This version was built with a Conda enviornment.
- Lines 243/245/247: <code>~/Software/zeo++-0.3/network...</code>
    - Update lines 243, 245 and 247 to include the correct path to your Zeo++ executable. 
- Line 373: <code>module load gcc/14.2.0 python/3.12.0</code>
    - Update this line to load the appropriate modules required for running Python on your HPC.

You will also need to make necessary changes to **submit_auto-relax** for your HPC enviornment.

## Known Issues

- 11/13/2024: DFTB+ on the MedicineBow HPC is being benchmarked currently. Once benchmarking is done, auto-relax.sh will be updated based on the benchmarking results. 

- DFTB+ is known to "stall" on the Beartooth HPC. When this happens, the calculation continues taking up time on the clock, but no data is written to the output files. **auto-relax.sh** attempts to account for this by checking for file size changes, and if the file size has not changed in 3 minutes, it assumes the job has stalled and kills the current iteraction job. Then, it uses the .gen produced from this iteration as the new input, lowers the number of tasks-per-node, and resubmits the calculation to restart from the last written point. It will be noted in **{BASH-JOBNAME}.out** when a job has stalled and been restarted. 
    - Sometimes, this can happen at the very beginning of the calculation before any data is written to the {TOL}.gen file. When this happens, **auto-relax.sh** will still tell DFTB+ to read this .gen file as the next input, but DFTB+ will crash because there is no data in the .gen file.
    - To circumnavigate this, instead of running from your current tolerance, for instance, if the job stalls at the first step of the 1e-1 iteration, changed **relax.in** to start from the next iteration, i.e., 1e-2. This usually fixes the problem and the calculation will continue running. Note, though, that this will not generate a 1e-1-Outputs directory, as this iteration has been skipped.