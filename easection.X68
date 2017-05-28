*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
            MOVE.W  #$06B9,D4      *SUBI/ADDI
            *MOVE.W  #$4E97,D4       *JSR (An)     
            *MOVE.W  #$4EB9,D4      *JSR DIRECT-LONG
            *MOVE.W  #$42DD,D4
            MOVEA.L #$0000A000,A2
            MOVE.L  #$12345678,(A2)
            
            BRA     EAADDI    
            *BRA     ENDIMATH
            *BRA     EAJSR
            *BRA      EAMOVEFCCR
*****************************************************************
* Specific ea code sections. handle nuanced behavior for each   *
* opcode which needs it                                         *
*****************************************************************
* EA MODES ADDI AND SUBI                                        *
*****************************************************************         
EAADDI      LEA     opHASH,A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print #
            LEA     opCASH,A1       
            TRAP    #15
            MOVE.W  D4,D5
            JSR     SIZEMATS        *GET immediate operand
            LEA     opCOMMA,A1      
            MOVE.W  #$0001,D0
            TRAP    #15           
ENDIMATH    JSR     EAFORM1
            RTS
EASUBI      JMP     EAADDI

*****************************************************************
* HANDLES JSR, MOVE FROM CCR, MOVE TO CCR, MOVE FROM SR         *
*****************************************************************
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
ENDEAJSR    JSR     ENDMODE2

***PRE-%0100001011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVEFCCR  MOVE.W  D4,D5
            JSR     EAFORM1
ENDMOVEFCCR JSR     ENDMODE2

***PRE-%0100010011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVE2CCR  JSR     EAFORM1
ENDMOVE2CCR JSR     ENDMODE2

***PRE-%0100000011XXXXXX***
***MODE CANNOT BE 001******
***************************
EAMOVESR    JSR     EAFORM1
ENDMOVESR   JSR     ENDMODE2

***PRE-%11100XXX11XXXXXX****
***THIS IS FOR MEM REGISTER*
***SHIFTS, ASL,ASR,LSL,LSR**
***ROL,ROR******************
****************************
EASHIFTM    JSR     EAFORM1
ENDSHIFTM   JSR     ENDMODE2

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
            *SUBI    #18,D5         
            JSR     0(A6,D5)   *Jump indirect with index
ENDFORM1    MOVEM.W (SP)+,D4
            RTS           
            
*****************************************************************
* this section works for branhing opcode whose format contains  *
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
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
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
* EA MODE TABLE - CALLED
*
*
*****************************************************************
EAMODTBL    JMP     MODE000     * Dn
            JMP     MODE001     * An
            JMP     MODE010     * (An)
            JMP     MODE011     * (An)+
            JMP     MODE100     * -(An)
            JMP     MODE111     * Direct Addressing/Immediate
            

*****************************************************************
* Reached from EAMODTBL - Used only for instructions which store*
* EA mode in bits 345. Instruction will be on D4, manipulated on*
* D5, D6 will keep size data,                                   *
* POSTCONDITION, prints necessary EA information to screen.     *
*****************************************************************

*must print D, get reg number, print reg number, 
MODE000     LEA     opDLTR,A1       *Letter 'D' put at A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print D
            JSR     GETREG          *GET REG NUMBER
            BRA     ENDMODE
            
MODE001     LEA     opALTR,A1       *Letter 'A' put at A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print A
            JSR     GETREG          *GET REG NUMBER
            BRA     ENDMODE
            
MODE010     LEA     opOPAR,A1       *'(' put at A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15
            BRA     ENDMODE
            
            
MODE011     LEA     opOPAR,A1       *'(' put at A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15
            LEA     opPLUS,A1       *'+'
            TRAP    #15
            BRA     ENDMODE

MODE100     LEA     opMINUS,A1      *'-' -> A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print '-'
            LEA     opOPAR,A1       *'(' put at A1
            TRAP    #15             *print '('
            LEA     opALTR,A1       *Letter 'A' put at A1
            TRAP    #15             *print 'A'
            JSR     GETREG          *GET REG NUMBER
            LEA     opCPAR,A1       *')'
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15
            BRA     ENDMODE

MODE111     JSR     MASK012         *leaves reg extension on D7
            JSR     REGEXT          *Need more info
            
            BRA     ENDMODE

ENDMODE     RTS
            
**************************************************************
* GETREG is used to get the register number held on bits 012 *
* PRECONDITION - D5 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
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
            ANDI.W  #$0007,D5       *mask 0000000000000111
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
            *LSL.B   #$02,D5
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
            MOVE.W  D5,D6
END67       RTS

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
            MOVE.W  #$0001,D0       * data
            MOVE.W  #$0001,D1
            TRAP    #15
            CMPI.W  #$0004,D6
            BEQ     SIZEMATS
            CMPI.W  #$0001,D6
            BEQ     GETTLONG
            BRA     GETTWORD        ****MAY NEED TO CLEAN UP 
                                    ****BRANCHING AND RTS

* used for #<data>, need this to determine if we need word or long
SIZEMATS    JSR     MASK67          *Ensure size is on d6
            CMPI.B  #$02,D6
            BEQ     GETTLONG
            BRA     GETTWORD
ENDREGEXT   RTS      
            
GETTLONG    MOVE.W  #$0008,D1
            MOVE.W  #$0001,D0
            MOVE.W  A2,D2
            ADDA.L  #$2,A2  
            *BRA     HEX2STRING
            TRAP    #15
            
GETTWORD    MOVE.W  #$0008,D1
            MOVE.W  #$0001,D0
            MOVE.W  A2,D2
            ADDA.L  #$2,A2
            *BRA     HEX2STRING
            TRAP    #15
            BRA     ENDREGEXT
     
* Put variables and constants here

opCOMMA     DC.B    ','
opOPAR      DC.B    '('
opCPAR      DC.B    ')'
opALTR      DC.B    'A'
opDLTR      DC.B    'D'
opPLUS      DC.B    '+'
opMINUS     DC.B    '-'
opSLASH     DC.B    '/'
opCASH      DC.B    '$'
opHASH      DC.B    '#'

    
        

            END    START        ; last line of source


