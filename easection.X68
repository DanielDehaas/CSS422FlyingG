*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
            *MOVE.W  #$06B9,D4      *SUBI/ADDI
            *MOVE.W  #$4E97,D4       *JSR (An)     
            *MOVE.W  #$4EB9,D4      *JSR DIRECT-LONG
            *MOVE.W  #$42DD,D4
            *MOVE.W  #$DFC3,D4
            *MOVE.W   #$EB66,D4
            *MOVE.W  #$DA04,D4
            *MOVE.W  #$DAFC,D4
            MOVE.W  #$DFB9,D4
            MOVEA.L #$0000A000,A2
            

            MOVE.L  #$12345678,(A2)+
            MOVE.L  #$ABCDEF01,(A2)
            MOVE.L  -(A2),A6
            *BRA     EAADDI    
            *BRA     ENDIMATH
            *BRA     EAJSR
            *BRA      EAMOVEFCCR
            *BRA     EAADDA
            *BRA     EABITSHIFT
            BRA     EAADD
            
            
            
***************DELETE WHEN DONE WITH PRES...*********************
EAMOVE      RTS
EAMOVEM     RTS



*****************************************************************
* Specific ea code sections. handle nuanced behavior for each   *
* opcode which needs it                                         *
*****************************************************************
* EA MODES ADDI AND SUBI                                        *
*****************************************************************         
EAADDI      LEA     opHASH,A1
            *MOVE.W  #1,D1       *only print 1 byte
            *MOVE.W  #1,D0      
            MOVE.W  #14,D0      *set trap condition
            TRAP    #15             *print #
            LEA     opCASH,A1       
            TRAP    #15
            MOVE.W  D4,D5
            JSR     SIZEMATS        *GET immediate operand
            LEA     opCOMMA,A1      
            *MOVE.W  #$0001,D0
            MOVE.W  #14,D0
            TRAP    #15           
ENDIMATH    JSR     EAFORM1
            RTS
EASUBI      JMP     EAADDI

*****************************************************************
* ODD MODES; MOVEQ, MOVEM                                       *
*****************************************************************
EAMOVEQ     MOVE.L  #14,D0
            MOVE.W  D4,D5
            LEA     opHASH,A1
            TRAP    #15
            MOVE.B  D5,D7
            JSR     GETREG
            MOVE.W  #14,D0
            LEA     opCOMMA,A1
            TRAP    #15
            LEA     opDLTR,A1
            TRAP    #15
            JSR     MASK9AB
            MOVE.B  D5,D7
            JSR     GETREG
ENDMOVEQ    JMP     ENDMODE2
******************************************************************
* HANDLES JSR, MOVE FROM CCR, MOVE TO CCR, MOVE FROM SR, ADDQ,LEA*
******************************************************************
***PRE-%0100111010XXXXXX*******
***MODE CAN ONLY BE 010 OR 111*
*******************************
*BUG1 - PRINTING REG NUMBER TWICE*
*POTENTIALLY BECAUSE SIZE CODE 
*IS INCORRECT  -- FIXED

*BUG2 - NOT JUMPING CORRECTLY 
* SKIPPING JUMP TABLE -
* DIRECT TO Dn MODE WHEN
* USING 0100111010111001
* SEE EAFORM1 - LINE 73ish

EAJSR       MOVE.W  D4,D5
            JSR     EAFORM1
ENDEAJSR    JMP     ENDMODE2

***PRE-%0100001011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVEFCCR  MOVE.W  D4,D5
            JSR     EAFORM1
ENDMOVEFCCR JMP     ENDMODE2

***PRE-%0100010011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVE2CCR  JSR     EAFORM1
ENDMOVE2CCR JMP     ENDMODE2

***PRE-%0100000011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVESR    JSR     EAFORM1
ENDMOVESR   JMP     ENDMODE2

***PRE-%11100XXX11XXXXXX****
***THIS IS FOR MEM REGISTER*
***SHIFTS, ASL,ASR,LSL,LSR**
***ROL,ROR******************
****************************
EASHIFTM    JSR     EAFORM1
ENDSHIFTM   JMP     ENDMODE2

