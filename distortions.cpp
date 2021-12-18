#include"atomicpp.h"

Cluster current, initial;
int N_step, geom, indx, a;
double dif,acumulado;
string command, current_file, num;

int main(int argc, char **argv)
{
   initial.read_fhi("initial_configuration.fhi");
   initial.print_xyz("movie.xyz");
   N_step=int_pipe("ls positions_*.fhi | wc -l ");//comando numero de configuraciones bash
   for(geom=2;geom<=N_step;geom++)
   {
      num=to_string(geom);
      current_file="positions_"+num;
      current_file+=".fhi"; //g definir el nombre
      current.read_fhi(current_file);
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
      current.print_xyz("temp");
      system("cat temp >> movie.xyz");
   }
   return 0;
}
