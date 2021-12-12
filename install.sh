echo  -e \\e[94m "Downloading necessary files"

wget https://raw.githubusercontent.com/J-Fabila/VASP_to_XYZ/master/atomicpp.h
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/geometrias.cpp
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/distortions.cpp
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/sampling.py
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/extractor.py
wget https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/input.txt


echo  -e \\e[94m "Compiling executables"

chmox +x extractor.py
g++ -o forces.exe forces.cpp -lm
g++ -o geometries.exe distortions.cpp -lm

rm atomicpp.h