***PRE-%0101XXX0XXXXXXXX****
***EAADDQ - SYNTAX = *******
***ADDQ.s #<8BIT>,Ea********
EAADDQ      MOVE.W  D4,D5
            LEA     opHASH,A1
            MOVE.L  #0,D0
            TRAP    #15
            JSR     MASK9AB
            MOVE.W  D5,D1
            MOVE.W  #3,D0
            TRAP    #15
            LEA     opCOMMA,A1
            MOVE.L  #0,D0
            TRAP    #15
            JSR     EAFORM1
ENDADDQ     JSR     ENDMODE2

***PRE-%0100XXX111XXXXXX****
EALEA       JSR     EAFORM1
            CLR.L   D0
            LEA     opCOMMA,A1
            MOVE.W  #14,D0
            TRAP    #15
            LEA     opALTR,A1
            TRAP    #15
            JSR     MASK9AB
            MOVE.L  D5,D7
            JSR     GETREG
ENDLEA      JMP     ENDMODE2

ENDMODE2    RTS   
           

* Put program code here
*****************************************************************
* this section works for all opcodes whose format contains      *
* the eamode at bits 345 and ea reg at 012. size may or may not *
* be stored at 67                                              *
* AFFECTED OPs - ADDI, SUBI, JSR, MOVE FROM CCR, MOVE TO CCR,   *
* MOVE FROM SR, ASx memory, LSx memory, and ROx memory          * 
* PRE - INSTRUCTION IS STORED AT D4.W                           *
* P0ST - EA INSTRUCTIONS WILL BE PRINTED, MEMORY POINTER UPDATED*
*       D5 HOLDS MODE, D6 HOLDS SIZE, D7 HOLDS REGISTER OR QUANT*
*       OF TRAILING INSTRUCTION                                 *
*****************************************************************
EAFORM1     MOVEM.W D4,-(SP)    *BACKUP D4
            CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5       *D5 FOR EA MANIPULATION
            JSR     MASK012
            JSR     MASK345     
            LEA     EAMODTBL,A6
            MULU    #6,D5        
            JSR     0(A6,D5)   *Jump indirect with index
ENDFORM1    MOVEM.W (SP)+,D4
            RTS           
            
*****************************************************************
* this section works for branching opcode whose format contains  *
* the branching condition in bits 8,9,10. the displacement is   *
*    stored at bits 0 - 7. In the case where 0-7 == $00 the     *
*    displacement will be 16-bit stored at the trailing waddress*
*     In the case where 0-7 == $FF  the displacement is 32-bit  * 
*    and will be store in the trailing two words.               *
*                                                               *
*****************************************************************            
EABRANCH    MOVEM.W D4,-(SP)
            CLR.L   D5
            LEA     opOPAR,A1       *'$' put at A1
            *MOVE.W  #$0001,D1       *only print 1 byte
            *MOVE.W  #$0001,D0       *set trap condition
            MOVE.W  #14,D0
            TRAP    #15             *print '$'    
            MOVE.W  D4,D5
            ANDI.W  #$00FF,D5       *MASK - 0000000011111111
            CMPI.B  #$FF,D5
            BEQ     GETTWORD        *NEED TO WRITE DIFF
            CLR.L   D5
            CMPI.B  #$00,D5         *FUNCTION TO GET TRAILING
            BGT     GETDISP
            BRA     GETTWORD
            
ENDBRANCH   MOVEM.W (SP)+,D4
            RTS

GETDISP     CLR.L   D2
            MOVE.B  D5,D2
            *BRA     HEX2STRING
            BRA     ENDBRANCH
            
*****************************************************************
* this section works for shifting opcode whose format contains  *
* the count or source register in bits BA9, size in 67, i/r in 5*
*    and data register in 012                                   *
* THIS will be called by each specific shifting ea subroutine   *
*     Will work for ASx, LSx, and ROx.                          * 
* WIll not work for memory shift operations                     *
*SYNTAX IS DETERMINED BY BIT 5, IF 1, Dx,Dy ELSE #<DATA>,Dy     *
*****************************************************************              
EABITSHIFT  MOVEM.W D4,-(SP)
            CLR.L   D5
            MOVE.W  D4,D5
            ASR.W   #5,D5
            ANDI.W  #5,D5
            CMPI.B  #1,D5
            MOVE.W  D4,D5
            BEQ     SYNCASE1
            BRA     SYNCASE2  

ENDSHIFT    MOVEM.W (SP)+,D4
            RTS
            
