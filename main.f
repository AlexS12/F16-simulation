      module var
        type :: ptr
          real(8),pointer ::p
        end type
        real(8),dimension(4) ::linearX,DeltaX,ModelX
        real(8),dimension(2) ::linearU,DeltaU
      end
      
      program main
      use var
      implicit none
      integer NN,MM
      PARAMETER (NN=20, MM=10)
      integer::NV,NX,Nstep,i,j,selection
      real(8)::COST,FDX,FDU,YDX,YDU
      real(8)::X(NN),U(MM),XD(NN),m2ft,lbf2N,RTOD,XCG
      real(8)::XD1(NN),XD2(NN)
      target::X,U
      real(8)::DT,TT,totalt
      real(8)::RADGAM,SINGAM,RR,PR,TR,PHI,CPHI,SPHI
      LOGICAL::COORD=.false., STAB=.false.
      real(8)::AN,ALAT,AX,QBAR,AMACH,Q,ALPHA,T
      real(8)::status(20,2)
      logical::Ltrim=.true.
      real(8)::V(NN),ABC(NN*NN),AAA(8,8),BBB(8,4)
      real(8)::Alongitudinal(4,4),Alateral(4,4)
      real(8)::Blongitudinal(4,2),Blateral(4,2)
      integer::NR,NC
      integer::IO(NN),JO(NN)

      COMMON/STATE/ X
      COMMON/DSTATE/ XD
      COMMON/CONTROLS/ U
      COMMON/logicalvar/Ltrim
      COMMON/PARAM/XCG
      COMMON/OUTPUT/AN,ALAT,AX,QBAR,AMACH,Q,ALPHA,T
      COMMON/CONSTRNT/RADGAM,SINGAM,RR,PR,TR,PHI,CPHI,SPHI,COORD,STAB
      EXTERNAL COST,F,FDX,FDU,YDX,YDU,F1
!                       1   2     3    4   5   6  7 8 9 10       11       12     
!    X = STATE VECTOR - VT,ALPHA,BETA,PHI,THE,PSI,P,Q,R,XN(north),XE(east),H.
!                        
C    U = INPUT VECTOR - THTL,EL,AIL,RDR.      

      m2ft=3.28084d0
      lbf2N=4.44822d0
      RTOD=180.d0/acos(-1.d0)
      XCG=0.35d0
      NV=3
      U(1:4)=(/0.2,-0.09,0.01,-0.01/) !initial guess


      !��ֱƽ��Լ��
      RR=0.d0; PR=0.d0; TR=0.d0; PHI=0.d0

      call writetitle
      write(*,*) '------------------------trim-------------------------'
      !do while(.true.)
      write(*,*) 'Input Velocity(m/s),Height(m):'
      !read(*,*)  X(1),X(12)
      X(1)=130.d0; X(12)=1000.d0
      !X(1)=502.d0; X(12)=0.d0
      call TRIMMER (NV, COST)
      call printXU
      write(*,*)'����T=',T,'N'
      !enddo


      write(*,*) '----------Numerical Linearization----------------'
      X(13)=X(1)*COS(X(2))*COS(X(3))
      X(14)=X(1)          *SIN(X(3))
      X(15)=X(1)*SIN(X(2))*COS(X(3))

      call calAB(X,XD,U,Alongitudinal,Blongitudinal,
     &                Alateral,Blateral )
      write(*,*) '����'
      write(*,*) 'X=[u, w, q, ��]'
      write(*,*) 'longitudinal A='
      write(*,'(5x,4f16.9)') transpose(Alongitudinal)
      write(*,*) '����'
      write(*,*) 'X=[v, p, r, ��]'
      write(*,*) 'lateral A='
      write(*,'(5x,4f16.9)') transpose(Alateral)

      write(*,*) 'X=[u, w, q, ��] U=[THTL,EL]'
      write(*,*) '����longitudinal B='
      write(*,'(5x,2f16.9)') TRANSPOSE(Blongitudinal)
      write(*,*) 'X=[v, p, r, ��] U=[AIL,RDR]'
      write(*,*) '����lateral B='
      write(*,'(5x,2f16.9)') TRANSPOSE(Blateral)
      !call printXU
      
      
      write(*,*) '----------Dynamic Responce----------------------'
      selection=1 !����С�Ŷ�����
      selection=2 !ȫ������
