#!/bin/bash
# AUTHORS: ALATHEA DAVIES AND TAYLOR KELSEY

# Declare an associative array for the Hubbard derivatives of each element for the 3ob parameters
declare -A HUBBARD
HUBBARD[Br]=-0.0573
HUBBARD[C]=-0.1492
HUBBBARD[Ca]=-0.034
HUBBARD[Cl]=-0.0697
HUBBARD[F]=-0.1623
HUBBARD[H]=-0.1857
HUBBARD[I]=-0.0433
HUBBARD[K]=-0.0339
HUBBARD[Mg]=-0.02
HUBBARD[N]=-0.1535
HUBBARD[Na]=-0.0454
HUBBARD[O]=-0.1575
HUBBARD[P]=-0.14
HUBBARD[S]=-0.11
HUBBARD[Zn]=-0.03

# Declare an associative array for the max angular momentum orbitals for each element for the 3ob parameters
declare -A MOMENTUM
MOMENTUM[Br]=d
MOMENTUM[C]=p
MOMENTUM[Ca]=p
MOMENTUM[Cl]=d
MOMENTUM[F]=p
MOMENTUM[H]=s
MOMENTUM[I]=d
MOMENTUM[K]=p
MOMENTUM[Mg]=p
MOMENTUM[N]=p
MOMENTUM[Na]=p
MOMENTUM[O]=p
MOMENTUM[P]=d
MOMENTUM[S]=d
MOMENTUM[Zn]=d

# Declare an associative array for the atomic/gaseous phase energy for each element (calculated so far)
declare -A ATOMIC_ENERGY
ATOMIC_ENERGY[C]=-38.055
ATOMIC_ENERGY[H]=-6.4926
ATOMIC_ENERGY[N]=-57.2033
ATOMIC_ENERGY[O]=-83.9795
ATOMIC_ENERGY[S]=-62.3719
ATOMIC_ENERGY[Br]=-79.5349
ATOMIC_ENERGY[F]=-115.2462
ATOMIC_ENERGY[Cl]=-84.1056
ATOMIC_ENERGY[K]=-2.3186

# Declare an associative array for the reference state energy for each element (calculated so far)
declare -A REFERENCE_ENERGY
REFERENCE_ENERGY[C]=-44.1197
REFERENCE_ENERGY[H]=-9.1083
REFERENCE_ENERGY[N]=-65.4249
REFERENCE_ENERGY[O]=-87.7172
REFERENCE_ENERGY[S]=-65.7086
REFERENCE_ENERGY[Br]=-81.167
REFERENCE_ENERGY[F]=-117.3936
REFERENCE_ENERGY[Cl]=-86.2041
REFERENCE_ENERGY[K]=-3.4933

scc_dftb_in () {
# 1 = $GEO
# 2 = $TOL
# 3 = $RESTART
# 4 = myHUBBARD
# 5 = myMOMENTUM
# 6 = $STACKING
if [[ $1 == *"gen"* ]]; then
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< "$1"
}
!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< "$1"

}
!
  fi
  cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
!
  if [[ $6 == "AB-Stagg" || $6 == "ABC" || $6 == "AA-Eclipsed" ]]; then
    printf "  FixAngles = Yes\n" >> dftb_in.hsd
    printf "  FixLengths = {No No No}\n" >> dftb_in.hsd
  fi
  if [ $2 == '1e-5' ]; then
    printf "  MaxForceComponent = 1e-4\n" >> dftb_in.hsd
    printf "  OutputPrefix = 1e-4-Out }\n" >> dftb_in.hsd
  else
    printf "  MaxForceComponent = $2\n" >> dftb_in.hsd
    printf "  OutputPrefix = $2-Out }\n" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!

