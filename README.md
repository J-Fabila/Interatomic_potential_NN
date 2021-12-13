# Installation

Download install.sh:

```
~$ wget  https://raw.githubusercontent.com/J-Fabila/Interatomic_potential_NN/main/install.sh
```

Change permissions

```
~$ chmod +x install.sh
```

Execute

```
~$ ./install.sh
```


# Already implemented:

---> Extracts geometries, forces, energies, dipoles, etc from *.fhi

---> Generates files with suitable format: X Y Z Fx Fy Fz

---> Executes forces and distortions programs

   ---> Calculates mean forces and mean distortions

   ---> Prints output to *csv files

---> Executes python sampling

   ---> Sample forces or energies

   ---> Output a list of selected configurations

---> Creates "data" directory which contains training data in appropriate format

# To implement:

---> Installation n2p2 (problems with installation)

---> Train NN model

---> Test performance and precision