333   continue
      write(*,*) '1:����С�Ŷ�����ʱ����Ӧ'
      write(*,*) '2:ȫ������ʱ����Ӧ'
      write(*,*) '3:����ģ̬������Ӧ'
      write(*,*) '4:����ģ̬������Ӧ'
      write(*,*) '��ѡ��:'
      selection=1
      read(*,*)  selection
      if(selection==1) then
        goto 1
      elseif(selection==2) then
        goto 2
      elseif(selection==3) then
        goto 3
      elseif(selection==4) then
        goto 4
      else
      write(*,*) '��������'
      goto 333
      endif
      
1     continue
      write(*,*) '----------��������С�Ŷ�����---------------------'
      selection=2
      write(*,*) 
      write(*,*) '2:�����浥λ��Ծ����״̬������ʱ����Ӧ'
      write(*,*) '3:����λ��Ծ����״̬������ʱ����Ӧ'
      write(*,*) '��ѡ��:'
      read(*,*)  selection
      !totalt=10.d0
      write(*,*) 'Input Total Simulation time:'
      read(*,*)  totalt
      write(*,*) '����ʱ������Ϊ',totalt,'s'
      write(*,*) '����ʱ��������ܻ����״̬����������ֵ��Χ'
      TT=0.d0         
      DT=0.001d0 
      Nstep=int(totalt/DT)   

      select case (selection)
      case(2)

        write(*,*)'��ʼ���������浥λ��Ծ����״̬������ʱ����Ӧ'
!        1  2     3    4   5   6   7 8 9 10        11       12 13 14 15    
!    X = VT,ALPHA,BETA,PHI,THE,PSI,p,q,r,XN(north),XE(east),H. u, v, w
!         1   2   3   4
!    U = THTL,EL,AIL,RDR.      

        DeltaX(1)=0.d0
        DeltaX(2)=0.d0
        DeltaX(3)=0.d0
        DeltaX(4)=0.d0
        DeltaU(1)=0.d0
        DeltaU(2)=1.d0
        open(20,file='./elevator_1input_linearEq.dat')
        write(20,'(A60)')
     &  'variables=time(s),u(m/s),w(m/s),q(rad/s),THE(rad)'
        write(20,*)'ZONE T="linear"'
        do i=1,Nstep
            CALL linearF(XD1,Alongitudinal,Blongitudinal)
            do j=1,4
              DeltaX(j)=DeltaX(j)+XD1(j)*DT
            enddo
            TT=TT+DT
            linearX(1)=X(13)+DeltaX(1)
            linearX(2)=X(15)+DeltaX(2)
            linearX(3)=X(8)+DeltaX(3)
            linearX(4)=X(5)+DeltaX(4)
            linearU(1)=U(1)+DeltaU(1)
            linearU(2)=U(2)+DeltaU(2)
            write(20,'(1x,5g15.7)')TT,linearX(1:4)
          enddo
          close(20)
        case(3)
          write(*,*)'��ʼ���㸱��λ��Ծ����״̬������ʱ����Ӧ'
!        1  2     3    4   5   6   7 8 9 10        11       12 13 14 15    
!    X = VT,ALPHA,BETA,PHI,THE,PSI,p,q,r,XN(north),XE(east),H. u, v, w
!         1   2   3   4
!    U = THTL,EL,AIL,RDR.      

          DeltaX(1)=0.d0
          DeltaX(2)=0.d0
          DeltaX(3)=0.d0
          DeltaX(4)=0.d0
          DeltaU(1)=1.d0
          DeltaU(2)=0.d0
          open(20,file='./ailerons_1input_linearEq.dat')
          write(20,'(A60)')
     &    'variables=time(s),v(m/s),p(rad/s),r(rad/s),PHI(rad)'
          write(20,*)'ZONE T="linear"'
          do i=1,Nstep
              CALL linearF(XD1,Alateral,Blateral)
              do j=1,4
                DeltaX(j)=DeltaX(j)+XD1(j)*DT
              enddo
              TT=TT+DT
              linearX(1)=X(14)+DeltaX(1)
              linearX(2)=X(7)+DeltaX(2)
              linearX(3)=X(9)+DeltaX(3)
              linearX(4)=X(4)+DeltaX(4)
              write(20,'(1x,5g15.7)')TT,linearX(1:4)
            enddo
            close(20)
          end select
        
      write(*,*) '�������������������ļ���ͼ'
      write(*,*) '�����������'
      read(*,*)
      stop      
      
      