***SYNTAX = Dx,Dy
SYNCASE1    LEA     opDLTR,A1
            MOVE.L  #14,D0
            TRAP    #15
            JSR     MASK9AB
            MOVE.L  D6,D7  
            LSR.W   #$08,D7
            LSR.W   #$01,D7         
            JSR     GETREG
            MOVE.L  #14,D0
            LEA     opCOMMA,A1
            TRAP    #15
            LEA     opDLTR,A1
            TRAP    #15
            JSR     MASK012
            JSR     GETREG            
            BRA     ENDSHIFT
            
***SYNTAX = #<data>,Dy
SYNCASE2    LEA     opHASH,A1
            MOVE.L  #14,D0
            TRAP    #15
            JSR     MASK9AB
            MOVE.L  D6,D7
            LSR.W   #$08,D7
            LSR.W   #$01,D7
            JSR     GETREG
            MOVE.L  #14,D0
            LEA     opCOMMA,A1
            TRAP    #15
            LEA     opDLTR,A1
            TRAP    #15
            JSR     MASK012
            JSR     GETREG  
            BRA     ENDSHIFT
*****************************************************************
* this section works for opcode who store the register at BA9,  *
*the opmode at 876, the EA mode at 345, and the ea reg/extension*
*    on 012. This will be the general form for the following    *
*    instructions: ADD AND, OR, SUB, DIVU, & MULS               *
*PRE:                                                           *
*                                                               *
*                                                               *
*****************************************************************
EAARITHM    MOVEM.W D4,-(SP)
            MOVE.W  D4,D5
            JSR     MASK678
            CMPI.B  #7,D6
            BEQ     SUBTRACT7
RETARITHM   CMPI.B  #3,D6
            BGT     ARITHM2            
            BRA     ARITHM1
            
ENDARITHM   MOVEM.W (SP)+,D4
            RTS
            

SUBTRACT7   SUBI.B  #7,D6
            BRA     RETARITHM
            
ARITHM1     MOVE.W  D4,D5
            JSR     MASK012
            JSR     MASK345     
            LEA     EAMODTBL,A6
            MULU    #6,D5        
            JSR     0(A6,D5)
            LEA     opCOMMA,A1
            MOVE.W  #14,D0
            TRAP    #15
            MOVE.W  D4,D5
            LEA     opDLTR,A1
            TRAP    #15
            JSR     MASK9AB
            MOVE.W  D5,D7
            JSR     GETREG
            BRA     ENDARITHM
            
ARITHM2     MOVE.W  D4,D5
            LEA     opDLTR,A1
            MOVE.W  #14,D0
            TRAP    #15
            JSR     MASK9AB
            MOVE.W  D6,D7
            JSR     GETREG
            LEA     opCOMMA,A1
            MOVE.W  #14,D0
            TRAP    #15
            MOVE.W  D4,D5
            JSR     MASK012
            JSR     MASK345
            LEA     EAMODTBL,A6
            MULU    #6,D5
            JSR     0(A6,D5)
            BRA     ENDARITHM
            
EAADD       JSR     EAARITHM
ENDEAADD    JMP     ENDMODE3

EAAND       JSR     EAARITHM
ENDEAAND    JMP     ENDMODE3

EAOR        JSR     EAARITHM
ENDEAOR     JMP     ENDMODE3

EASUB       JSR     EAARITHM
ENDEASUB    JMP     ENDMODE3

EADIVU      JSR     EAARITHM
ENDEADIVU   JMP     ENDMODE3

EAMULS      JSR     EAARITHM
ENDEAMULS   JMP     ENDMODE3

ENDMODE3    RTS

*****************************************************************
*EAADDA WILL BE CALLED FROM op-decoder                          *
* SYNTAX -> ADDA <EA>,An                                        *
* all modes required for the specification of this project are  *
*       valid.                                                  *
*PRE: INSTRUCTION will be stored on D5                          *
*****************************************************************  
*****************************************************************
* BUG - not working for direct addressing
*       -PROPOSED- define logic to not use
*       - jump table when ea == 111
****************************************************************

