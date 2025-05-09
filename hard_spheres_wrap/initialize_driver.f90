! initialize.f90
! Sets up initial configuration for MD or MC
MODULE init_driver

    !------------------------------------------------------------------------------------------------!
    ! This software was written in 2016/17                                                           !
    ! by Michael P. Allen <m.p.allen@warwick.ac.uk>/<m.p.allen@bristol.ac.uk>                        !
    ! and Dominic J. Tildesley <d.tildesley7@gmail.com> ("the authors"),                             !
    ! to accompany the book "Computer Simulation of Liquids", second edition, 2017 ("the text"),     !
    ! published by Oxford University Press ("the publishers").                                       !
    !                                                                                                !
    ! LICENCE                                                                                        !
    ! Creative Commons CC0 Public Domain Dedication.                                                 !
    ! To the extent possible under law, the authors have dedicated all copyright and related         !
    ! and neighboring rights to this software to the PUBLIC domain worldwide.                        !
    ! This software is distributed without any warranty.                                             !
    ! You should have received a copy of the CC0 Public Domain Dedication along with this software.  !
    ! If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.                               !
    !                                                                                                !
    ! DISCLAIMER                                                                                     !
    ! The authors and publishers make no warranties about the software, and disclaim liability       !
    ! for all uses of the software, to the fullest extent permitted by applicable law.               !
    ! The authors and publishers do not recommend use of this software for any purpose.              !
    ! It is made freely available, solely to clarify points made in the text. When using or citing   !
    ! the software, you should not imply endorsement by the authors or publishers.                   !
    !------------------------------------------------------------------------------------------------!
  
    ! Reads several variables and options from standard input using a namelist nml
    ! Leave namelist empty to accept supplied defaults
  
    USE, INTRINSIC :: iso_fortran_env, ONLY : input_unit, output_unit, error_unit, iostat_end, iostat_eor, &
         &                                    COMPILER_VERSION, COMPILER_OPTIONS
    
    USE config_io_module,  ONLY : write_cnf_atoms, write_cnf_mols
    USE maths_module,      ONLY : lowercase
    USE initialize_module, ONLY : allocate_arrays, deallocate_arrays, &
         &                        fcc_positions, ran_positions, ran_velocities, &
         &                        chain_positions, chain_velocities, &
         &                        n, r, e, v, w
  
    IMPLICIT NONE 

    INTEGER            :: molecule_option ! User option for atoms, linear, or nonlinear molecule, or chain
    INTEGER, PARAMETER :: atom = 0, linear = 1, nonlinear = 2, chain = 3
    
    REAL, PARAMETER :: tol = 1.0e-6
      
