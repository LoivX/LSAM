import os
from f2py_jit import jit
from config_io_module import read_cnf_atoms

# Compile the relevant modules for hard spheres
f90 = jit(['maths_module.f90', 'mc_hs_module.f90', 'mc_hs_driver.f90'],
          flags='-O3 -ffast-math')

# Read the input file, this will allocate the arrays too
n, box, r = read_cnf_atoms('./cnf.inp')

# Set the positions in mc_module
f90.mc_module.n = n
f90.mc_module.r = r.transpose()
# Set the remaining parameters in mc_driver
f90.mc_driver.box = box
f90.mc_driver.dr_max = 0.1

# Make nsteps MC steps (each one comprises N attempted moves)
nsteps = 10
for step in range(nsteps):
    f90.mc_driver.run(1000)