2     continue
      write(*,*) '----------����ȫ���˶�����-----------------------'
      selection=2
      write(*,*) 
      write(*,*) '1:��������״̬������ʱ����Ӧ'
      write(*,*) '2:�����浥λ��Ծ����״̬������ʱ����Ӧ'
      write(*,*) '3:����λ��Ծ����״̬������ʱ����Ӧ'
      write(*,*) '��ѡ��:'
      read(*,*)  selection
      !totalt=10.d0
      write(*,*) 'Input Total Simulation time:'
      read(*,*)  totalt
      write(*,*) '����ʱ������Ϊ',totalt,'s'
      write(*,*) '����ʱ��������ܻ����״̬����������ֵ��Χ'
      DT=0.001d0 
      Nstep=int(totalt/DT)   

      select case (selection)
      case (1)
        write(*,*)'��ʼ������������״̬������ʱ����Ӧ'
        TT=0.d0           
        NX=12           
        open(10,file='./zero_input.dat')
        write(10,'(A120)')'variables=time(s),u(m/s),v(m/s),w(m/s),
     &PHI(rad),THE(rad),PSI(rad),p(rad/s),q(rad/s),r(rad/s),
     &xE(m),yE(m),H(m)'
        write(10,*)'ZONE T="non-linear"'
        do i=1,Nstep
          call RK4(F,DT,X,NX)
          TT=TT+DT
          write(10,'(1x,13g15.7)')TT,X(1)*cos(X(2))*cos(X(3)),
     &       X(1)*sin(X(3)),X(1)*sin(X(2))*cos(X(3)),
     &       X(4:9),X(10:12)
        enddo
        close(10)

      case (2)
        write(*,*)'��ʼ���������浥λ��Ծ����״̬������ʱ����Ӧ'
        U(2)=U(2)+1.d0
        TT=0.d0         
        NX=12           
        open(20,file='./elevator_1input.dat')
        write(20,'(A120)')'variables=time(s),u(m/s),v(m/s),w(m/s),
     &  PHI(rad),THE(rad),PSI(rad),p(rad/s),q(rad/s),r(rad/s),
     &  xE(m),yE(m),H(m)'
        write(20,*)'ZONE T="non-linear"'
        do i=1,Nstep
          !X(3)=0.0         
          call RK4(F,DT,X,NX)
          TT=TT+DT
          write(20,'(1x,13g15.7)')TT,X(1)*cos(X(2))*cos(X(3)),
     &       X(1)*sin(X(3)),X(1)*sin(X(2))*cos(X(3)),
     &       X(4:9),X(10:12)
        enddo
        close(20)
      case (3)
        write(*,*)'��ʼ���㸱��λ��Ծ������״̬������ʱ����Ӧ'
        U(3)=U(3)+1.d0
        TT=0.d0     
        NX=12   
        open(30,file='./ailerons_1input.dat')
        write(30,'(A120)')'variables=time(s),u(m/s),v(m/s),w(m/s),
     &  PHI(rad),THE(rad),PSI(rad),p(rad/s),q(rad/s),r(rad/s),
     &  xE(m),yE(m),H(m)'
        write(30,*)'ZONE T="non-linear"'
        do i=1,Nstep
          !X(3)=0.0         
          call RK4(F,DT,X,NX)
          TT=TT+DT
          write(30,'(1x,13g15.7)')TT,X(1)*cos(X(2))*cos(X(3)),
     &       X(1)*sin(X(3)),X(1)*sin(X(2))*cos(X(3)),
     &       X(4:9),X(10:12)
        enddo
        close(30)
      end select

      write(*,*) '�������������������ļ���ͼ'
      write(*,*) '�����������'
      read(*,*)
      stop

