MODULE mc_driver

  USE maths_module, ONLY : random_translate_vector
  USE mc_module, ONLY: overlap_1, r

  IMPLICIT NONE

  REAL :: box         ! Box length
  REAL :: dr_max      ! Maximum MC displacement

CONTAINS

  SUBROUTINE run(nsteps)
    INTEGER, INTENT(in) :: nsteps
    INTEGER :: i, step, moves
    REAL :: ri(3), acc_ratio
    ! This may be done once at the beginning
    ! Convert positions to box units and PBC
    r(:,:) = r(:,:) / box
    r(:,:) = r(:,:) - ANINT(r(:,:))
    ! Do nsteps MC steps
    moves = 0
    DO step = 1, nsteps
       DO i = 1, SIZE(r, 2)
          ri(:) = random_translate_vector(dr_max/box, r(:,i))
          ri(:) = ri(:) - ANINT(ri(:))
          IF (.NOT. overlap_1(ri, i, box)) THEN
             r(:,i) = ri(:)
             moves  = moves + 1
          END IF
       END DO
    END DO
    acc_ratio = REAL(moves) / (nsteps * SIZE(r, 2))
    ! Convert positions back to natural units
    r(:,:) = r(:,:) * box
  END SUBROUTINE run

END MODULE mc_driver