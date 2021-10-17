//ZP60001  JOB (SYSGEN),'J06 M16: ZP60001',
//             CLASS=A,
//             MSGCLASS=A,
//             MSGLEVEL=(1,1),
//             REGION=4096K
/*JOBPARM LINES=100
//JOBCAT   DD  DSN=SYS1.VSAM.MASTER.CATALOG,DISP=SHR
//*
//*  WTO EXIT TO AUTOMATICALLY START TSO AFTER VTAM INITIALIZATION.
//*
//GENER01  EXEC PGM=IEBGENER
//SYSPRINT DD  DUMMY
//SYSUT1   DD  *
++USERMOD(ZP60001)       /* IEECVXIT WTO EXIT TO START TSO */  .
++VER(Z038) FMID(EBB1102)
 /*
   PROBLEM DESCRIPTION:
     TSO IS DIFFICULT TO START AUTOMATICALLY AFTER AN IPL.
       IF STARTED FROM A COMMNDXX MEMBER OF PARMLIB THEN TSO
       TRIES TO INITIALIZE BEFORE VTAM IS READY.  THE OPERATOR
       MUST THEN REPLY TO RETRY AFTER VTAM IS INITIALIZED.  IF
       TSO IS CONVERTED TO A TWO-STEP PROCEDURE WHERE THE FIRST
       STEP RUNS A PROGRAM TO WAIT FOR VTAM INITIALIZATION THEN
       IKTCAS00 LOSES THE "SYSTEM TASK" STATUS (WHICH REQUIRES
       THAT A STARTED TASK HAVE ONLY ONE STEP) WHICH SHOULD BE
       ASSIGNED AS PER THE PROGRAM PROPERTIES TABLE ENTRY.
       THE "PROBLEM PROGRAM ATTRIBUTES ASSIGNED" MESSAGE IS THEN
       ISSUED BY THE SYSTEM.

       THIS USERMOD CONTAINS AN IEECVXIT WTO EXIT WHICH WILL
       ISSUE THE "S TSO" OPERATOR COMMAND WHENEVER MESSAGE
       "IST02OI  VTAM INITIALIZATION COMPLETE" IS ISSUED.
       ONCE IMPLEMENTED, THIS ACTION WILL OCCUR EVERY TIME
       VTAM INITIALIZES, NOT NECCESSARILY JUST AFTER AN IPL.
       TSO CAN THEN REMAIN A SINGLE-STEP TASK AS DISTRIBUTED
       AND BE AUTOMATICALLY AVAILABLE AFTER VTAM IS READY.

   SPECIAL CONDITIONS:
     ACTION:
       A "CLPA" MUST BE PERFORMED AT IPL TIME FOR THIS EXIT TO
       BECOME ACTIVE.

   COMMENTS:
     PRYCROFT SIX P/L PUBLIC DOMAIN USERMOD FOR MVS 3.8 NUMBER 1.

     THE FOLLOWING MODULES AND/OR MACROS ARE AFFECTED BY THIS USERMOD:
     MODULES:
       IEECVXIT
 */.
