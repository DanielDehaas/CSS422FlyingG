*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                 

*constants etc...
cash    EQU     $24
comma   EQU     $2C
CR      EQU     $0D
LF      EQU     $0A

* Put program code here

    
*//////////////////// <EA> Subroutines /////////////////////

************************************************************
* EASUBI will be called when the first two digits of       *
* instruction are equal to $04                             *
* This subroutine will extract the ea mode information     *
* precondition - msb == $0 and second digit == $4          *
* postcondition - instruction binary on D4,all relevant    *
*               instruction code printed, d6 = size, d7=ea *
************************************************************
***PSEUDO CODE
***         GET LENGTH, STORE ON D6 TO DETERMINE WHETHER TO TAKE TRAILING WORD OR LONG
***         PUSH #$ TO BUFFER, PUSH TRAILING WORD OR LONG TO BUFFER WITH COMMA
***         GET OPMODE, PUSH TO BUFFER, GET REGISTER/DIR ADDRESS PUSH TO BUFFER
***         END BY INCLUDING PARENTHESIS AND + IF NECESSARY
EASUBI  MOVEM.W D4,-(SP)            * BACKUP D4
        LEA     opHash,(A1)         * prepare to print '#$'
        MOVE.W  #$0001,D0
        MOVE.W  #$0002,D1           * two bytes
        TRAP    #15
        CLR     D5                  * zero out d5 and d6
        CLR     D6
        MOVE.B  D4,D5               * get last 8 bits from opcode
        JSR     GET67B              * get size, move size to D6
        CLR     D5                  
        MOVE.B  D4,D5               
        CMPI.B  #$01,D6             
        BLE     GETTWRD             * get trailing word, increment (A2)
        CMPI.B  #$02,D6
        BEQ     GETLNG              * get trailing Long, increment (A2)
        LEA     opComa,(A1)
        MOVE.W  #$0001,D0  
        JSR     GET345              * get opmode, store in d7
        CLR     D5
        MOVE.B  D4,D5               
        JSR     GET012              * get register number
        CMPI.B  #$02,D7
        BEQ     putPar
        CMPI.B  #$03,D7
        BEQ     postInc
        CMPI.B  #$04,d7
        BEQ     putPar
        MOVEM.W (SP)+,D4                
ENDSUBI RTS
        
        
GETTWRD **CONVERT (A2) TO STRING
        MOVE.W  #$0001,D0
        MOVE.W  (A2)+,(A1)
        MOVE.W  #$0004,D1
        TRAP    #15
        RTS

GETTLNG **CONVERT (A2) TO STRING
        MOVE.W  #$0001,D0
        MOVE.L  (A2)+,(A1)
        MOVE.W  #$0008,D1
        TRAP    #15
        RTS

postInc LEA     opPlus,(A1)
        MOVE.W  #$0002,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS

putPar  LEA     opCPar,(A1)
        MOVE.W  #$0001,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS
        



*EASUBI  MOVEM.W D4,-(SP)    *BACKUP D4
*        CLR     D5          *CLEAR D5 before use
*        CLR     D6          *CLEAR D6 for size
*        MOVE.B  D4,D5       *MOVE D4 TO D5 for use
*        JSR     GET67B      *GETS size from bits 67
*        MOVE.B  D5,D6       *store size at D6
*        CLR     D5
*        JSR     GET_IM
*        MOVE.B  D4,D5
*        JSR     GET345      *gets ea mode from 345
*        MOVE.B  D4,D5
*        JSR     GET012      *gets dest. from 012
*        MOVE.B  D6,D5       *moves size back to D5 for next SR
*        JSR     GET_IM      *gets immediate value using size
*        MOVEM.W (SP)+,D4    *Restore data to D4
*        RTS
*

************************************************************
* Assembler syntax ADDI.S <DATA>,<EA>                      *
* EAADDI will be called when the first two digits of       *
* instruction are equal to $06                             *
* This subroutine will extract the ea mode information     *
* precondition - msb == $0 and second digit == $6          *
* postcondition - instruction binary on D4, all relevant   *
*               instruction code pushed to buffer          *
************************************************************
*EAADDI  MOVEM.W D4,-(SP)    *BACKUP D4
*        CLR     D5          *CLEAR D5 before use 
*        CLR     D6          *CLEAR D6 for size  
*        MOVE.B  D4,D5       *move D4 to D5 for use
*        JSR     GET67B      *gets size from 67
*        CLR     D5
*        MOVE.B  D4,D5
*        JSR     GET345      *gets ea mode from 345
*        MOVE.B  D4,D5
*        JSR     GET012      *gets dest. from 012
*        MOVE.B  D6,D5       *moves size back to D5 for next SR
*        JSR     GET_IM      *gets immediate value using size
*        MOVE.W  (SP)+,D4    *Restore data to D4
*        RTS
EAADDI  MOVEM.W D4,-(SP)            * BACKUP D4
        LEA     opHash,(A1)         * prepare to print '#$'
        MOVE.W  #$0001,D0
        MOVE.W  #$0002,D1           * two bytes
        TRAP    #15
        CLR     D5                  * zero out d5 and d6
        CLR     D6
        MOVE.B  D4,D5               * get last 8 bits from opcode
        JSR     GET67B              * get size, move size to D6
        CLR     D5                  
        MOVE.B  D4,D5               
        CMPI.B  #$01,D6             
        BLE     GETTWRD             * get trailing word, increment (A2)
        CMPI.B  #$02,D6
        BEQ     GETLNG              * get trailing Long, increment (A2)
        LEA     opComa,(A1)
        MOVE.W  #$0001,D0  
        JSR     GET345              * get opmode, store in d7
        CLR     D5
        MOVE.B  D4,D5               
        JSR     GET012              * get register number
        CMPI.B  #$02,D7
        BEQ     putPar
        CMPI.B  #$03,D7
        BEQ     postInc
        CMPI.B  #$04,d7
        BEQ     putPar
        MOVEM.W (SP)+,D4                
