MODULE mc_driver
  
  USE, INTRINSIC :: iso_fortran_env, ONLY : input_unit, output_unit, error_unit, iostat_end, iostat_eor, &
       &                                    COMPILER_VERSION, COMPILER_OPTIONS
  
  USE maths_module, ONLY : random_translate_vector
  USE mc_module, ONLY: overlap_1, overlap, n_overlap, r


  IMPLICIT NONE

  REAL :: box         ! Box length
  REAL :: dr_max      ! Maximum MC displacement
  REAL :: eps_box     ! Pressure scaling parameter

CONTAINS

  SUBROUTINE run(nsteps, vars)
    INTEGER, INTENT(in) :: nsteps
    INTEGER :: i, stp, moves
    REAL :: ri(3), vir, rho, acc_ratio, p_f
    REAL, INTENT(out) :: vars(2, nsteps)
    ! This may be done once at the beginning
    ! Convert positions to box units and PBC
    r(:,:) = r(:,:) / box
    r(:,:) = r(:,:) - ANINT(r(:,:))

    ! Initial pressure calculation and overlap check
  IF ( overlap ( box ) ) THEN
    WRITE ( unit=error_unit, fmt='(a)') 'Overlap in initial configuration'
    STOP 'Error in mc_nvt_hs'
  END IF

  ! Do nsteps MC steps
  DO stp = 1, nsteps
    moves = 0

     DO i = 1, SIZE(r, 2)
        ri(:) = random_translate_vector(dr_max/box, r(:,i))
        ri(:) = ri(:) - ANINT(ri(:))
        IF (.NOT. overlap_1(ri, i, box)) THEN
           r(:,i) = ri(:)
           moves  = moves + 1
        END IF
     END DO

     acc_ratio = REAL(moves) / (SIZE(r, 2))

     vir = REAL ( n_overlap ( box/(1.0+eps_box) ) ) / (3.0*eps_box) ! Virial
     rho = REAL(SIZE(r, 2)) / box**3  
     p_f = rho + vir/box**3 

     vars(1, stp) = acc_ratio
     vars(2, stp) = p_f
  END DO
  

  ! Convert positions back to natural units
  r(:,:) = r(:,:) * box
  
END SUBROUTINE run

END MODULE mc_driver