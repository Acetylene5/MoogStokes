
      subroutine synspec
c******************************************************************************
c     This routine does synthetic spectra                                
c******************************************************************************

      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'
      include 'Factor.com'
      include 'Pstuff.com'
      include 'Dummy.com'
      real*8 dd(5000)
c      real*8 Stokes(5)
      real*8 NOK, NBAD, H_MIN, H_GUESS, EPS, B
      real*8 factor, right
      PARAMETER (NDGL=5,NRD=0)
      PARAMETER (LWORK=11*NDGL+8*NRD+21, LIWORK=NRD+21)
      DIMENSION STOKES(NDGL),WORK(LWORK),IWORK(LIWORK)
c      real*8 work(76), iwork(21)
c      integer ipar(1), lwork, liwork
c      real*8 rpar(1)
      integer counter
      logical direction, prev_step
      EXTERNAL derivs, SOLOUT

      NEQS = 5
      RPAR=0.0
      counter = 0

c*****initialize the synthesis
      direction = .TRUE.
      prev_step = .FALSE.
      write (nf1out,1101)
      write (nf2out,1002) moditle(1:73)
      if (iunits .eq. 1) then
         write (nf2out,1103) oldstart,oldstop,oldstep,olddelta
      else
         write (nf2out,1102) start,sstop,step,delta
      endif
      if (iraf .eq. 1) then
         npoint = (sstop-start)/step
         write (nf4out,1104) npoint,wave,wave,step,step
         write (nf4out,1105)
         write (nf4out,1106) moditle
         do j=1,93
            if (pec(j) .gt. 0 ) then
               dummy1(j) = dlog10(xabund(j)) + 12.0
               write (nf4out,1107) names(j),dummy1(j)
            endif
         enddo
         write (nf4out,1108) vturb(1)
         write (nf4out,1109)
      endif
      n = 1           
      num = 0
      nsteps = 1
      lim1line = 0


c*****calculate continuum quantities at the spectrum wavelength
      wave = start
      left = wave
      right = wave
      wavl = 0.
      open(unit=nf11out, file=f11out)
30    if (dabs(wave-wavl)/wave .ge. 0.001) then
         wavl = wave   
         call opacit (2,wave)    
      endif


c*****find the appropriate set of lines for this wavelength, reading 
c     in a new set if needed
      if (mode .eq. 3) then
20       call linlimit
         if (lim2line .lt. 0) then
            call inlines (2)
            call nearly (1)
            go to 20
         endif
         lim1 = lim1line
         lim2 = lim2line
      endif


c*****compute a spectrum depth at this point
      call taukap
      call Planck(t(ntau), B)
      Stokes(1) = B
      Stokes(2) = 0.0
      Stokes(3) = 0.0
      Stokes(4) = 0.0
      Stokes(5) = B
      H_guess = 0.0001
      H_min = 1.0e-2
      EPS = 0.01
      NOK = 0
      NBAD = 0
      TOL = 1.0D-5
      ITOL = 0
      RTOL = TOL
      ATOL = 0
      IOUT = 0
c      write (*,*) Stokes(1), B
c      call rkdumb(Stokes,4,log10(tauref(ntau)*kaplam(ntau)/(kapref(ntau)
c     .         *mu)), log10(tauref(1)*kaplam(1)/(kapref(1)*mu)),700)
c      call odeint(Stokes,5,log10(tauref(ntau)*kaplam(ntau)/
c     .     (kapref(ntau)*MU)),log10(tauref(1)*kaplam(1)/(
c     .     kapref(1)*MU)),
c     .     EPS, H_GUESS, H_MIN, NOK, NBAD)
c      call DOP853(NDGL, derivs,
c     .      log10(tauref(ntau)*kaplam(ntau)/(kapref(ntau)*mu)), Stokes,
c     .      log10(tauref(1)*kaplam(1)/(kapref(1)*mu)), RTOL, ATOL, ITOL,
c     .      junk, IOUT, work, lwork, iwork, liwork, rpar, ipar, IDID)
      do 21 i=1,LWORK
21        work(i)=0.0
      do 23 i=1,LIWORK