3     continue
      write(*,*) '----------����ģ̬������Ӧ---------------------'
      
      call computeEig(Alongitudinal,4)!��������ֵ����������
      write(*,*)'������һ������ֵ��Ӧ������������ʵ��'
      read(*,*)ModelX(1:4)
      !totalt=10.d0
      write(*,*) 'Input Total Simulation time:'
      read(*,*)  totalt
      write(*,*) '����ʱ������Ϊ',totalt,'s'
      write(*,*)'��ʼ���������浥λ��Ծ����״̬������ʱ����Ӧ'
      TT=0.d0         
      DT=0.001d0 
      Nstep=int(totalt/DT)   
!        1  2     3    4   5   6   7 8 9 10        11       12 13 14 15    
!    X = VT,ALPHA,BETA,PHI,THE,PSI,p,q,r,XN(north),XE(east),H. u, v, w
!         1   2   3   4
!    U = THTL,EL,AIL,RDR.      

        DeltaX(1:4)=ModelX(1:4)
        DeltaU(:)=0.d0
        open(20,file='./zongxiangmotaijili.dat')
        write(20,'(A120)')
     &  'variables=time(s),u(m/s),w(m/s),q(rad/s),THE(rad)'
        do i=1,Nstep
            call linearRK4(DT,Alongitudinal,Blongitudinal)
            !CALL linearF(XD1,Alongitudinal,Blongitudinal)
            !do j=1,4
            !  DeltaX(j)=DeltaX(j)+XD1(j)*DT
            !enddo
            linearX(1)=X(13)+DeltaX(1)
            linearX(2)=X(15)+DeltaX(2)
            linearX(3)=X(8)+DeltaX(3)
            linearX(4)=X(5)+DeltaX(4)
            TT=TT+DT
            write(20,'(1x,5g15.7)')TT,linearX(1:4)
          enddo
          close(20)     
      
      write(*,*) '�������������������ļ���ͼ'
      write(*,*) '�����������'
      read(*,*)
      stop
     
      
4     continue
      write(*,*) '----------����ģ̬������Ӧ---------------------'
      call computeEig(Alateral,4)!��������ֵ����������
      write(*,*)'������һ������ֵ��Ӧ������������ʵ��'
      read(*,*)ModelX(1:4)
      !totalt=10.d0
      write(*,*) 'Input Total Simulation time:'
      read(*,*)  totalt
      write(*,*) '����ʱ������Ϊ',totalt,'s'
      TT=0.d0         
      DT=0.001d0 
      Nstep=int(totalt/DT)   
!        1  2     3    4   5   6   7 8 9 10        11       12 13 14 15    
!    X = VT,ALPHA,BETA,PHI,THE,PSI,p,q,r,XN(north),XE(east),H. u, v, w
!         1   2   3   4
!    U = THTL,EL,AIL,RDR.      

        DeltaX(1:4)=ModelX(1:4)
        DeltaU(:)=0.d0
        open(20,file='./hengxiangmotaijili.dat')
        write(20,'(A120)')
     &    'variables=time(s),v(m/s),p(rad/s),r(rad/s),PHI(rad)'
        do i=1,Nstep
            call linearRK4(DT,Alateral,Blateral)
            linearX(1)=X(14)+DeltaX(1)
            linearX(2)=X(7)+DeltaX(2)
            linearX(3)=X(9)+DeltaX(3)
            linearX(4)=X(4)+DeltaX(4)
            TT=TT+DT
            write(20,'(1x,5g15.7)')TT,linearX(1:4)
          enddo
          close(20)     
      
      write(*,*) '�������������������ļ���ͼ'
      write(*,*) '�����������'
      read(*,*)
      stop
      end





      subroutine main_test_SMPLX
      implicit none
      integer NN,MM
      PARAMETER (NN=20, MM=10)

      integer NV,NC
      real(8) COST,bananafunction
      real(8) X(NN),U(MM),m2ft,S(2),DS(2),SIGMA,F0,FFIN
      EXTERNAL COST,bananafunction
