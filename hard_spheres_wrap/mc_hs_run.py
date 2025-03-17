import os
from f2py_jit import jit
from config_io_module import read_cnf_atoms

# Compile the relevant modules for hard spheres
f90 = jit(['maths_module.f90', 'mc_hs_module.f90', 'mc_hs_driver.f90'],
          flags='-O3 -ffast-math')

def run_nvt_hs(input_file='./cnf.inp', nsteps=1, dr_max=0.1, eps_box=0.005):
    n, box, r = read_cnf_atoms(input_file)
    f90.mc_module.r = r.transpose()
    f90.mc_driver.box = box
    f90.mc_driver.dr_max = dr_max
    f90.mc_driver.eps_box = eps_box
    for step in range(nsteps):
        vars = f90.mc_driver.run(10000)

        mean_acc_ratio = vars[0].mean()
        mean_pressure = vars[1].mean()
        print(f'Pressure: {mean_pressure:.6f}')
        print(f'Acceptance ratio: {mean_acc_ratio:.6f}')-
    

    # Write the final configuration to a file
    with open('cnf.out', 'w') as output_file:
        output_file.write(f'   {n:> 12d}\n')
        output_file.write(f'   {box:> 12.8f}\n')
        for i in range(n):
            for j in range(3):
                output_file.write(f'  {f90.mc_module.r[j][i]:> 12.10f}')
            output_file.write('\n')

if __name__ == '__main__':
    import argh
    argh.dispatch_command(run_nvt_hs)