23        iwork(i)=0.0
c      work(7) = -0.1
      call DOP853(NDGL, derivs,
     .      log10(tauref(ntau)*kaplam(ntau)/(kapref(ntau)*mu)), Stokes,
     .      log10(tauref(1)*kaplam(1)/(kapref(1)*mu)), RTOL, ATOL, ITOL,
     .      junk, IOUT, work, lwork, iwork, liwork, rpar, ipar, IDID)
c      write (*,*) "Checkpoint F"
      write (*,*) iwork(17),iwork(18),iwork(19),iwork(20)
      d(n) = 1.0-Stokes(1)/Stokes(5)
      if (idid .ne. 1) then
         write (*,*) wave, 1.0-d(n),idid, counter
         write (*,*) iwork(17),iwork(18),iwork(19),iwork(20)
         write (*,*) log10(tauref(ntau)*kaplam(ntau)/(kapref(ntau)*mu))
         write (*,*) log10(tauref(1)*kaplam(1)/(kapref(1)*mu))
c         open(nf3out)
c         call dump_taus(d(n))
         read (*,*) 
         do 24 i=1,LWORK
24          work(i)=0.0
         do 25 i=1,LIWORK
25          iwork(i)=0.0
c         work(7) = -0.1
c         work(5) = 0.05
         Stokes(1) = B
         Stokes(2) = 0.0
         Stokes(3) = 0.0
         Stokes(4) = 0.0
         Stokes(5) = B
         IOUT = 1
         call DOP853(NDGL, derivs,
     .      log10(tauref(ntau)*kaplam(ntau)/(kapref(ntau)*mu)), Stokes,
     .      log10(tauref(1)*kaplam(1)/(kapref(1)*mu)), RTOL, ATOL, ITOL,
     .      Solout, IOUT, work, lwork, iwork, liwork, rpar, ipar, IDID)
         IOUT = 0
         write (*,*) Stokes(1)/Stokes(5)
         write (*,*) wave, idid, counter
         write (*,*) iwork(17),iwork(18),iwork(19),iwork(20), n, num
         read (*,*) 
      endif
      counter = counter +1
c      read (*,*)
      write (nf11out,12345) wave,1.0-d(n),Stokes
      if (1.0-d(n) .gt. 2.0) then
         write (*,*) 'I am less than intelligent'
         read (*,*)
      endif
c      write (*,*) wave,1.0-d(n), Stokes(1), Stokes(2), Stokes(3),
c     .              Stokes(4), Stokes(5), NOK, NBAD
c      write (*,*) wave,1.0-d(n), NOK, NBAD
c      read (*,*)
      if (mod(n,10) .eq. 0) then
         if (iraf .eq. 1) then
            do j=1,10
               dd(num+j) = 1. - d(num+j)
            enddo
            write (nf4out,1110) (dd(num+j),j=1,10)
         endif
         if (iunits .eq. 1) then
            wave3 = 1.d-4*(wave - 9.0*step)
            write (nf1out,1112) wave3,(d(num+j),j=1,10)
         else
            wave3 = wave - 9.0*step
            write (nf1out,1111) wave3,(d(num+j),j=1,10)
         endif
         if (nf2out .gt. 0) write (nf2out,1110) (d(num+j),j=1,10)
         num = num + 10
      endif


c*****step in wavelength and try again 
      if (d(n).gt.0.05) then
          stepsize = dopp(nstrong,50)*wave/2.997929e10
c            First step into a region with a line.  Need to reverse direction
          if (.not.prev_step) THEN
              direction = .FALSE.
              prev_step = .TRUE.
              right = wave
          ENDIF
          if (direction) THEN
              factor = 1.0
          else
              factor = -1.0
          endif
c          write (*,*) "line!  - ", d(n), wave, wave*dopp(nstrong,20)
c     .           /2.997929e10
          wave = wave + factor*stepsize
      else
          stepsize = dopp(nstrong, 50)*wave/2.997929e9
          prev_step = .FALSE.
          if (.not.direction) THEN
              direction = .TRUE.
              prev_step = .TRUE.
              stepsize = stepsize/10.0
              wave = right
          ENDIF