++MOD(IEECVXIT) DISTLIB(AOSC5).
/*
//SYSUT2   DD  DSN=&&SMPMCS,DISP=(NEW,PASS),UNIT=SYSALLDA,
//             SPACE=(CYL,3),
//             DCB=(DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=4080)
//SYSIN    DD  DUMMY
//*
//IFOX00  EXEC PGM=IFOX00,PARM='OBJECT,NODECK,NOTERM,XREF(SHORT)'
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(CYL,10)
//SYSUT2   DD  UNIT=SYSALLDA,SPACE=(CYL,10)
//SYSUT3   DD  UNIT=SYSALLDA,SPACE=(CYL,10)
//SYSLIB   DD  DSN=SYS1.MACLIB,DISP=SHR
//         DD  DSN=SYS1.SMPMTS,DISP=SHR
//         DD  DSN=SYS1.AMODGEN,DISP=SHR
//SYSGO    DD  DSN=&&SMPMCS,DISP=(MOD,PASS)
//SYSIN    DD  *
IEECVXIT TITLE ' SINGLE LINE WTO/WTOR EXIT FOR MVS 3.8 '
***********************************************************************
*                                                                     *
*   THIS EXIT RECEIVES CONTROL FROM IEAVVWTO BEFORE THE WQE (AND      *
*   ORE IF IT IS A WTOR) ARE BUILT.  THE EXIT CAN CHANGE THE          *
*   ROUTING AND DESCRIPTOR CODES OF THE WTO (FIELDS USERRC AND        *
*   USERDC RESPECTIVELY).  (A WTOR WILL NOT YET HAVE A REPLY ID       *
*   ASSIGNED.)                                                        *
*                                                                     *
*   THIS EXIT WILL LOOK FOR MESSAGE                                   *
*             IST020I  VTAM INITIALIZATION COMPLETE                   *
*   (ONLY THE MESSAGE ID WILL BE CHECKED) AND WILL THEN ISSUE THE     *
*             S TSO                                                   *
*   OPERATOR COMMAND.                                                 *
*                                                                     *
*   THE INTENTION IS TO ALLOW FOR AN AUTOMATED IPL.  VTAM CAN BE      *
*   STARTED FROM THE COMMNDXX MEMBER OF PARMLIB, AND TSO WILL NOW     *
*   BE AUTOMATICALLY STARTED WHENEVER VTAM INITIALIZES.  THE TSO      *
*   STARTED TASK WILL THEREFORE NOT HAVE TO BE CHANGED TO INCLUDE     *
*   A FIRST STEP TO WAIT FOR VTAM TO COME UP, AND THE "PROBLEM        *
*   PROGRAM ATTRIBUTES ASSIGNED" MESSAGE WILL NOT BE ISSUED.          *
*                                                                     *
*   WRITTEN BY GREG PRICE          22 SEPTEMBER 2001                  *
*                                                                     *
***********************************************************************
         EJECT
IEECVXIT CSECT
         USING IEECVXIT,R15
         B     $START
         DROP  R15                 IEECVXIT
         DC    AL1(17),CL17'IEECVXIT &SYSDATE'
         USING IEECVXIT,R11
$START   STM   R14,R12,12(R13)     SAVE REGISTERS
         LR    R11,R15             SET BASE REGISTER
         L     R2,0(,R1)           POINT TO PARAMETER
         USING USERPARM,R2
         CLC   =C'IST020I ',USERTEXT
         BNE   RETURN              NOT THE MESSAGE TO BE ACTED UPON
         LA    R1,STSO             POINT TO COMMAND BUFFER
         SLR   R0,R0               CLEAR CONSOLE ID FOR MASTER
         SVC   34                  ISSUE OPERATOR COMMAND
         DROP  R2                  USERPARM
RETURN   LM    R14,R12,12(R13)     RESTORE REGISTERS
         BR    R14                 RETURN - R15 IS NOT CHECKED
         SPACE
STSO     DC    H'10',H'0',CL6'S TSO '
         LTORG
         DS    0D                  END OF CSECT
         TITLE ' EXIT PARAMETER STRUCTURE AND EQUATES '
USERPARM DSECT
USERTEXT DS    CL128
USERROUT DS    CL4
USERRC   EQU   USERROUT,2
USERDESC DS    CL4
USERDC   EQU   USERDESC,2
*        ORG   USERPARM+136
         SPACE 2
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
         SPACE 2
         END   IEECVXIT
/*
//*
//GENER2  EXEC PGM=IEBGENER
//SYSPRINT DD  DUMMY
//SYSUT1   DD  *
  IDENTIFY IEECVXIT('ZP60001')
//SYSUT2   DD  DSN=&&SMPMCS,DISP=(MOD,PASS)
//SYSIN    DD  DUMMY
//*
//RECEIVE EXEC SMPREC,WORK='SYSALLDA'
//SMPPTFIN DD  DSN=&&SMPMCS,DISP=(OLD,DELETE)
//SMPCNTL  DD  *
  RECEIVE
          SELECT(ZP60001)
          .
/*
//*
//APPLYCK EXEC SMPAPP,WORK='SYSALLDA'
//SMPCNTL  DD  *
  APPLY
        SELECT(ZP60001)
        CHECK
        .
/*
//*
//APPLY   EXEC SMPAPP,WORK='SYSALLDA'
//SMPCNTL  DD  *
  APPLY
        SELECT(ZP60001)
        DIS(WRITE)
        .
/*
//