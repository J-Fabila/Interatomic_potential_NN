import pandas as pd
import numpy as np
#import matplotlib.pyplot as plt
#import seaborn as sns
#sns.set_style("darkgrid")
from sklearn.model_selection import train_test_split
import warnings
import sys
warnings.filterwarnings('ignore')

################################ Lectura de parámetros
path=sys.argv[1]
selected_sampling=int(sys.argv[2])
sampling_size=float(sys.argv[3])
sampling_parameter=int(sys.argv[4])
######################################################

############################# Declaración de funciones

def random_sampling(input_data,fraction=0.5):
    # Works for either forces or energies
    train, test = train_test_split(input_data, test_size=fraction)
    accepted_index=list(test.index)
    pd.DataFrame(accepted_index).to_csv("selected_points.csv", index=False, header=False,sep=' ')

def uniform_sampling_forces(forces,rad=2.0,num_cuantiles=10):
    # Works exclusively for forces
    forces=forces-forces.mean()
    lim_min=forces.Force.mean()-(rad*forces.Force.std() )
    lim_max=forces.Force.mean()+(rad*forces.Force.std() )
    cuantiles=np.linspace(lim_max,lim_min,num_cuantiles)
    frames=[]
    for i in range(num_cuantiles-1):
        numerador=forces.loc[(forces['Force']< cuantiles[i]) & (forces['Force']>cuantiles[i+1] )]
        total_muestras_cuantil=numerador.shape[0]
        if(i==0):
            num_muestras=numerador.shape[0]
        fraccion_necesaria=num_muestras/total_muestras_cuantil
        if(fraccion_necesaria>1):
            fraccion_necesaria=1
        train, test = train_test_split(numerador, test_size=fraccion_necesaria*0.99999)
        frames.append(test)
    tot_accepted = pd.concat(frames)
    numerador=forces.loc[(forces['Force']> (forces.Force.mean()+(rad*forces.Force.std() ) )) | (forces['Force']< (forces.Force.mean()-(rad*forces.Force.std() ) ))]
    frames.append(numerador)
    selected=pd.concat(frames)
    accepted_index=list(selected.index)
    pd.DataFrame(accepted_index).to_csv("selected_points.csv", index=False, header=False,sep=' ')
    return len(accepted_index)/forces.shape[0]

def uniform_sampling_energies(energies,rad=2.0,num_cuantiles=10):
    # Works exclusively for forces
    energies=energies-energies.mean()
    lim_min=energies.Uncorrected.mean()-(rad*energies.Uncorrected.std() )
    lim_max=energies.Uncorrected.mean()+(rad*energies.Uncorrected.std() )
    cuantiles=np.linspace(lim_max,lim_min,num_cuantiles)
    frames=[]
    for i in range(num_cuantiles-1):
        numerador=energies.loc[(energies['Uncorrected']< cuantiles[i]) & (energies['Uncorrected']>cuantiles[i+1] )]
        total_muestras_cuantil=numerador.shape[0]
        if(i==0):
            num_muestras=numerador.shape[0]
        fraccion_necesaria=num_muestras/total_muestras_cuantil
        if(fraccion_necesaria>1):
            fraccion_necesaria=1
        train, test = train_test_split(numerador, test_size=fraccion_necesaria*0.99999)
        frames.append(test)
    tot_accepted = pd.concat(frames)
    numerador=energies.loc[(energies['Uncorrected']> (energies.Uncorrected.mean()+(rad*energies.Uncorrected.std() ) )) | (energies['Uncorrected']< (energies.Uncorrected.mean()-(rad*energies.Uncorrected.std() ) ))]
    frames.append(numerador)
    selected=pd.concat(frames)
    accepted_index=list(selected.index)
    pd.DataFrame(accepted_index).to_csv("selected_points.csv", index=False, header=False,sep=' ')
    return len(accepted_index)/energies.shape[0]


def monte_carlo(T,energy,energy_0):
    k_BT = 0.00008617*T;
    criterio=np.exp(((energy-energy_0))/k_BT)
    if criterio > np.random.random(1)[0]:
        return (criterio,False)
    else:
        return (criterio,True)