c          write (*,*) "continuum! - ", d(n), wave, wave*dopp(nstrong,20)
c     .           /2.997929e10
          wave = wave + stepsize
      endif
c      wave = oldstart + step*nsteps
      if (wave .le. sstop) then
         n = n + 1        
         nsteps = nsteps + 1
         if (n .gt. 5000) then
            n = 1                                      
            num = 0
         endif
         go to 30                   


c*****finish the synthesis
      else
         nn = mod(n,10)
         if (nn .ne. 0) then
            if (iraf .eq. 1) then
               do j=1,nn
                  dd(num+j) = 1. - d(num+j)
               enddo
               write (nf4out,1110) (dd(num+j),j=1,nn)
            endif
            if (iunits .eq. 1) then
               wave3 = 1.d-4*(wave - 9.0*step)
               write (nf1out,1112) wave3,(d(num+j),j=1,nn)
            else
               wave3 = wave - 9.0*step
               write (nf1out,1111) wave3,(d(num+j),j=1,nn)
            endif
            if (nf2out .gt. 0) write (nf2out,1110) (d(num+j),j=1,nn)
         endif
         if (iunits .eq. 1) then
            write (nf1out,1113) 1.d-4*wave
         else
            write (nf1out,1114) wave
         endif
         close(nf11out)
         return 
      endif


c*****format statements
1001  format ('  kaplam from 1 to ntau at wavelength',f10.2/
     .        (6(1pd12.4)))
1002  format ('MODEL: ',a73)
1003  format ('AT WAVELENGTH/FREQUENCY =',f11.7,
     .        '  CONTINUUM FLUX/INTENSITY =',1p,d12.5)
1004  format ('AT WAVELENGTH/FREQUENCY =',f11.3,
     .        '  CONTINUUM FLUX/INTENSITY =',1p,d12.5)
1101  format (/'SPECTRUM DEPTHS')
1102  format (4f11.3)
1103  format (4f10.7)
1104  format ('SIMPLE  =    t'/'NAXIS   =     1'/'NAXIS1  = ',i10,/
     .        'W0      =',f10.4/'CRVAL1  =',f10.4/'WPC     =',f10.4/
     .        'CDELT1  =',f10.4)
1105  format (16HORIGIN  = 'moog'/21HDATA-TYP= 'synthetic'/
     .        18HCTYPE1  = 'lambda'/21HCUNIT1  = 'angstroms')
1106  format (11HTITLE   = ',A65,1H')
1107  format ('ATOM    = ',1H',7x,a2,1H',/,'ABUND   = ',f10.2)
1108  format ('VTURB   = ',d10.4,'     /  cm/sec  ')
1109  format ('END')
1110  format (10f7.4)
1111  format (f10.3,': depths=',10f6.3)
1112  format (f10.7,': depths=',10f6.3)
1113  format ('FINAL WAVELENGTH/FREQUENCY =',f10.7/)
1114  format ('FINAL WAVELENGTH/FREQUENCY =',f10.3/)
12345 format (f10.4,f10.7,5e10.3)

      end                                


      subroutine Planck(temperature, B)
      
      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'
      include 'Factor.com'
      include 'Pstuff.com'
      include 'Dummy.com'
      B = ((1.19089d+25/wave**2)*1.0d+10)/(wave**3*
     .      (dexp(1.43879d+08/(wave*temperature))-1.0d+00))
      end

      subroutine Solout(NR,XOLD,X,Y,N,CON,ICOMP,ND,RPAR,IPAR,IRTRN,XOUT)
      DIMENSION Y(N),CON(8*ND),ICOMP(ND)
      write (*,*) NR, XOLD, X, N
      read (*,*)
      end 


      subroutine dump_taus(value)

      implicit real*8 (a-h,o-z)
      include 'Atmos.com'
      include 'Linex.com'
      include 'Factor.com'
      include 'Pstuff.com'
      include 'Dummy.com'

      do 56 i=1, ntau
56      write (nf3out,321) tauref(i), eta_I(i),eta_Q(i),eta_V(i),
     .        zet_Q(i),zet_V(i)
      close(nf3out)

321   format (f11.3, 5e11.3)
      end
