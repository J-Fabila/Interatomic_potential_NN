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
   Nat=$(grep "| Number of atoms" $1  | awk '{print $6}')
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

   for ((i=$Nat;i<=$(($Nconf*$Nat));i=i+$Nat))
   do
      j=$(($i/$Nat))
      head -$i posiciones   | tail -$Nat > positions_$j.fhi
      head -$i velocidades  | tail -$Nat > velocities_$j.fhi
      head -$i fuerzas  | tail -$Nat > forces_$j.fhi
      redraw_progress_bar 50 1 $j $Nconf
      ###################################################################
      echo "begin"> coords_$j
      echo "comment configuration ${j} of $Nconf" >> coords_$j
      # Lattice section is skipped because this is not a periodic system

      cat positions_$j.fhi | awk '{print $2" "$3" "$4" "$5}'  > temp ; cat forces_$j.fhi | awk '{print $3" "$4" "$5}' > temp2
      nl=$(wc -l temp | awk '{print $1}')
      ## Esto podria ir hasta arriba, asi evitamos repetirlo #
      yes "atom " | head -$nl > atoms
      yes " 0.0 0.0 " | head -$nl > zeros
      ########################################################
      ########################################################
      paste atoms temp > temp_coords1
      paste temp_coords1 zeros > temp_coords2
      paste temp_coords2 temp2 >> coords_$j
      energy=$(sed "${j}q;d" energias_uncorrected)
      echo "energy $energy" >> coords_$j
      echo "charge 0.0" >> coords_$j
      echo "end" >> coords_$j
      cat coords_$j | tr '\t' ' ' > coords_$j.fhi
      rm coords_$j
      ###################################################################

      #   echo "Preparing step $j/$Nconf"
      echo -ne "[\r"
   done
   echo " " ; echo " " ; echo " " ;

   rm posiciones velocidades fuerzas temp_coords*
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
fi

if [ $selected_calculation = 1 ] || [ $selected_calculation = 2 ] || [ $selected_calculation = 3 ]
then
   #RUNNING N2P2
    echo "RUNNING N2P2"
fi

## Alternativa split
# split -l 4 texto.text output_
# split -l300 --numeric-suffixes=1 --suffix-length=1 --additional-suffix=".lst"  file ""
## Optimizacion del head -$NUM | tail -1:
# sed "${NUM}q;d" file

#PROGRESS BARS
# https://www.it-swarm-es.com/es/bash/usando-bash-para-mostrar-un-indicador-de-progreso/1069184172/