!                       1   2     3    4   5   6  7 8 9 10       11       12     
!    X = STATE VECTOR - VT,ALPHA,BETA,PHI,THE,PSI,P,Q,R,XN(orth),XE(east),H.
C    U = INPUT VECTOR - THTL,EL,AIL,RDR.      
      COMMON/STATE/ X
      COMMON/ CONTROLS/ U

      m2ft=3.28084
      NV=3
      X=0.0
      U=0.0
      X(1) =400.0        !Vt
      X(12)=0.0       


      !call TRIMMER (NV, COST)
      !test 
      nv=2        
      S=(/2.0,0.0/)   
      DS=(/0.5,0.5/)
      SIGMA=-1    
      NC=10000
      CALL SMPLX(bananafunction,NV,S,DS,SIGMA,NC,F0,FFIN)
      WRITE(*,*)F0,FFin,S
      end


      FUNCTION bananafunction (S) !
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DOUBLE PRECISION S(*)
      bananafunction = (S(1)-1)**2+5*(S(1)**2-S(2))**2
      RETURN
      END

      subroutine printXU
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      integer NN,MM
      PARAMETER (NN=20, MM=10)
      real(8)::X(NN),U(MM)
      COMMON/STATE/ X
      COMMON/CONTROLS/ U      
      RTOD=180.d0/acos(-1.d0)
      WRITE(*,'(/1X,A)')'  Alpha��       Throttle    Elevator��
     &    Ailerons��    Rudder�� '
      WRITE(*,'(1X,5(1PE10.2,3X))')
     &      X(2)*RTOD,U(1),U(2),X(3)*RTOD, U(4)*RTOD
        
      write(*,*) "X:"
      write(*,*) "  u =",X(1)*cos(X(2))*cos(X(3))
      write(*,*) "  v =",X(1)*sin(X(3))
      write(*,*) "  w =",X(1)*sin(X(2))*cos(X(3))
      write(*,*) " �� =",X(4)*RTOD,'��'
      write(*,*) " �� =",X(5)*RTOD,'��'
      write(*,*) " �� =",X(6)*RTOD,'��'
      write(*,*) "  p =",X(7),'rad/s'
      write(*,*) "  q =",X(8),'rad/s'
      write(*,*) "  r =",X(9),'rad/s'
      write(*,*) "  xE=",X(10),'m'
      write(*,*) "  yE=",X(11),'m'
      write(*,*) "  zE=",X(12),'m'
      RETURN
      END

	subroutine writetitle
	character*10 bar10
	character*20 bar20
	bar10='----------'
	bar20='--------------------'
	write(6,'(4a20)')bar20,bar20,bar20,bar20
	write(6,*)'        Non-linear F16 Simulation            '
	write(6,*)'             �����ߣ�������'
	write(6,'(4a20)')bar20,bar20,bar20,bar20
	write(6,*)'  ��Ҫ��ʾ��'
	write(6,*)'::���������Aircraft Control and Simulation�α���д'
	write(6,*)'::��ȷ������
     & http://www.aem.umn.edu/~balas/darpa_sec/SEC.Software.html
     & �ϵĳ�������˶Ա���֤ '
	!write(6,*)'::��ʦ����������������������X=0.35c����'
	!write(6,*)'::F16����������X=0.30c��'
	write(6,*)'::����������ϵ��ʱ������ƫ�Ǻͷ����ƫ��Ҳ��Ҫ�����ٻ�'
	write(6,*)'::�ֱ�ʹ�����ƫ�����ֵ���������ٻ�'
	write(6,*)'::��������ʱֻ��ȫ���˶����̽���ʱ����Ӧ����'
	write(6,*)'::��������߻�����ʹ����ֵ΢�ֵķ�������'
	write(6,*)'::����������뿪������ϵ.'
	write(6,'(4a20)')bar20,bar20,bar20,bar20
	write(6,*)

	end      