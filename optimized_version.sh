echo -e \\e[32m  " "
echo " Reading input.txt file  "
input_file=input.txt
selected_calculation=$(grep "calculation" $input_file | awk '{print $3}' )
sampling_parameter=$(grep "sampling_parameter" $input_file | awk '{print $3}')
selected_sampling=$(grep "type_of_sampling" $input_file | awk '{print $3}')
sampling_size=$(grep "sampling_size" $input_file | awk '{print $3}')
dir_name=$(grep "directory_name" $input_file | awk '{print $3}')

case $# in
   0)
      if [ $selected_calculation = 1 ]
      then
         echo -e \\e[91m "No input data file provided"
         exit
      fi
   ;;
   1)
      if ! [ -f $1 ]
      then
         echo  -e \\e[91m " $1 file does not exists"
         exit
      fi
   ;;
esac
######################################################################
function redraw_progress_bar { # int barsize, int base, int i, int top
    local barsize=$1
    local base=$2
    local current=$3
    local top=$4
    local j=0
    local progress=$(( ($barsize * ( $current - $base )) / ($top - $base ) ))
    echo -n "["
    for ((j=0; j < $progress; j++)) ; do echo -n '='; done
    echo -n '=>'
    for ((j=$progress; j < $barsize ; j++)) ; do echo -n ' '; done
    echo -ne "] $(( $current )) / $top " $'\r'
}
######################################################################

#######################################################
#######################################################
if [ $selected_calculation = 1 ]
then
   echo " Extracting data from $1"
   echo " "
   ## Determina número de átomos
   Nat=$(grep -m 1 "| Number of atoms" $1  | awk '{print $6}')
   ## Determina número de configuraciones (pasos)
   Nconf=$(grep "Self-consistency cycle converged" $1  | wc -l)
   ## Obtiene coordenadas iniciales
   grep -A$((5+$(echo $Nat))) "Parsing geometry.in (first pass over file, find array dimensions only)." $1  | grep "atom" > initial_configuration.fhi
   ## Extrae lista de energias
   echo  -e \\e[32m "Extracting uncorrected energy data"
   echo " "
   pv $1 | grep  "Total energy uncorrected"  | awk '{print $6}' > energias_uncorrected # puede ser: | Total energy uncorrected  | Total energy corrected | Electronic free energy ;
   echo " "
   echo  -e \\e[32m "Extracting corrected energy data"
   echo " "
   pv $1 | grep  "Total energy corrected"  | awk '{print $6}' > energias_corrected
   echo " "
   echo  -e \\e[32m "Extracting free energy data"
   echo " "
   pv $1 | grep -A2  "Total energy uncorrected" | grep "Electronic free energy" | awk '{print $6}' > energias_free
   echo " "
   echo  -e \\e[32m "Collecting into  energies.csv file"
   echo " " ; echo " "
   paste energias_corrected energias_uncorrected  > temp ; paste temp energias_free > energies.temp
   awk '{print $1","$2","$3}' energies.temp > energies.csv; rm temp energies.temp
   # Separa momento dipolar, uno por configuración
   echo " "
   echo  -e \\e[32m "Extracting dipolar moment components"
   echo " "
   pv $1 | grep "Total dipole moment"  | awk '{print $7 " " $8 " " $9}' > dipolos_vec
   echo " "
   echo  -e \\e[32m "Extracting dipolar moment magnitudes"
   echo " "
   grep "Absolute dipole moment" $1 | awk '{print $6}' > dipolos_abs
   echo " "
   echo  -e \\e[32m "Collecting data into dipoles.csv"
   echo " " ; echo " "

   paste dipolos_vec dipolos_abs > dipole.temp ; rm dipolos_vec dipolos_abs
   awk '{print $1","$2","$3","$4}' dipole.temp > dipoles.csv; rm dipole.temp
   # Junta los datos de energias y dipolos
   #paste energias dipolos > energies_dipoles.csv ; rm energias dipolos
   ## Separa las posiciones atómicas
   echo  -e \\e[32m "Extracting atomic positions"
   echo " "
   pv $1 | grep -A$((1+2*$(echo $Nat))) "Atomic structure (and velocities) as used in the preceding time step:"  | grep "atom" > posiciones
   # Hace falta separar todo el archivo en individuales
   ## Separa las velocidades atómicas
   echo " "
   echo  -e \\e[32m "Extracting atomic velocities" ; echo " "
   pv $1 | grep -A$((1+2*$(echo $Nat))) "Atomic structure (and velocities) as used in the preceding time step:"  | grep "velocity" > velocidades
   # Hace falta separar todo el archivo en individuales
   # Separa las fuerzas atómicas unidades  [eV/Ang]:
   echo " "
   echo  -e \\e[32m "Extracting atomic forces" ; echo " "
   pv $1 | grep -A40 "Total atomic forces (unitary forces cleaned)"  | grep "|" > fuerzas
   # Idem: Capaz k lo podríamos hacer en el mismo loop
   echo " " ; echo " " ; echo " "
   echo  -e \\e[32m "Preparing formatted files" ; echo " "
   suf_len=5
   split -l$Nat --numeric-suffixes=1 --suffix-length=$suf_len  posiciones "posiciones_"
   split -l$Nat --numeric-suffixes=1 --suffix-length=$suf_len  fuerzas "fuerzas_"
#La numeracion comienza en 1
   ls posiciones_* | cut -d"_" -f2  > archivos
   nl=$(wc -l posiciones_$(head -1 archivos) | awk '{print $1}' ) ## Segun entiendo deberia  ser igual wc -l temp quue de posiciones*.fhi
   yes "atom " | head -$nl > atoms
   yes " 0.0 0.0 " | head -$nl > zeros
   cat archivos | parallel echo begin ">" coords_{}
   cat archivos | parallel echo comment configuration {} of $Nconf" >> coords_{}

   cat archivos | parallel awk \'{print $2" "$3" "$4" "$5}\' posiciones_{} ">" posiciones_{}.temp
   cat archivos | parallel awk \'{print $2" "$3" "$4" "$5}\' fuerzas_{} ">" fuerzas_{}.temp

   cat archivos | parallel paste atoms posiciones_{}.temp ">" temp_coords_{}
   cat archivos | parallel paste temp_coords_{} zeros ">" temp_coords_2_{}
   cat archivos | parallel paste temp_coords_2_{} fuerzas_{}.temp ">>" coords_{}
################################################################################ paralelizar el sed ???
   cat energias_uncorrected | parallel echo {} ">>" coords_{}
#########################################################################################################
   cat archivos | parallel echo charge 0.0 ">" coords_{}
   cat archivos | parallel echo end ">" coords_{}
   parallel  tr \'\\t\' \'b\' "<" coords_{1} ">" coords_{1}.fhi :::: archivos
   cat archivos | parallel rm coords_{}  posiciones_{}.temp fuerzas_{}.temp temp_coords_{} temp_coords_2_{}
   rm archivos posiciones_* fuerzas_* zeros atoms # energias_uncorrected
###########################################################################################################
   echo " "
   echo " Calculating average of forces and collecting into forces.csv"
   echo " "
   ./forces.exe > forces.csv
   echo " Calculating average geometric distortions and collecting into desv.csv"
   echo " "
   ./geometries.exe > desv.csv
   if [ -d $dir_name ]
   then
      echo -e \\e[91m  " $dir_name directory already exists ... moving existing $dir_name to \"other_$dir_name\" "
      echo " Current data will be saved to $dir_name"
      echo -e \\e[32m " "
      mv $dir_name other_$dir_name
   fi
   mkdir $dir_name
   cd $dir_name
   mkdir data
   mkdir selected_data
   cd ..
   mv forces_*fhi $dir_name/data
   mv coords_*fhi $dir_name/data
   mv positions*fhi $dir_name/data
   mv velocities*fhi $dir_name/data
   rm atoms zeros energias* temp* forces.dat
   mv *csv $dir_name
   mv movie.xyz $dir_name
   mv initial_configuration.fhi $dir_name
fi

if [ $selected_calculation = 1 ] || [ $selected_calculation = 2 ]
then
   echo " "
   echo " Executing python sampling" ; echo " "
   echo -n " Sampling method selected:  "
   case $selected_sampling in
      1)
         echo -e " Monte Carlo \n"
      ;;
      2)
         echo -e " Uniform distribution \n"
      ;;
      3)
         echo -e " Random \n"
      ;;
      4)
         echo -e " Cutted trajectory \n"
      ;;
      *)
         echo -e \\e[91m " $selected_sampling is not a valid option \n"
         echo -e " Aborting execution \n"
         exit
      ;;
   esac

   python3 sampling.py $dir_name $selected_sampling $sampling_size $sampling_parameter 2> error

   if [ -f error ] && [ $(wc -l error | awk '{print $1}') -gt 0 ]
   then
      echo -e \\e[91m " An error with Python ocurred when sampling data: " ; echo " "
      cat error ; echo " " ; rm error
      echo " "; echo " "
      echo -e \\e[32m " " ; echo " Aborting execution" ; echo " "

      exit
   else
      echo " Data correctly sampled" ; echo " "
      if [ -f error ]
      then
         rm error
      fi
   fi
   cd $dir_name
   if [ -d selected_data ]
   then
      echo " " > /dev/null
   else
      mkdir selected_data
   fi
   echo " " ; echo " Preparing input data set with selected points" ; echo " " ;
   num_points=$(cat ../selected_points.csv | wc -l | awk '{print $1}')
   Nconf=$(cat forces.csv | wc -l | awk '{print $1}')
   frac=$(echo "scale=3; $num_points / $Nconf *100" | bc -l)
   echo " $num_points were selected  out of $Nconf (${frac}%)"; echo " "
   iter=1
   for i in $(cat ../selected_points.csv | tr '\n' ' ')
   do
      cp data/coords_${i}.fhi selected_data
      cat data/coords_${i}.fhi >> selected_data/training.dat
      redraw_progress_bar 50 1 $iter $num_points
      echo -ne "[\r"
      iter=$(($iter+1))
   done
   echo " " ; echo " " ; echo " " ;

   mv ../*.csv .
   cd ..
fi

if [ $selected_calculation = 1 ] || [ $selected_calculation = 2 ] || [ $selected_calculation = 3 ]
then
   read_input=$(grep "read_input" $input_file | awk '{print $3}' )
   generate_automatic_input=$(grep "generate_automatic_input" $input_file | awk '{print $3}' )
   if [ $(echo $read_input | tr '[:upper:]' '[:lower:]' ) = "false" ] ||  [ $(echo $read_input | tr '[:upper:]' '[:lower:]' ) = "no" ] || [ $read_input = "0" ] [ $(echo $read_input | tr '[:upper:]' '[:lower:]' ) = ".false." ]
   then
      echo -e " No input file given \n"
      if [ generate_automatic_input = 1 ]
      then
         echo " Generating automatic input file "
         ################## Default parameters
         rcutoff=6.0
         cutoff_type=6
         eta=2.0
         zeta=2.0
         lambda=1.0 # lambda= \pm 1
         rshift=0.0
         scale_min=0.0
         scale_max=1.0
         #####################################
         n_hidden=$(grep "n_hidden" $input_file | awk '{print $3}' )
         n_neurons=$(grep "n_neurons" $input_file | cut -d"=" -f2 | cut -d"#" -f1)
         activations=$(for i in $(echo $n_neurons) ; do  echo -n "t " ; done ; echo "l")
         elements=$(cat $dir_name/initial_configuration.fhi  | awk '{print $5}' | sort | uniq | tr '\n' ' ')
         n_elements=$(cat $dir_name/initial_configuration.fhi  | awk '{print $5}' | sort | uniq | wc -l )
         Nat=$(cat $dir_name/initial_configuration.fhi | grep "atom" | wc -l )
#================================================================================================================================
echo "###############################################################################
# Length unit     : Angstrom
# Energy unit     : eV
# Reference method: PBE
###############################################################################

###############################################################################
# GENERAL NNP SETTINGS
###############################################################################
# These keywords are (almost) always required.
number_of_elements              $n_elements
elements                        $elements
cutoff_type                     $cutoff_type          # Cutoff type.
#scale_symmetry_functions                       # Scale all symmetry functions with min/max values.
scale_symmetry_functions_sigma                 # Scale all symmetry functions with sigma.
scale_min_short                 $scale_min            # Minimum value for scaling.
scale_max_short                 $scale_max            # Maximum value for scaling.
#center_symmetry_functions                      # Center all symmetry functions, i.e. subtract mean value.
global_hidden_layers_short      $n_hidden              # Number of hidden layers.
global_nodes_short              $n_neurons          # Number of nodes in each hidden layer.
global_activation_short         $activations          # Activation function for each hidden layer and output layer.
#normalize_nodes                                # Normalize input of nodes."> input.nn
#================================================================================================================================
         for ((i=0;i<$Nat;i++)) #element in $(cat $dir_name/initial_configuration.fhi  | awk '{print $5}' | tr '\n' ' ')
         do
            echo -n "symfunction_short $element " >> input.nn
            case $# in
               2)
                  #symfunction_short <element-central> 2 <element-neighbor> <eta> <rshift> <rcutoff>
                  echo  $type $element_neighbor $eta $rshift $rcutoff >> input.nn
               ;;
               3)
                  #symfunction_short <element-central> 3 <element-neighbor1> <element-neighbor2> <eta> <lambda> <zeta> <rcutoff> <<rshift>
                  echo  $type $element_neighbor1 $element_neighbor2 $eta $lambda $zeta $rcutoff $rshift >> input.nn
               ;;
               9)
                  #symfunction_short <element-central> 9 <element-neighbor1> <element-neighbor2> <eta> <lambda> <zeta> <rcutoff> <<rshift>
                  echo  $type $element_neighbor1 $element_neighbor2 $eta $lambda $zeta $rcutoff $rshift >> input.nn
               ;;
              12)
                  #symfunction_short <element-central> 12 <eta> <rshift> <rcutoff>
                  echo  $type $eta $rshift $rcutoff >> input.nn
               ;;
              13)
                  #symfunction_short <element-central> 13 <eta> <rshift> <lambda> <zeta> <rcutoff>
                  echo  $type $eta $lambda $zeta $rcutoff $rshift >> input.nn
               ;;
            esac
         done
         mv input.nn $dir_name
      else
         echo " generate_automatic_input variable was setted to 0 (false)"
         echo -e " no input file will be generated \n"
         echo " Stoping execution"
         exit
      fi
   else
      echo -e " Working with given $read_input file \n"
      mv $read_input $dir_name/
   fi
   cd $dir_name
   #train?


fi

## Alternativa split
# split -l 4 texto.text output_
# split -l300 --numeric-suffixes=1 --suffix-length=1 --additional-suffix=".lst"  file ""
## Optimizacion del head -$NUM | tail -1:
# sed "${NUM}q;d" file

#PROGRESS BARS
# https://www.it-swarm-es.com/es/bash/usando-bash-para-mostrar-un-indicador-de-progreso/1069184172/
    echo "RUNNING N2P2"
