echo -e \\e[32m "Extracting data from $1"
echo " "
## Determina número de átomos
Nat=$(grep "| Number of atoms" $1  | awk '{print $6}')
## Determina número de configuraciones (pasos)
Nconf=$(grep "Self-consistency cycle converged" $1  | wc -l)
## Obtiene coordenadas iniciales
grep -A$((5+$(echo $Nat))) "Parsing geometry.in (first pass over file, find array dimensions only)." $1  | grep "atom" > configuracion_inicial.fhi
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
echo " "
echo  -e \\e[32m "Preparing formatted files" ; echo " "
for ((i=$Nat;i<=$(($Nconf*$Nat));i=i+$Nat))
do
   j=$(($i/$Nat))
   head -$i posiciones   | tail -$Nat > posiciones_$j.fhi
   head -$i velocidades  | tail -$Nat > velocidades_$j.fhi
   head -$i fuerzas  | tail -$Nat > fuerzas_$j.fhi

###################################################################
echo "begin"> coords_$j
echo "comment configuration${j} of $Nat" >> coords_$j
# Lattice section is skipped because this is not a periodic system

cat posiciones_$j.fhi | awk '{print $2" "$3" "$4" "$5}'  > temp ; cat fuerzas_$j.fhi | awk '{print $3" "$4" "$5}' > temp2 
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

   echo "Preparing step $j/$Nconf"
done
rm posiciones velocidades fuerzas temp_coords*
echo " "
echo "Calculating mean forces and collecting into forces.csv"
echo " "
./forces.exe > forces.csv
echo "Calculating mean geometric distortions and collecting into desv.csv"
echo " "
./geometries.exe > desv.csv

echo "Executing python sampling" ; echo " "
python3 sampling.py 2> /dev/null
mkdir data
for i in $(cat selected_points.csv | tr '\n' ' ')
do
   cp coords_${i}.fhi data
   cat coords_${i}.fhi >> data/training.dat
done

rm atoms zeros energias* temp*
## Alternativa split
# split -l 4 texto.text output_
# split -l300 --numeric-suffixes=1 --suffix-length=1 --additional-suffix=".lst"  file ""
## Optimizacion del head -$NUM | tail -1:
# sed "${NUM}q;d" file

#PROGRESS BARS
# https://www.it-swarm-es.com/es/bash/usando-bash-para-mostrar-un-indicador-de-progreso/1069184172/