ENDADDI RTS
*********************************************************
* GET67B gets the size from the 6 and 7 bits.           *
* precondition - opcode format stores size in bits 67   *
*********************************************************

GET67B  ROL.B   #2,D5       *Rotate register
        ANDI.B  #3,D5       *Mask BYTE data
        CMPI.B  #$03,D5       
        BEQ     ERR67B      *TODO: determine if this should be a sr or if this should trigger 'data' message
        CMPI.B  #0,D5
        BEQ     SIZEB       *TODO: create subroutine to add '.B' to buffer - I/O SR
        CMPI.B  #1,D5
        BEQ     SIZEW       *TODO: create subroutine to add '.W' to buffer - I/O SR
        CMPI.B  #2,D5
        BEQ     SIZEL       *TODO: create subroutine to add '.L' to buffer - I/O SR
        BRA     DONE
ERR67B  JSR     ERRSIZE
DONE    RTS                 

SIZEB   MOVE.B  #0,D6
        RTS
SIZEW   MOVE.B  #1,D6
        RTS
SIZEL   MOVE.B  #2,D6
        RTS
        
        
ERRSIZE * PRINT DATA MESSAGE *
        RTS
*******************************************
* GET_IM USES THE SIZE STORED ON D6 TO    *
* DETERMINE HOW MANY HEX BITS TO GET      *
* FOLLOWING THE INSTRUCTION CODE          *
* PRECONDITION - instruction is directly  *
* followed by a 2, 4, or 8 hex bit value. *
* D5 contains 0, 1, or 2 to signify byte, *
* word, or long.                          *
* POSTCONDITION - immediate value is put  *
* on D5 and mem location pointer is   *
* incremented by 2, 4, or 8.              *
*******************************************
*GET_IM  CMPI.B  #0,D6       
*        BEQ     GETBYTE
*        CMPI.B  #1,D6
*        BEQ     GETWORD
*        CMPI.B  #2,D6
*        BEQ     GETLONG
*        BRA     ERRSIZE             *TODO: determine if this should be a sr or if this should trigger 'data' message
*        
*GETBYTE MOVE.W  (A2)+,D5            *this may be superfluous - i believe trailing instructions are always words
*        *PUSH D5 TO BUFFER          *MAY need to manually increment (A2), need to convert A2 to STRING first
*        RTS   
*GETWORD MOVE.W  (A2)+,D5
*        *PUSH D5 TO BUFFER
*        RTS
*GETLONG MOVE.L  (A2)+,D5
*        *PUSH D5 TO BUFFER
*        RTS
*        
*******************************************
*  GET345 gets the opmode from bits 345   *
* precondition - instruction code format  * 
*    stores size in bits 345              *
*******************************************
GET345  ASL.B   #2,D5
        ASR.B   #5,D5       *isolate 345 bits to 012
        ANDI.B  #$07,D5     *mask with 0111
        CMPI.B  #7,D5       *CHECK IF == 7
        BEQ     REGEXT      *Will need to get extension to determine trailing instruction code
        CMPI.B  #5,D5       *value must be less than 5 or 7
        BGE     BADMODE     *TODO: determine what to do here.
        CMPI.B  #4,D5
        BEQ     RINPDEC     *should probably determine better name for register indirect predecrement -(An)
        CMPI.B  #3,D5
        BEQ     RINPINC     *again, (An)+ deserves a better name
        CMPI.B  #2,D5       
        BEQ     RINAN       *AGAIN, (An)
        CMPI.B  #1,D5
        BEQ     DIRADD      *An
        CMPI.B  #0,D5
        BEQ     DIRDATR     *Dn
        RTS

*** THIS directive pushes '-(A' to buffer        
RINPDEC LEA     opIPDC,(A1)
        MOVE.W  #$0001,D0
        TRAP    #15
        MOVE.B  #$04,D7
        RTS

*** This directive pushes '(A' to buffer
RINPINC LEA     opIAdd,(A1)
        MOVE.W  #$0001,D0
        TRAP    #15
        MOVE.B  #$03,D7
        RTS

*** This directive pushes '(A' to buffer
RINAN   LEA     opIAdd,(A1)
        MOVE.W  #$0001,D0
        TRAP    #15
        MOVE.B  #$02,D7
        RTS

