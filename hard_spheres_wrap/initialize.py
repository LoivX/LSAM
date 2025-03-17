import os
from f2py_jit import jit
import config_io_module

# Compile the relevant modules
f90 = jit(['config_io_module.f90', 'maths_module.f90', 'initialize_module.f90', 'initialize_driver.f90'],
          flags='-O3 -ffast-math')

def initialize_hs(nc=4, 
                  temperature=1.0,
                  inertia=1.0,
                  density=0.75,
                  velocities= False, 
                  lattice= True, 
                  length=0.0, 
                  bond=1.122462, 
                  molecules='atoms', 
                  soft= False, 
                  constraints= True, 
                  filename='cnf.inp'):
    
    f90.init_driver.init(nc, temperature, inertia, density, velocities, lattice, length, bond, molecules, soft, constraints, filename)


if __name__ == '__main__':
    import argh
    argh.dispatch_command(initialize_hs)