echo  -e \\e[94m "Downloading necessary files"

wget https://github.com/J-Fabila/interatomic_potential/edit/master/atomicpp.h
wget https://github.com/J-Fabila/interatomic_potential/edit/master/forces.cpp
wget https://github.com/J-Fabila/interatomic_potential/edit/master/distortions.cpp
wget https://github.com/J-Fabila/interatomic_potential/edit/master/sampling.py
wget https://github.com/J-Fabila/interatomic_potential/edit/master/extractor.py
wget https://github.com/J-Fabila/interatomic_potential/edit/master/input.txt


echo  -e \\e[94m "Compiling executables"

chmox +x extractor.py
g++ -o forces.exe forces.cpp -lm
g++ -o geometries.exe distortions.cpp -lm

rm atomicpp.h