CONTAINS

  SUBROUTINE init(nc, temperature, inertia, density, velocities, & 
                  lattice, length, bond, molecules, soft, constraints, &
                  filename)
    INTEGER, INTENT(in)          :: nc
    REAL, INTENT(in)             :: temperature, density, bond
    LOGICAL, INTENT(in)          :: velocities, lattice, soft, constraints
    CHARACTER(len=*), INTENT(in) :: filename
    REAL                         :: box, inertia, length
    CHARACTER(len=10)            :: molecules

    WRITE ( unit=output_unit, fmt='(a)'   ) 'initialize'
    WRITE ( unit=output_unit, fmt='(2a)'  ) 'Compiler: ', COMPILER_VERSION()
    WRITE ( unit=output_unit, fmt='(2a/)' ) 'Options:  ', COMPILER_OPTIONS()
    
    WRITE ( unit=output_unit, fmt='(a)' ) 'Sets up initial configuration file for various simulations'
    WRITE ( unit=output_unit, fmt='(a)' ) 'Options for molecules are "atom", "linear", "nonlinear", "chain"'
    WRITE ( unit=output_unit, fmt='(a)' ) 'Particle mass m=1 throughout'
  
    CALL RANDOM_INIT ( .FALSE., .TRUE. ) ! Initialize random number generator
  
    ! Use molecules string to deduce molecule_option
    molecules = lowercase(molecules)
  
    IF ( INDEX ( molecules, 'nonlinear' ) /= 0 ) THEN
  
       molecule_option = nonlinear
       WRITE ( unit=output_unit, fmt='(a)' ) 'Nonlinear molecules'
  
    ELSE IF ( INDEX ( molecules, 'linear') /= 0 ) THEN
  
       molecule_option = linear
       WRITE ( unit=output_unit, fmt='(a)' ) 'Linear molecules'
  
    ELSE IF ( INDEX ( molecules, 'atom') /= 0 ) THEN
  
       molecule_option = atom
       WRITE ( unit=output_unit, fmt='(a)' ) 'Atoms'
  
    ELSE IF ( INDEX ( molecules, 'chain') /= 0 ) THEN
  
       molecule_option = chain
       WRITE ( unit=output_unit, fmt='(a)' ) 'Atoms in a chain'
  
    ELSE
  
       WRITE ( unit=error_unit, fmt='(a,a)') 'Unrecognized molecules option: ', molecules
       STOP 'Error in initialize'
  
    END IF
  
    IF ( n <= 0 ) THEN ! Test for unspecified N
  
       IF ( nc <= 0 ) THEN ! Test for unphysical nc
  
          WRITE ( unit=error_unit, fmt='(a,2i15)') 'nc must be positive', nc
          STOP 'Error in initialize'
  
       ELSE ! Deduce N from nc
  
          WRITE ( unit=output_unit, fmt='(a,t40,i15)') 'nc = ', nc
          n = 4*nc**3
          WRITE ( unit=output_unit, fmt='(a,t40,i15)') 'n = ', n
  
       END IF
  
    ELSE ! N has been specified
  
       WRITE ( unit=output_unit, fmt='(a,t40,i15)') 'n = ', n
  
    END IF ! End test for unspecified N
  
    IF ( velocities ) THEN
       WRITE ( unit=output_unit, fmt='(a)' ) 'Velocities option selected'
  
       ! Inertia should be positive, even for atoms
       IF ( inertia < tol ) THEN
          WRITE ( unit=output_unit, fmt='(a,f15.6)' ) 'Warning, inertia = ', inertia
          WRITE ( unit=output_unit, fmt='(a)' ) 'Resetting to 1 '
          inertia = 1.0
       END IF
  
    ELSE
       WRITE ( unit=output_unit, fmt='(a)' ) 'No velocities option selected'
    END IF
  
    SELECT CASE ( molecule_option )
  
    CASE ( nonlinear )
       WRITE ( unit=output_unit, fmt='(a)' ) 'Periodic boundary conditions'
  
    CASE ( linear )
  
       WRITE ( unit=output_unit, fmt='(a)' ) 'Periodic boundary conditions'
  
       IF ( length < tol ) THEN
          WRITE ( unit=output_unit, fmt='(a,f15.6)' ) 'Warning, length = ', length
       END IF
  
    CASE ( atom )
  
       WRITE ( unit=output_unit, fmt='(a)' ) 'Periodic boundary conditions'
       IF ( ABS(length) > tol ) THEN
          WRITE ( unit=output_unit, fmt='(a,f15.6)' ) 'Warning, length = ', length
          WRITE ( unit=output_unit, fmt='(a)' ) 'Resetting to zero'
          length = 0.0
       END IF
  
    CASE ( chain )
  
       WRITE ( unit=output_unit, fmt='(a)' ) 'NO periodic boundary conditions'
       IF ( ABS(length) > tol ) THEN
          WRITE ( unit=output_unit, fmt='(a,f15.6)' ) 'Warning, length = ', length
          WRITE ( unit=output_unit, fmt='(a)' ) 'Resetting to zero'
          length = 0.0
       END IF
       IF ( velocities ) THEN
          IF ( constraints ) THEN
             WRITE ( unit=output_unit, fmt='(a)' ) 'Velocities constrained relative to bonds'
          ELSE
             WRITE ( unit=output_unit, fmt='(a)' ) 'Velocities not constrained relative to bonds'
          END IF
       END IF
  
    END SELECT
  
    ! Allocate arrays appropriately according to molecule_option
    CALL allocate_arrays ( quaternions = ( molecule_option == nonlinear ) )
  
    ! Initialize positions and optionally velocities
  
    IF ( soft ) WRITE ( unit=output_unit, fmt='(a)' ) 'Soft option selected - no overlap checking'
  
    IF ( molecule_option == chain ) THEN
  
       WRITE ( unit=output_unit, fmt='(a,t40,f15.6)' ) 'Bond length', bond
       CALL chain_positions ( bond, soft ) ! Random with chosen bond length
       IF ( velocities ) CALL chain_velocities ( temperature, constraints )
  
    ELSE
  
       ! Periodic boundaries apply
       ! Box length is deduced from density
       box = ( REAL(n) / density ) ** ( 1.0/3.0 )
       WRITE ( unit=output_unit, fmt='(a,t40,f15.6)' ) 'Density',    density
       WRITE ( unit=output_unit, fmt='(a,t40,f15.6)' ) 'Box length', box
  
       IF ( lattice ) THEN
          CALL fcc_positions ( box, length, soft ) ! On a lattice within box
       ELSE
          CALL ran_positions ( box, length, soft ) ! Random within box
       END IF
  
       IF ( velocities ) CALL ran_velocities ( temperature, inertia )
  
    END IF
  
    ! Write out configuration
  
    WRITE ( unit=output_unit, fmt='(a,a)' ) 'Writing configuration to filename ', filename
  
    SELECT CASE ( molecule_option )
  
    CASE ( atom )
  
       ! Write out coordinates in same units as box
       IF ( velocities ) THEN
          CALL write_cnf_atoms ( filename, n, box, r, v )
       ELSE
          CALL write_cnf_atoms ( filename, n, box, r )
       END IF
  
    CASE ( linear, nonlinear )
  
       ! Write out coordinates in same units as box
       IF ( velocities ) THEN
          CALL write_cnf_mols ( filename, n, box, r, e, v, w )
       ELSE
          CALL write_cnf_mols ( filename, n, box, r, e )
       END IF
  
    CASE ( chain )
  
       ! We do not use periodic boundaries for this system
       ! Instead, use "box" variable to store bond length
       IF ( velocities ) THEN
          CALL write_cnf_atoms ( filename, n, bond, r, v )
       ELSE
          CALL write_cnf_atoms ( filename, n, bond, r )
       END IF
  
    END SELECT
  
    CALL deallocate_arrays
  
  END SUBROUTINE init

END MODULE init_driver
  