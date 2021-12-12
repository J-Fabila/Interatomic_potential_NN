echo  -e \\e[32m " #########################################################"
echo  -e \\e[32m " ############################# Downloading necessary files"
echo  -e \\e[32m " #########################################################"
echo  -e \\e[94m " "
wget https://raw.githubusercontent.com/J-Fabila/VASP_to_XYZ/master/atomicpp.h
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/forces.cpp
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/distortions.cpp
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/sampling.py
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/extractor.sh
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/input.txt


echo  -e \\e[94m "Compiling executables"

chmod +x extractor.sh
g++ -o forces.exe forces.cpp -lm
g++ -o geometries.exe distortions.cpp -lm

rm atomicpp.h forces.cpp distortions.cpp

echo  -e \\e[32m " #########################################################"
echo  -e \\e[32m " #################################################### Done"
echo  -e \\e[32m " #########################################################"