*** this directive pushes 'A' to buffer
DIRADD  LEA     opALtr,(A1)
        MOVE.W  #$0001,D0
        TRAP    #15
        MOVE.B  #$01,D7
        RTS

*** this directive pushes 'D' to buffer
DIRDATR LEA opDLtr,(A1)
        MOVE.W  #$0001,D0
        TRAP    #15
        MOVE.B  #$00,D7
        RTS
        
*** WILL NEED TO REFACTOR THIS SECTION TO ACCOUNT
*** FOR #<DATA>
*************************************************
*Absolute and immediate addressing modes require*
*checking the register for extension            *
*000 is absolute short                          *
*001 is absolute long                           *
*opcode will be followed by IMMEDIATE value and *
*address                                        *
*************************************************
REGEXT  LEA     opCash,(A1) *READIES TO PRINT $
        MOVE.W  #$0001,D0
        TRAP    #15
        CLR     D5
        MOVE.B  D4,D5
        ASL.B   #5,D5
        ASR.B   #5,D5       *Isolate bits 012 
        CMPI.B  #1,D5
        BGT     BADREG      *DETERMINE what to do here
        BEQ     GETTLNG
        BLT     GETTWRD
        RTS
        
**************************************************************
* GET012 is used to get the register number held on bits 012 *
* PRECONDITION - D5 will contain the binary instruction for *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - D5 will contain REGISTER NUMBER            *
**************************************************************
GET012  ANDI.W  #$07,D5
        ADDI.B  #$30,D5     *CONVERT D5 TO ASCII
        MOVE.W  #$0001,D1
        MOVE.W  #$0001,D0
        MOVE.B  D5,(A1)
        TRAP    #15
        RTS
        
**************************************************************
* EAJSR will be called when opcode == %0100111010xxxxxx      *
* PRECONDITION - D4 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - will print ea and update (A2) as needed    *
**************************************************************
*** BITS 345 CAN ONLY BE 010 OR 111
*** 
*** PSEUDO - BACKUP
EAJSR   MOVEM.W D4,-(SP)            * BACKUP D4
        CLR     D5
        CLR     D7
        JSR     GET345              * PUT EA MODE ON D7
        CMPI.B  #$02,D7
        BEQ     addPar
        CLR     D5
        MOVE.B  D4,D5
        JSR     GET012
        MOVEM.W (SP)+,D4
ENDJSR  RTS
        
addPar  LEA     opCPar,(A1)
        MOVE.W  #$0001,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS
        
**************************************************************
* EALEA will be called when opcode == %0100XXX111xxxxxx      *
* PRECONDITION - D4 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - will print ea and update (A2) as needed    *
**************************************************************    

**************************************************************
* EAMFCCR WILL be called when opcode == %0100001011xxxxxx    *
* PRECONDITION - D4 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - will print ea and update (A2) as needed    *
**************************************************************
EAMFCCR MOVEM.W D4,-(SP)            * BACKUP D4
        CLR     D5
        CLR     D7
        JSR     GET345              * PUT EA MODE ON D7
        CLR     D5
        MOVE.B  D4,D5
        JSR     GET012
        CMPI.B  #$02,D7
        BEQ     MFCPar
        CMPI.B  #$03,D7
        BEQ     MFCpInc
        CMPI.B  #$04,D7
        BEQ     MFCPar
        MOVEM.W (SP)+,D4
ENDMFCR RTS
        
addPar  LEA     opCPar,(A1)
        MOVE.W  #$0001,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS
        
MFCpInc LEA     opPlus,(A1)
        MOVE.W  #$0002,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS

MFCPar  LEA     opCPar,(A1)
        MOVE.W  #$0001,D1
        MOVE.W  #$0001,D0
        TRAP    #15
        RTS


**************************************************************
* EAMTCCR WILL be called when opcode == %0100010011xxxxxx    *
* ASSEMBLER SYNTAX = MOVE   <EA>,CCR                         *
* PRECONDITION - D4 will contain the binary instruction for  *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - will print ea and update (A2) as needed    *
**************************************************************
*EAMTCCR     MOVEM.W D4,-(SP)
*            CLR     D5
*            CLR     D7
          

*///////////////////////////////////////////////////////////

* Put variables and constants here
   
opADDI  DC.W    'ADDI'
opSUBI  DC.W    'SUBI'
sizeB   DC.B    '.B'
sizeW   DC.B    '.W'
sizeL   DC.B    '.L'
msgDAT  DC.W    'DATA'
opComa  DC.B    ','
opOPar  DC.B    '('
opCPar  DC.B    ')'
opPlus  DC.B    ')+'
opMin   DC.B    '-'
opCash  DC.B    '$'
opHash  DC.B    '#$'
opALtr  DC.B    'A'
opDLtr  DC.B    '(D'
opSlsh  DC.B    '/'
opIPDC  DC.B    '-(A'
opIAdd  DC.B    '(A'
opCCR   DC.B    'CCR'



    END    START        ; last line of source


