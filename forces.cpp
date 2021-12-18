#include"atomicpp.h"
//Probando
Cluster current, initial;
int N_step, geom, indx, a;
double dif,acumulado;
string command, current_file, num;

int main(int argc, char **argv)
{
   system("awk '{print \" atom \" $3 \" \" $4 \" \" $5 \" F \" }' forces_1.fhi > forces.dat");
   initial.read_fhi("forces.dat");
   N_step=int_pipe("ls positions_*.fhi | wc -l ");//comando numero de configuraciones bash
   for(geom=2;geom<=N_step;geom++)
   {
      num=to_string(geom);
      current_file="forces_"+num;
      current_file+=".fhi"; //g definir el nombre
      ///////////////
      command ="awk '{print \" atom \" $3 \" \" $4 \" \" $5 \" F \" }' forces_";
      command+=num;
      command+=".fhi > forces.dat";
      system(command.c_str());
      current.read_fhi("forces.dat");
      // Diferencia entre la inicial y la actual
      acumulado=0;
      for(a=1;a<=initial.Nat;a++)
      {
         dif=0;
         for(indx=0;indx<3;indx++)
         {
            dif=dif+pow( (initial.atom[a].x[indx]-current.atom[a].x[indx] ), 2 );
         }
         dif=sqrt(dif); // En este punto dif es la norma del vector diferencia
         acumulado=acumulado+dif;
      }
      acumulado=acumulado/initial.Nat; // Este es el desplazamiento promedio
      cout<<geom<<","<<acumulado<<endl;
   }
   return 0;
}
