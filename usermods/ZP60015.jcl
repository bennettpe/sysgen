//ZP60015  JOB (SYSGEN),'J01 M29: ZP60015',
//             CLASS=A,
//             MSGCLASS=A,
//             MSGLEVEL=(1,1),
//             REGION=4096K
/*JOBPARM LINES=100
//JOBCAT   DD  DSN=SYS1.VSAM.MASTER.CATALOG,DISP=SHR
//*
//*  EXTEND THE JOB SEARCH BY JES2 FOR TSO STATUS WITHOUT OPERANDS.
//*
//RECEIVE EXEC SMPREC,WORK='SYSALLDA'
//SMPPTFIN DD  *
++USERMOD(ZP60015)          /* EXTEND JES2 TSO STATUS SEARCH */  .
++VER(Z038) FMID(EJE1103)
  PRE(UZ31176,UZ33158,UZ35334,UZ37263,UZ52543,UZ54837,UZ57911,
      UZ63374,UZ65742,UZ68537,UZ71437,UZ76165)
 /*
   PROBLEM DESCRIPTION:
     TSO STATUS ONLY LOOKS FOR JOB NAMES OF USERID PLUS ONE CHARACTER.
       WHEN THE TSO STATUS COMMAND IS ISSUED WITHOUT ANY OPERAND
       THE SYSTEM LOOKS FOR ALL JOBS WITH NAMES BEGINNING WITH THE
       USERID PLUS ONE CHARACTER.  IF THE USERID IS SHORTER THAN
       SEVEN CHARACTERS THEN OTHER JOBS WITH NAMES BEGINNING WITH
       THE USERID BUT HAVING MORE THAN ONE EXTRA CHARACTER ARE NOT
       REPORTED BY THE STATUS COMMAND.

       THIS USERMOD ALTERS JES2 SO THAT ANY JOB WITH A NAME WHICH
       STARTS WITH THE REQUESTING USERID IS REPORTED.

   SPECIAL CONDITIONS:
     ACTION:
       JES2 MUST BE RESTARTED FOR THIS ZAP TO BECOME ACTIVE.
       A HOT START IS SUFFICIENT.

   COMMENTS:
     PRYCROFT SIX P/L PUBLIC DOMAIN USERMOD FOR MVS 3.8 NO. 15.

     USERMODS ZP60015 AND ZP60016 ARE INTENDED TO BE OPERATIONAL
     CONCURRENTLY.  NOTE THE FOLLOWING BEHAVIOUR TABLE:

       WHICH USERMODS ACTIVE      I  STATUS DEFAULT SEARCH
       ==========================================================
       NEITHER 15 NOR 16 APPLIED  I  FIND USERID+1 ONLY
       ----------------------------------------------------------
       15 APPLIED BUT NOT 16      I  FIND USERID+0,1,2,3 BUT
                                  I  NAME REPORTED AS USERID+1
       ----------------------------------------------------------
       16 APPLIED BUT NOT 15      I  FIND USERID+1 ONLY BUT
                                  I  MESSAGE HAS NULLS AFTER NAME
       ----------------------------------------------------------
       BOTH 15 AND 16 APPLIED     I  FIND USERID+0,1,2,3
       ----------------------------------------------------------

     THE FOLLOWING MODULES AND/OR MACROS ARE AFFECTED BY THIS USERMOD:
     MODULES:
       HASPXEQ
 */.
++ SRCUPD   (HASPXEQ)  DISTLIB(HASPSRC ).
./ CHANGE NAME=HASPXEQ
         CLM   WD,1,=AL1(L'JQEJNAME-2) TEST FOR FULL NAME SCAN  ZP60015 U5596000
         SLR   R15,R15             CLEAR FOR INSERT             ZP60015 U5599000
         IC    R15,SJBTULEN        GET USER NAME LENGTH         ZP60015 U5599500
         LA    R15,JQEJNAME(R15)   POINT TO LAST CHARACTER + 1  ZP60015 U5600000
         CLM   WD,1,=AL1(L'JQEJNAME-5)  NEED TRAILER CHECK?     ZP60015 U5602000
         BH    XTJSCNA             NO, NAME LONG ENOUGH TO NOT  ZP60015 U5603000
         CLI   3(R15),C' '         INSURE NAME NOT >3 LONGER    ZP60015 U5604000
         NOP   XTJSCN     (BE)     LOOP IF NOT (TSO ID OKAY)    ZP60015 U5612000
         ICM   WD,14,0(R15)        PICK UP CHARACTER(S)         ZP60015 U5614000
         STCM  WD,14,SSCSUJOB      SET LAST CHARS IF PRESENT    ZP60015 U5684000
/*
//SMPCNTL  DD  *
  RECEIVE
          SELECT(ZP60015)
          .
/*
//*
//APPLYCK EXEC SMPAPP,WORK='SYSALLDA'
//SYSUT1   DD  SPACE=(1700,(1200,100))
//SYSUT2   DD  SPACE=(1700,(1200,100))
//SYSUT3   DD  SPACE=(1700,(1200,100))
//SMPWRK3  DD  UNIT=&WORK,SPACE=(CYL,(80,20,84)),DCB=(BLKSIZE=3120,
//             LRECL=80)
//SMPCNTL  DD  *
  APPLY
        SELECT(ZP60015)
        CHECK
        .
/*
//*
//APPLY   EXEC SMPAPP,COND=(0,NE),WORK='SYSALLDA'
//SYSUT1   DD  SPACE=(1700,(1200,100))
//SYSUT2   DD  SPACE=(1700,(1200,100))
//SYSUT3   DD  SPACE=(1700,(1200,100))
//SMPWRK3  DD  UNIT=&WORK,SPACE=(CYL,(80,20,84)),DCB=(BLKSIZE=3120,
//             LRECL=80)
//SMPCNTL  DD  *
  APPLY
        SELECT(ZP60015)
        .
/*
//