import os
from f2py_jit import jit
from config_io_module import read_cnf_atoms

# Compile the relevant modules for hard spheres
f90 = jit(['maths_module.f90', 'mc_hs_module.f90', 'mc_hs_driver.f90'],
          flags='-O3 -ffast-math')

def run_nvt_hs(input_file='./cnf.inp', nsteps=1, dr_max=0.1):
    n, box, r = read_cnf_atoms('./cnf.inp')
    f90.mc_module.r = r.transpose()
    f90.mc_driver.box = box
    f90.mc_driver.dr_max = dr_max
    for step in range(nsteps):
        f90.mc_driver.run(10000)

if __name__ == '__main__':
    import argh
    argh.dispatch_command(run_nvt_hs)