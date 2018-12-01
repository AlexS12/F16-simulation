      SUBROUTINE RK4(F,DT,XX,NX)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      !input :״̬����XX,��������U,ʱ�䲽��DT
      !output:�ƽ�һ�����µ�״̬����XX
      PARAMETER (NN=20) ! same as main prog.
      REAL(8):: XX(NN),XD(NN),X(NN),XA(NN)
      
      CALL F(XX,XD)
      
      DO M=1,NX
        XA (M)=XD(M)*DT
        X(M)=XX(M)+0.5d0*XA(M)
      enddo
      
      CALL F(X,XD)
      
      DO M=1,NX
        Q=XD(M)*DT
        X(M)=XX(M)+0.5*Q
        XA(M)=XA(M)+Q+Q
      enddo
      
      CALL F(X,XD)
      
      DO M=1,NX
        Q=XD(M)*DT
        X(M)=XX(M)+Q
        XA(M)=XA(M)+Q+Q
      enddo
      
      CALL F(X,XD)
      
      DO M=1,NX
        XX(M)=XX(M)+(XA(M)+XD(M)*DT)/6.d0
      enddo
      RETURN
      END
      
      SUBROUTINE linearRK4(DT,AAA,BBB)
      use var
      !IMPLICIT real(8) (A-H,O-Z)
      IMPLICIT none
      !input :״̬����XX,��������U,ʱ�䲽��DT
      !output:�ƽ�һ�����µ�״̬����XX
      integer NX,NU!״̬�����Ϳ��Ʊ����ĸ���
      PARAMETER (NX=4, NU=2)
      integer M
      real(8) Q,DT
      real(8) X(NX), XD(NX),XA(NX)
      real(8) AAA(NX,NX),BBB(NX,NU)      

      CALL linearF(XD,AAA,BBB)
      
      DO M=1,NX
        XA (M)=XD(M)*DT
        X(M)=DeltaX(M)+0.5d0*XA(M)
      enddo
      
      CALL linearF(XD,AAA,BBB)
      
      DO M=1,NX
        Q=XD(M)*DT
        X(M)=DeltaX(M)+0.5*Q
        XA(M)=XA(M)+Q+Q
      enddo
      
      CALL linearF(XD,AAA,BBB)

      DO M=1,NX
        Q=XD(M)*DT
        X(M)=DeltaX(M)+Q
        XA(M)=XA(M)+Q+Q
      enddo
      
      CALL linearF(XD,AAA,BBB)
      
      DO M=1,NX
        DeltaX(M)=DeltaX(M)+(XA(M)+XD(M)*DT)/6.d0
      enddo
      RETURN
      END