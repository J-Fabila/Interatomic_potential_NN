import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("darkgrid")
from sklearn.model_selection import train_test_split
import warnings
warnings.filterwarnings('ignore')

forces  =pd.read_csv("forces.csv",names=["Force"])
# Centering values
forces=forces-forces.mean()
forces_s=forces.shift(-1)


fig, axs = plt.subplots(1, 2, figsize=(20, 10),sharey=True)
#axs[1].set_title("Histogram",fontsize=20)
#axs[0].set_title("Average distorsions",fontsize=20)

mean_=[forces["Force"].mean()]*forces.shape[0]
std_upper=[forces["Force"].mean()+(2*forces["Force"].std())]*forces.shape[0]
std_lower=[forces["Force"].mean()-(2*forces["Force"].std())]*forces.shape[0]

fig.suptitle('Forces distribution',fontsize=30)

axs[0].set_ylabel('Force [eV/A]',fontsize=20)
axs[0].set_xlabel('Time step', fontsize=20)
axs[1].set_xlabel('Frequency', fontsize=20)
#axs[0].set_xticklabels(fontsize=20)
axs[0].tick_params(axis="x", labelsize=20)
axs[0].tick_params(axis="y", labelsize=20)
axs[1].tick_params(axis="x", labelsize=20)


axs[1].hist(forces["Force"],orientation="horizontal",bins=30)
axs[0].plot(forces["Force"],label="Accepted  points",linestyle='none',marker='o',markersize=3)

#plt.xticks(fontsize=15) # Asigna tamaño de fuente = 15 a los números en el eje x
#plt.yticks(fontsize=15) # Asigna tamaño de fuente = 15 a los números en el eje y
axs[0].plot(mean_,label="Mean",linewidth=4.0,marker='o')
axs[0].plot(std_lower,label="Mean+2*Std",linewidth=4.0,marker='o')
axs[0].plot(std_upper,label="Mean-2*Std",linewidth=4.0,marker='o')
axs[0].legend(loc="upper left",fontsize=15)

#axs[1].plot(mean_,label="Mean",linewidth=4.0,marker='o')
#axs[1].plot(std_lower,label="Mean+Std",linewidth=4.0,marker='o')
#axs[1].plot(std_upper,label="Mean-Std",linewidth=4.0,marker='o')

fig.savefig("forces_hist.png") # Esto guarda la figura como en formato png.

forces  =pd.read_csv("forces.csv",names=["Force"])

###################### Parameters
rad=2.5               # times STD
num_cuantiles=10 # N of quantiles
#################################

forces=forces-forces.mean()
lim_min=forces.Force.mean()-(rad*forces.Force.std() )
lim_max=forces.Force.mean()+(rad*forces.Force.std() )
cuantiles=np.linspace(lim_max,lim_min,num_cuantiles)
frames=[]
for i in range(num_cuantiles-1):
    #print(cuantiles[i],cuantiles[i+1])
    numerador=forces.loc[(forces['Force']< cuantiles[i]) & (forces['Force']>cuantiles[i+1] )]
    total_muestras_cuantil=numerador.shape[0]
    #print(total_muestras_cuantil)
    if(i==0):
        num_muestras=numerador.shape[0]
     #   print(num_muestras)
    fraccion_necesaria=num_muestras/total_muestras_cuantil
    if(fraccion_necesaria>1):
        fraccion_necesaria=1
    #print(fraccion_necesaria)
    #sklearn fraction fraccion necesaria
    train, test = train_test_split(numerador, test_size=fraccion_necesaria*0.99999)
    #print("test",test.shape)
    frames.append(test)

tot_accepted = pd.concat(frames)
numerador=forces.loc[(forces['Force']> (forces.Force.mean()+(2*forces.Force.std() ) )) | (forces['Force']< (forces.Force.mean()-(2*forces.Force.std() ) ))]
frames.append(numerador)
selected=pd.concat(frames)

#fig, axs = plt.subplots(1, 2, figsize=(20, 10),sharey=True)
#axs[1].hist(tot_accepted["Force"],orientation="horizontal",bins=50)
#axs[0].plot(tot_accepted["Force"],label="Accepted  points",linestyle='none',marker='o',markersize=3)

print("Selected points: ",selected.shape[0]," out of ",forces.shape[0], "(",selected.shape[0]/forces.shape[0]*100,"%)")


numerador=forces.loc[(forces['Force']> (forces.Force.mean()+(rad*forces.Force.std() ) )) | (forces['Force']< (forces.Force.mean()-(rad*forces.Force.std() ) ))]

fig, axs = plt.subplots(1, 2, figsize=(20, 10),sharey=True)

fig.suptitle('Uniform sampling from normal distribution (Forces)',fontsize=30)

axs[0].set_ylabel('Force [eV/A]',fontsize=20)
axs[0].set_xlabel('Time step', fontsize=20)
axs[1].set_xlabel('Frequency', fontsize=20)
#axs[0].set_xticklabels(fontsize=20)
axs[0].tick_params(axis="x", labelsize=20)
axs[0].tick_params(axis="y", labelsize=20)
axs[1].tick_params(axis="x", labelsize=20)

axs[1].hist(forces["Force"],orientation="horizontal",bins=30,color="orange")
axs[0].plot(forces["Force"],label="Rejected  points",linestyle='none',marker='o',markersize=3,color="orange")

axs[1].hist(numerador["Force"],orientation="horizontal",bins=30,color="blue")
axs[0].plot(numerador["Force"],label="Accepted  points",linestyle='none',marker='o',markersize=3,color="blue")

axs[1].hist(tot_accepted["Force"],orientation="horizontal",bins=10,color="blue")
axs[0].plot(tot_accepted["Force"],linestyle='none',marker='o',markersize=3,color="blue")
axs[0].legend(loc="lower right",fontsize=15)

#axs[1].plot(mean_,label="Mean",linewidth=4.0,marker='o')
#axs[1].plot(std_lower,label="Mean+Std",linewidth=4.0,marker='o')
#axs[1].plot(std_upper,label="Mean-Std",linewidth=4.0,marker='o')

fig.savefig("selected_forces.png") # Esto guarda la figura como en formato png.

accepted_index=list(tot_accepted.index)

pd.DataFrame(tot_accepted.index).to_csv("selected_points.csv", index=False, header=False,sep=' ')