**** PRESENTATION MODE... UNCOMMENT LINES BETWEEN EAADA AND ENDADDA
EAADDA      CLR.L   D5              
*            MOVE.W  #14,D0      
*            MOVE.W  D4,D5       
*            JSR     MASK012     *PUT ea reg/extension on d7
*            CLR.W   D5          
*            CLR.L   D6
*            MOVE.W  D4,D5
*            JSR     MASK678     *put
*            CMPI.B  #3,D6
*            BEQ     PUSH1
*            CMPI.B  #7,D6
*            BEQ     PUSH2
*RETEADDA    JSR     MASK345
RETEADDA    MOVE.B  #0,D7
*            LEA     EAMODTBL,A6
*            MULU    #6,D5   
*            JSR     0(A6,D5)   *Jump indirect with index
*            MOVE.W  #14,D0
*            LEA     opCOMMA,A1
*            TRAP    #15
*            LEA     opALTR,A1
*            TRAP    #15
*            MOVE.W  D4,D5
*            ROL.W   #7,D5
*            JSR     SKIP012
*            JSR     GETREG
ENDADDA     RTS

PUSH1       MOVE.W  #1,D6
            BRA     RETEADDA
            
PUSH2       MOVE.W  #2,D6
            BRA     RETEADDA

*****************************************************************
* EA MODE TABLE - CALLED
*
*
*****************************************************************
EAMODTBL    JMP     MODE000     * Dn
            JMP     MODE001     * An
            JMP     MODE010     * (An)
            JMP     MODE011     * (An)+
            JMP     MODE100     * -(An)
            JMP     MODE101     * INVALID
            JMP     MODE110     * INVALID
            JMP     MODE111     * Direct Addressing/Immediate
            

*****************************************************************
* Reached from EAMODTBL - Used only for instructions which store*
* EA mode in bits 345. Instruction will be on D4, manipulated on*
* D5, D6 will keep size data,                                   *
* POSTCONDITION, prints necessary EA information to screen.     *
*****************************************************************

*must print D, get reg number, print reg number, 
MODE000     LEA     opDLTR,A1       *Letter 'D' put at A1
            *MOVE.W  #$0001,D1       *only print 1 byte
            *MOVE.W  #$0001,D0       *set trap condition
            MOVE.W  #14,D0
            TRAP    #15             *print D
            JSR     GETREG          *GET REG NUMBER
            BRA     ENDMODE
            
MODE001     LEA     opALTR,A1       *Letter 'A' put at A1
            *MOVE.W  #$0001,D1       *only print 1 byte
            *MOVE.W  #$0001,D0       *set trap condition
            MOVE.W  #14,D0
            TRAP    #15             *print A
            JSR     GETREG          *GET REG NUMBER
            BRA     ENDMODE
            
MODE010     LEA     opOPAR,A1       *'(' put at A1
            *MOVE.W  #$0001,D1       *only print 1 byte
            *MOVE.W  #$0001,D0       *set trap condition
            MOVE.W  #14,D0
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            *MOVE.W  #$0001,D1       *only print 1 byte
            *MOVE.W  #$0001,D0       *set trap condition
            MOVE.W  #14,D0
            TRAP    #15
            BRA     ENDMODE
            
            
MODE011     LEA     opOPAR,A1       *'(' put at A1
            MOVE.W  #14,D0
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            MOVE.W  #14,D0
            TRAP    #15
            LEA     opPLUS,A1       *'+'
            TRAP    #15
            BRA     ENDMODE

MODE100     LEA     opMINUS,A1      *'-' -> A1           
            MOVE.W  #14,D0
            TRAP    #15             *print '-'
            LEA     opOPAR,A1       *'(' put at A1
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            MOVE.W  #14,D0
            TRAP    #15
            BRA     ENDMODE
            
MODE101     BRA     ENDMODE

MODE110     BRA     ENDMODE         

MODE111     JSR     MASK012         *leaves reg extension on D7
            JSR     REGEXT          *Need more info
            
            BRA     ENDMODE

ENDMODE     RTS
            
**************************************************************
* GETREG is used to get the register number held on bits 012 *
* PRECONDITION - D5 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012. D7 MUST CONTAIN ONLY WHAT IS TO BE PRINTED TO SCRN *
* POST - D5 will contain REGISTER NUMBER, NUMBER IS PRINTED  *
**************************************************************
GETREG      *ANDI.W  #$0007,D5
            MOVE.W  #$0003,D0
            MOVE.W  D7,D1
            TRAP    #15