Hamiltonian = DFTB {
SCC = Yes
SCCTolerance = $2
!
  if [[ $3 == "yes" ]]; then
    printf "ReadInitialCharges = Yes\n" >> dftb_in.hsd
  else
    printf "ReadInitialCharges = No\n" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!
MaxSCCIterations = 1000
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
HubbardDerivs {
!
  hubbard=$4[@]
  sccHUBBARD=("${!hubbard}")
  printf "%s\n" "${sccHUBBARD[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
SlaterKosterFiles = Type2FileNames {
  Prefix = "/project/design-lab/software/DFTB+/3ob-3-1/"
  Separator = "-"
  Suffix = ".skf" }
KPointsAndWeights = SupercellFolding {
  4 0 0
  0 4 0
  0 0 4
  0.5 0.5 0.5 }
MaxAngularMomentum {
!
  momentum=$5[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }
!
  if [ $2 == '1e-5' ]; then
    printf "%s\n" "Analysis = {" >> dftb_in.hsd
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  WriteEigenvectors = Yes" >> dftb_in.hsd
    printf "%s\n" "  AtomResolvedEnergies = Yes" >> dftb_in.hsd
    printf "%s\n" "  PrintForces = Yes }" >> dftb_in.hsd
  else
    printf "%s\n" "Analysis = {" >> dftb_in.hsd
    printf "%s\n" "  MullikenAnalysis = Yes }" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!

Parallel = {
  Groups = 8
  UseOmpThreads = Yes }

ParserOptions {
  ParserVersion = 14 }
!
  if [ $2 == '1e-5' ]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi
}

gen_submit () {
# $1 = TASK
# $2 = CPUS
# $3 = JOB_NAME
# $4 = PARTITION

	NODE=1
	MEM=30GB
	TIME=72:00:00

	SCRIPT_NAME=submit_$3

	PROC=$((NODE * $1))

	cat > $SCRIPT_NAME<<!
#!/bin/bash
#SBATCH --nodes=$NODE
#SBATCH --ntasks-per-node=$1
#SBATCH --cpus-per-task=$2
#SBATCH --account=design-lab
#SBATCH --time=$TIME
#SBATCH --job-name=$3
#SBATCH --output=$3.out
#SBATCH --partition=$4
#SBATCH --mem=$MEM
cd \$SLURM_SUBMIT_DIR
export OMP_NUM_THREADS=$2
module load miniconda3/24.3.0
conda activate /cluster/medbow/project/design-lab/software/DFTB+/dftb+
mpirun -n $PROC dftb+ > $3.log
conda deactivate
!
}

calculate_energies () {
# $1 = $GEN
# $2 = $cof
  printf "$1\n$2-Out-POSCAR" | gen-to-POSCAR.py
  GEO="$2-Out-POSCAR"
  ATOM_TYPES=($(sed -n 6p $GEO))
  N_TYPES=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${N_TYPES[@]}; do
    let N_ATOMS+=$i
    done

  E_atom=0
  E_ref=0
  count=0
  for element in ${ATOM_TYPES[@]}; do
    E_atom=$(echo $E_atom+${ATOMIC_ENERGY[$element]}*${N_TYPES[$count]} | bc)
    E_ref=$(echo $E_ref+${REFERENCE_ENERGY[$element]}*${N_TYPES[$count]} | bc)
    ((count++))
  done

  DETAILED=($(grep "Total energy" detailed.out))
  TOTAL_ENERGY=${DETAILED[4]}

  COHESIVE=$(echo "scale=3; ($E_atom - $TOTAL_ENERGY) / $N_ATOMS" | bc)
  ENTHALPY=$(echo "scale=3; ($TOTAL_ENERGY - $E_ref) / $N_ATOMS" | bc)

  cat > Energies.dat <<!
E(COH) $COHESIVE eV
H(f) $ENTHALPY eV
!
}

zeo () {
# $1 = $COFNAME
  convert=($(printf "1e-4-Out.gen\n$1.cif" | aseconvert.py))
  # Pore diameters
  ~/Software/zeo++-0.3/network -ha -res $1.res $1.cif > OUTPUT.zeo
  # Surface area
  ~/Software/zeo++-0.3/network -ha -sa 1.8 1.8 10000 $1.sa $1.cif >> OUTPUT.zeo
  # Accessible volume
  ~/Software/zeo++-0.3/network -ha -vol 1.8 1.8 10000 $1.vol $1.cif >> OUTPUT.zeo
}

scc1 () {
# $1 = $PARTITION
# $2 = $JOBNAME
# $3 = $TOL
# $4 = $COF
  gen_submit 8 1 $2 $1
  submit=($(sbatch submit_$2))
  JOBID=(${submit[3]})
  echo "$JOBID submitted"
  while :
  do
    stat=($(squeue -n $2))
    jobstat=(${stat[12]})
    if [ "$jobstat" == "PD" ]; then
        echo "$2 is pending..."
        sleep 5s
    else
        log_size=($(ls -l "$2.log"))
        size=(${log_size[4]})
        sleep 60s
        log_size2=($(ls -l "$2.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$2 is running..."
        elif [[ $size2 == $size ]]; then
          sleep 30s
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $2.log; then
            if [[ $3 == '1e-5' ]]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              densities=($(printf "$4\ngen\n1e-4-Out.gen" | atomdensities))
              calculate_energies '1e-4-Out.gen' $4
              zeo $4
              mv detailed* $2.log 1e-4-Out.* charges.* eigenvec.bin submit_$2 Energies.dat *.densities *.res *.sa *.vol *.zeo band.out $4-Out-POSCAR 1e-4-Outputs/
              rm *.gen *.xyz $4*.out *cif
              RESULT='final'
              break
            elif [[ $3 == '1e-1' || $3 = '1e-2' || $3 = '1e-3' ]]; then
              if [ ! -d "$3-Outputs" ]; then
                mkdir $3-Outputs
              fi
              cp $3-Out.gen charges.bin $3-Outputs/
              mv detailed.out $2.log submit_$2 $3-Outputs/
              sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
              sed -i "s/.*<<<.*/  <<< ""$3-Out.gen""/g" dftb_in.hsd
              sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd
              if [ $3 == '1e-1' ]; then
                TOL='1e-2'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $3 == '1e-2' ]; then
                TOL='1e-3'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $3 == '1e-3' ]; then
                TOL='1e-5'
                sed -i 's/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g' dftb_in.hsd
                sed -i 's/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out" }/g' dftb_in.hsd
                sed -i '/.*Analysis.*/d' dftb_in.hsd
                cat >> dftb_in.hsd <<!

Analysis = {
  MullikenAnalysis = Yes
  AtomResolvedEnergies = Yes
  WriteEigenvectors = Yes
  PrintForces = Yes }

Options {
  WriteChargesAsText = Yes
  WriteDetailedXML = Yes }
!
              fi
              sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
              echo "$2 has completed."
              JOBNAME="$4-scc-$TOL"
              RESULT='iteration'
              break
            fi
          elif grep -q "SCC is NOT converged" $2.log; then
            echo "$2 did NOT converge. User trouble-shoot required to check atoms."
            exit
          elif grep -q "ERROR!" $2.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          fi
        fi
      fi
  done
}

module load gcc/14.2.0 python/3.12.0

# The instruction file is passed as an arguement when the job is submitted
INSTRUCT=$1

# Read the input file for the COF name, starting tolerance, restart calculation, input structure file, and partition
COF=($(sed -n 1p $INSTRUCT))
TOL=($(sed -n 2p $INSTRUCT))
GEO=($(sed -n 3p $INSTRUCT))
RESTART=($(sed -n 4p $INSTRUCT))
PARTITION=($(sed -n 5p $INSTRUCT))
STACKING=($(sed -n 6p $INSTRUCT))

TASK=8
JOBNAME="$COF-scc-$TOL"

# Read input geometry file to get atom types and number of atoms
if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
else
  ATOM_TYPES=($(sed -n 6p $GEO))
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Write dftb_in.hsd for the first calculation
scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM $STACKING

# submit the first calculation
scc1 $PARTITION $JOBNAME $TOL $COF
if [ $RESULT == 'final' ]; then
  echo "$COF is fully relaxed!"
  exit
elif [ $RESULT == 'iteration' ]; then
  # Submit the second calculation
  scc1 $PARTITION $JOBNAME $TOL $COF $RESULT
  if [ $RESULT == 'final' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'iteration' ]; then
    # Submit the third calculation
    scc1 $PARTITION $JOBNAME $TOL $COF $RESULT
    if [ $RESULT == 'final' ]; then
      echo "$COF is fully relaxed!"
      exit
    elif [ $RESULT == 'iteration' ]; then
      # Submit the final calculation
      scc1 $PARTITION $JOBNAME $TOL $COF $RESULT
      if [ $RESULT == 'final' ]; then
      echo "$COF is fully relaxed!"
      exit
      fi
    fi
  fi
fi