v_monte_carlo=np.vectorize(monte_carlo)

def monte_carlo_forces(forces,temp): #solo fuerzas
    forces=forces-forces.mean()
    forces_s=forces.shift(-1)
    forces['Criterio'],forces['Accepted']=v_monte_carlo(temp,forces['Force'],forces_s['Force'])
    accepted=forces.loc[forces['Accepted']==True]
    accepted_index=list(accepted.index)
    pd.DataFrame(accepted_index).to_csv("selected_points.csv", index=False, header=False,sep=' ')
    return len(accepted.index)/forces.shape[0]

def monte_carlo_energies(energies,temp): #solo energias
    energies=energies-energies.mean()
    energies_s=energies.shift(-1)
    energies['Criterio'],energies['Accepted']=v_monte_carlo(temp,energies['Uncorrected'],energies_s['Uncorrected'])
    accepted=energies.loc[energies['Accepted']==True]
    accepted_index=list(accepted.index)
    pd.DataFrame(accepted_index).to_csv("selected_points.csv", index=False, header=False,sep=' ')
    return len(accepted.index)/energies.shape[0]

def cutted_trajectory(input_data,frac=0.5):
    # Funciona para fuerzas y energas
    long=input_data.shape[0]
    limit=int(long*fraction)
    input_data=input_data[:limit]
    accepted_index=list(input_data.index)
    pd.DataFrame(accepted_index).to_csv("cutted_energy_points.csv", index=False, header=False,sep=' ')

######################################################

##################################### Lectura de datos
if sampling_parameter == 0: # Fuerzas
    path=path+"/forces.csv"
    forces  =pd.read_csv(path,names=["Force"])
elif sampling_parameter == 1: #Energias
    path=path+"/energies.csv"
    energies  =pd.read_csv(path,names=["Corrected","Uncorrected","Free"])
######################################################

if selected_sampling == 1:
   #Monte Carlo
    if sampling_parameter == 0: #Forces
        fraction=sampling_size
        i=50
        temp=1
        frac=1
        tolerancia=0.025
        while  ( ((frac+tolerancia)<fraction) | ((frac-tolerancia)>fraction)):
            frac=monte_carlo_forces(forces,temp)
        #    print(frac,temp)
            temp=temp+i
            if temp>5000:
                break
    elif sampling_parameter ==1: #Energies
        fraction=sampling_size
        i=50
        temp=1
        frac=1
        tolerancia=0.025
        while  ( ((frac+tolerancia)<fraction) | ((frac-tolerancia)>fraction)):
            frac=monte_carlo_energies(energies,temp)
        #    print(frac,temp)
            temp=temp+i
            if temp>5000:
                break

elif selected_sampling == 2:
   #Uniform distribution
    if sampling_parameter == 0: #Forces
        fraction=sampling_size
        frac=1.0
        i=0.05
        rad=1
        tolerancia=0.025
        while  ( ((frac+tolerancia)<fraction) | ((frac-tolerancia)>fraction)):
            frac=uniform_sampling_forces(forces,rad,10)
#            print(frac,rad)
            rad=rad+i
            if rad>5:
                break

    elif sampling_parameter ==1: #Energies
        fraction=sampling_size
        frac=1
        i=0.05
        rad=1
        tolerancia=0.025
        while  ( ((frac+tolerancia)<fraction) | ((frac-tolerancia)>fraction)):
            frac=uniform_sampling_energies(energies,rad,10)
#            print(frac,rad)
            rad=rad+i
            if rad>5:
                break

elif selected_sampling == 3:
   #Random
   if sampling_parameter == 0: #Forces
       random_sampling(forces,sampling_size)
   elif sampling_parameter ==1: #Energies
       random_sampling(energies,sampling_size)
elif selected_sampling == 4:
   #Cutted trajectory
   if sampling_parameter == 0: #Forces
       cutted_trajectory(forces,sampling_size)
   elif sampling_parameter ==1: #Energies
       cutted_trajectory(energies,sampling_size)