ENDGREG     RTS

*************************************************************
* MASK012 masks word on D5 and puts result on D7            *
* PRE - D4 contains instruction.                            *
* POST - D7 will contain the DATA from bits 012             *
*************************************************************
MASK012     CLR.L   D5
            CLR.L   D7
            MOVE.W  D4,D5
SKIP012     ANDI.W  #$0007,D5       *mask 0000000000000111
            MOVE.W  D5,D7
END012      RTS
      
*************************************************************
* MASK345 masks word on D5                                  *
* PRE - D4 contains instruction.                            *
* POST - D5 Will contain the DATA from bits 345             *
************************************************************* 
MASK345     CLR.L   D5
            MOVE.W  D4,D5
            ANDI.W  #$0038,D5       *mask 0000000000111000
            LSR.B   #$03,D5

END345      RTS

*************************************************************
* MASK67masks word on D5 and puts result on D6             *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 67              *
*************************************************************
MASK67      CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$00C0,D5       *mask 0000000011000000
            LSR.B   #6,D5
            MOVE.W  D5,D6
END67       RTS

*************************************************************
* MASK678 masks word on D5 and puts result on D6            *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 678             *
*************************************************************
MASK678     CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$01C0,D5       *mask 0000000111000000
            MOVE.W  D5,D6
            LSR.W   #$06,D5
            MOVE.W  D5,D6
END678      RTS

*************************************************************
* MASK9AB masks word on D5 and puts result on D6            *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 9AB             *
*************************************************************
MASK9AB     CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$0E00,D5       *mask 0000111000000000
            LSR.W   #$08,D5
            LSR.W   #$01,D5
            MOVE.W  D5,D6
END9AB      RTS


*************************************************************
* REGEXT determines if trailing data is a word or a long,   *
*       prints appropriate trailing data, UPDATES MEM PTR   *
*PRE - instruction is on D4, opmode == 111 -> #<data> or    *
*       direct addressing                                   *
*POST - trailing information is printed in correct place,   *
*       A2 mem pointer is appropriately incremented, if     *
*       trailing needs to be stored, will be on D7          *
*************************************************************

REGEXT      MOVE.W  D4,D5
            LEA     opCASH,A1       *DISPLAY '$' for trailing
            MOVE.W  #14,D0
            TRAP    #15
            CMPI.W  #$0004,D7
            BEQ     SIZEMATS
            CMPI.W  #$0001,D7
            BEQ     GETTLONG
            BRA     GETTWORD        ****MAY NEED TO CLEAN UP 
                                    ****BRANCHING AND RTS

* used for #<data>, need this to determine if we need word or long
***bug- THIS PART WILL NOT WORK FOR ADDA WHERE THE OPMODE
SIZEMATS    JSR     MASK67          *Ensure size is on d6
            CMPI.B  #$02,D6
            BEQ     GETTLONG
            BRA     GETTWORD
ENDREGEXT   RTS      
            
GETTLONG    *MOVE.W  #$0008,D1
            *MOVE.W  #$0001,D0
            ADDA.L  #$2,A2
            MOVE.W  (A2),D2  
            JSR     PRINTD2W
                        
GETTWORD    *MOVE.W  #$0008,D1
            *MOVE.W  #$0001,D0
            ADDA.L  #$2,A2
            MOVE.W  (A2),D2
            JSR     PRINTD2W
            BRA     ENDREGEXT
            
*GETTBYTE    ***********DO SHIT HERE********************
     
     
*****////////////I/O//////////////////******************
*//////////////////// I/O Subroutines //////////////////////




*-------------------- PREPMASKCHK ---------------------
* Clears D5 and D7; loads D5 with the HEX of OPCODE
* To be executed on every opcode cycle
*------------------------------------------------------
PREPMASKCHK CLR.L   D5
            CLR.L   D7
            MOVE.L  D4,D5
            RTS



*-------------------- PRINTOFFSET ---------------------
* Very temporary/test - checking HEX2STRING
*------------------------------------------------------
PRINTOFFSET MOVE.L  #SafeOutStr,A4
            MOVE.L  A2,D2
            JSR     HEX2STRING
            MOVE.L  #CurAddrOut,A4
            MOVE.L  D2,(A4)
            JSR     ADDRPRNT
            JSR     ADDRRESETL
            MOVE.L  #SafeOutStr,A4
            RTS
            


