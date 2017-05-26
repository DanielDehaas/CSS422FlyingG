*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
            MOVE.W  #$06BF,D4
            MOVEA.L #$0000A000,A2
            MOVE.L  #$12345678,(A2)
            
*****************************************************************
* Specific ea code sections. handle nuanced behavior for each   *
* opcode which needs it                                         *
*****************************************************************         
EAADDI      LEA     opHASH,A1
            MOVE.W  #$0001,D1       *only print 1 byte
            MOVE.W  #$0001,D0       *set trap condition
            TRAP    #15             *print #
*            LEA     opCASH,A1       
*            TRAP    #15
            JSR     SIZEMATS        *GET immediate operand
            LEA     opCOMMA,A1      
            MOVE.W  #$0001,D0
            TRAP    #15           
ENDIMATH    JSR     EAFORM1
            
EASUBI      JMP     EAADDI

            
* Put program code here
*****************************************************************
* this section works for all opcodes whose format contains      *
* the eamode at bits 345 and ea reg at 012. size may or may not *
* be stored at 78.                                              *
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
GETREG      ANDI.W  #$0007,D5
            MOVE.W  #$0003,D0
            MOVE.W  D5,D1
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
            LSL.B   #$03,D5

END345      RTS

*************************************************************
* MASK78 masks word on D5 and puts result on D6             *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 78              *
*************************************************************
MASK78      CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$00C0,D5       *mask 0000000011000000
            MOVE.W  D5,D6
END78       RTS

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
            CMPI.W  #$0004,D7
            BEQ     SIZEMATS
            CMPI.W  #$0001,D7
            BEQ     GETTLONG
            BRA     GETTWORD        ****MAY NEED TO CLEAN UP 
                                    ****BRANCHING AND RTS

* used for #<data>, need this to determine if we need word or long
SIZEMATS    JSR     MASK78          *Ensure size is on d6
            CMPI.B  #$02,D6
            BEQ     GETTLONG
            BRA     GETTWORD
ENDREGEXT   RTS      
            
GETTLONG    MOVE.W  #$0002,D1
            MOVE.W  #$0001,D0
            MOVE.W  (A2)+,A1
            TRAP    #15
            
GETTWORD    MOVE.W  #$0002,D1
            MOVE.W  #$0001,D0
            MOVE.W  (A2)+,A1
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