*--------------------- PRINTD2W -----------------------
* Prints the hex data of D2.W as string (no whitespace)
*------------------------------------------------------
PRINTD2W    JSR     ADDRRESETW
            JSR     HEX2STRING
            MOVE.L  #CurAddrOut,A4
            MOVE.L  D2,(A4)
            JSR     ADDRPRNT
            JSR     ADDRRESETL
            MOVE.L  #SafeOutStr,A4
            RTS



*-------------------- STRING2HEX ----------------------
* Converts string at A1 to hex value at D2
* Input: (A1) (string), D1.W (# of chars)
* Output: D2.L (hex value)
* Process: D3.B, D1.B (overwrites), A1 (overwrites)
* NOTE: Skips first char (will be $ in implementation)
*
* NOTE2: NOT FINISHED. No error checking for non 0-F
* characters. Must check and exit if incorrect. Also,
* it currently takes any size input. Should only take
* 4 & 8 digit hex values for best practice. 4 digit
* values larger than '7FFF' must have preceding digits
* rounded to 'FFFF'.
*------------------------------------------------------
STRING2HEX  CLR.L   D2
            MOVE.B  D1,D3
            SUBQ.B  #1,D3
            ADDQ.W  #1,A1
S2HLOOP1    CMP     #0,D3
            BLE     S2HEXIT
            SUBQ    #1,D3
            MOVE.B  (A1)+,D1
            CMP.B   #$40,D1
            BLT     S2HSKIP1
            SUB.B   #$7,D1
S2HSKIP1    SUB.B   #$30,D1
            LSL.L   #4,D2
            ADD.B   D1,D2
            BRA.W   S2HLOOP1         
S2HEXIT     RTS
            
            
            
*-------------------- HEX2STRING ----------------------
* Converts HEX at D2 to string at SafeStr1
* Input: D2.W (contents of HEX; ONLY WORD)
* Output: D2.L (string content)
* Process: D3.L, D4.L (backup in SP)
*------------------------------------------------------
HEX2STRING  MOVEM.L D3-D4,-(SP)
            CLR.L   D3
            CLR.L   D4
            MOVE.W  #$F000,D3
            AND.W   D2,D3   * #$A000 (#$ABCD)
            LSR.W   #8,D3  
            LSR.W   #4,D3   * #$000A
            JSR     H2SDIGIT
            MOVE.B  D3,D4   * #$000000XX
            LSL.L   #8,D4   * #$0000XX00
            
            MOVE.W  #$0F00,D3
            AND.W   D2,D3   * #$0B00
            LSR.W   #8,D3   * #$000B
            JSR     H2SDIGIT
            MOVE.B  D3,D4   * #$0000xxXX
            LSL.L   #8,D4   * #$00xxXX00
            
            MOVE.W  #$00F0,D3
            AND.W   D2,D3   * #$00C0
            LSR.W   #4,D3   * #$000C
            JSR     H2SDIGIT
            MOVE.B  D3,D4   * #$00xxxxXX
            LSL.L   #8,D4   * #$xxxxXX00
            
            MOVE.W  #$000F,D3
            AND.W   D2,D3   * #$000D
            JSR     H2SDIGIT
            MOVE.B  D3,D4   * #$xxxxxxXX
            
            MOVE.L  D4,D2

H2SEXIT     MOVEM.L (SP)+,D3-D4
            RTS

*--------------------- H2SDIGIT -----------------------
* NOT FOR USAGE - PRIVATE HEX2STRING SUBROUTINE
*------------------------------------------------------
H2SDIGIT    CMP.B   #09,D3
            BLE     NUM_H2SD
LET_H2SD    ADD.B   #$37,D3
            BRA.W   EXIT_H2SD
NUM_H2SD    ADD.B   #$30,D3
            BRA.W   EXIT_H2SD
EXIT_H2SD   RTS



*-------------------- STRTOHEX ----------------------
* Converts string at A1 to hex value at D2
* Input: (A1) (string), D1.W (# of chars)
* Output: D2.L (hex value)
* Process: D3.B, D1.B (overwrites), A1 (overwrites)
* NOTE: Skips first char (will be $ in implementation)
*
* Readed in string A2 and A3 from the code before 
* We need to convert it to hex, so we use the logic 
* from below
* This code  is currently for  A2. Reusable for A3 as 
* well if value is  changed. 
*------------------------------------------------------
*NOTE: address is changable, adjust it to whatever we need:)* changed to STRTOHEXOUT
STRTOHEX    MOVEM.L A0-A6/D0-D7,-(SP)
            MOVEA.L STRTOHEXOUT, A5
*Store i = 8 for looping for 8 characters*
            ADDI.B  #1,D1
            *MOVE.B  #9, D1      
            
* here we are going to use the loop to scan for 
* potential letters and  numbers. This part is representing 
* the for llop from 8 to 0 at D1
START_S2H  
* check +1 for trial attempt for first digit.
            MOVE.B  (A2)+,D3        
            SUB.B   #1, D1
*if our counter is 0, then we are done with checking digit by digit.     
            CMP.B   #0, D1      
            BEQ     ADD$5LOGIC    
*compare to 40/39 to see numbers/letters
            CMP.B   #$40, D3    
            BGT     POSSIBLE_LETTER 
            CMP.B   #$3A, D3     
            BLT     POSSIBLE_NUM 
POSSIBLE_LETTER
*is it full?has data? fix if  not
            CMP.B   #$46, D3    
            BGT     NOTFULL8 
*convert using -
            SUB.B   #$37, D3
            MOVE.B  D3, (A5)+
*go back if success
            BRA START_S2H
POSSIBLE_NUM
*same logic as letter: check if full, fix
            CMP.B   #$30, D3    
            BLT     NOTFULL8   
*convert by -
            SUB.B   #$30, D3    
            MOVE.B  D3, (A5)+
*go back
            BRA START_S2H  
NOTFULL8 
*used in possible num/leter
* fills  empty space with 0's if user didn't 
            MOVE.B  #$00, (A5)+ 
            BRA START_S2H
* loop used to shift the data we need
* for the correct conversion. 
ADD$5LOGIC
*reset a5, make d1 = hex5
            MOVEA.L STRTOHEXOUT, A5
*adjust for the next loop 
            MOVE.B  #5, D1  
*loop for d1 = 5 going down    
LOOP_D1_5   SUB.B   #1, D1     
            CMP.B   #0, D1      
            BEQ     DONE_S2H
            MOVE.B (A5)+, D2    
*shifting logic
            LSL.L   #4, D2      
            ADD.B  (A5)+,D2     
            LSL.L   #8, D3      
*add result
            ADD.B   D2, D3      
*repeat till done
            BRA LOOP_D1_5 

DONE_S2H    MOVEM.L (SP)+,A0-A6/D0-D7
            MOVE.L  STRTOHEXOUT,D0
            RTS 
*--------------------- /STRTOHEX ----------------------



*///////////////////////////////////////////////////////////




*////////////////// Op-Code Subroutines ////////////////////


*------------------- PAUSEOUTPUT ----------------------
* Simply prints message <ENTER TO CONTINUE> and takes
* user input before continuing
*------------------------------------------------------
PAUSEOUTPUT * reset counter
            MOVE.B  #$00,(LoopCounter) 
            
            * print message
            MOVE.W  #14,D0
            LEA     CONTINUE,A1
            TRAP    #15
            * take input
            MOVEA.W #SafeStrA1,A1
            MOVE.W  #2,D0
            TRAP    #15
            * TRAP 14 ready
            MOVE.W  #14,D0
POEXIT      RTS
            

*-------------------- OUTPUTSTR -----------------------
* In this subroutine, we loop through each character of
* a DC.B and add it to SafeOutStr, stopping when we hit
* "00" (null termination). We will increment var
* SafeOutPtr as we go along, and it will be left at the
* last empty space on exit.
* INPUT: A1 (points to specific DC.B; use "LEA   x,A1",
* A4 (points to continuing point in SafeStrOut)
* OUTPUT: A1, SafeOutStr, SafeOutPtr
*------------------------------------------------------
OUTPUTSTR   *MOVE.L  #SafeOutStr,(SafeOutPtr)
OSLOOP      CMP.B   #0,(A1)
            BEQ     OSEXIT
            MOVE.B  (A1)+,(A4)
            ADDA.L  #1,A4
            BRA.W   OSLOOP
OSEXIT      RTS

           

*------------------- OUTPUTPRNT -----------------------
* Print characters in A4
*------------------------------------------------------
OUTPUTPRNT  JSR     PRINTOFFSET
            LEA     SafeOutStr,A1
            TRAP    #15
            JSR     OUTPUTRESET
            RTS



*-------------------- ADDRPRNT ------------------------
* Print characters in of HEX address
*------------------------------------------------------
ADDRPRNT    LEA     CurAddrOut,A1
            TRAP    #15
            JSR     ADDRRESETL
            RTS



*------------------- OUTPUTRESET ----------------------
* Resets the Safe String pointer (A4) to beginning,
* resets the data for new input
*------------------------------------------------------
OUTPUTRESET MOVEA.L #SafeOutStr,A4
            * Set $00020000 to #$202020202020202000FFFFFFFFFFFFFF
            MOVE.L  #$20202020,(A4)
            MOVE.L  #$20202020,$4(A4)
            MOVE.L  #$00FFFFFF,$8(A4)
            MOVE.L  #$FFFFFFFF,$C(A4)
            RTS 


            
*-------------------- ADDRRESETL ----------------------
* Resets the Current Address pointer (A4) to beginning,
* resets the data for new input
*------------------------------------------------------
ADDRRESETL  * Set Safe Output Pointer
            MOVEA.L  #CurAddrOut,A4
            * Set CurAddrOut to #$202020202020202000FFFFFFFFFFFFFF
            MOVE.L  #$20202020,(A4)
            MOVE.L  #$20202020,$4(A4)
            MOVE.L  #$00FFFFFF,$8(A4)
            MOVE.L  #$FFFFFFFF,$C(A4)
            MOVEA.L #SafeOutStr,A4
            RTS 
            
            
            
*-------------------- ADDRRESETW ----------------------
* Resets the Current Address pointer (A4) to beginning,
* resets the data for new input
*------------------------------------------------------
ADDRRESETW  MOVEA.L  #CurAddrOut,A4
            * Set CurAddrOut to #$2020202000FFFFFFFFFFFFFFFFFFFFFF
            MOVE.L  #$20202020,(A4)
            MOVE.L  #$00FFFFFF,$4(A4)
            MOVE.L  #$FFFFFFFF,$8(A4)
            MOVE.L  #$FFFFFFFF,$C(A4)
            MOVEA.L #SafeOutStr,A4
            RTS 
            
* Put variables and constants here

opCOMMA     DC.B    ',',0
opOPAR      DC.B    '(',0
opCPAR      DC.B    ')',0
opALTR      DC.B    'A',0
opDLTR      DC.B    'D',0
opPLUS      DC.B    '+',0
opMINUS     DC.B    '-',0
opSLASH     DC.B    '/',0
opCASH      DC.B    '$',0
opHASH      DC.B    '#',0

**********************************************
*************zach stuff***********************    
LSR         DC.B    'LSR.',0
ROL         DC.B    'ROL.',0
ROR         DC.B    'ROR.',0
ASL_MEM     DC.B    'ASL     ',0
ASR_MEM     DC.B    'ASR     ',0
LSL_MEM     DC.B    'LSL     ',0
LSR_MEM     DC.B    'LSR     ',0
ROL_MEM     DC.B    'ROL     ',0
ROR_MEM     DC.B    'ROR     ',0

symbCASH    DC.B    '$',0

B           DC.B    'B',0
W           DC.B    'W',0
L           DC.B    'L',0

DATASTUFF   DC.B    '####',0
NEWLINE     DC.B    '',CR,LF,0
CR          EQU     $0D
LF          EQU     $0A
CONTINUE    DC.B    '<ENTER TO CONTINUE>',0


SafeStrA1   EQU     $0FB0
LoopCounter EQU     $0001FFFF   * For determining when to pause output
SafeOutStr  EQU     $00020000   * All output in string format will go here, with an
                                *  incrementing Addr inserting as we disassemble
                                *  Uses FULL memory offset (4 longs)
STRTOHEXOUT EQU     $0001FFF0   * Uses Long
CurAddrOut  EQU     $0001FFE0   * Uses FULL memory offset (4 longs)
JSRDATA1    EQU     $0001FFFE   * Uses Byte to be used in Subroutines for ANY purpose - defined by subroutine
***********************************************************************************************************


            END    START        ; last line of source



