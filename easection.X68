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

* EAADDI will be called when the first two digits of
* instruction are equal to $06
* This subroutine will extract the ea mode information
* precondition - msb == $0 and second digit == $6
* postcondition - instruction binary on D4
EAADDI  MOVE.W  D4,-(SP)    *BACKUP D4
        CLR.B   D5          *CLEAR D5 before use   
        MOVE.B  D4,D5       *move D4 to D5 for use
        JSR     GET67B      *gets size from 67
        MOVE.B  D5,D6       *store size at D6
        MOVE.B  D4,D5
        JSR     GET345      *gets ea mode from 345
        MOVE.B  D4,D5
        JSR     GET012      *gets dest. from 012
        MOVE.B  D6,D5       *moves size back to D5 for next SR
        JSR     GET_IM      *gets immediate value using size
        MOVE.W  (SP)+,D4    *Restore data to D4
        RTS

* GET67B gets the size from the 6 and 7 bits. 
* precondition - opcode format stores size in bits 67

GET67B  ROL.B   #2,D5       *Rotate register
        ANDI.B  #3,D5       *Mask BYTE data
        CMPI.B  #3,D5       
        BEQ     ERRSIZE     *TODO: determine if this should be a sr or if this should trigger 'data' message
        CMPI.B  #0,D5
        BEQ     SIZEB       *TODO: create subroutine to add '.B' to buffer
        CMPI.B  #1,D5
        BEQ     SIZEW       *TODO: create subroutine to add '.W' to buffer
        CMPI.B  #2,D5
        BEQ     SIZEL       *TODO: create subroutine to add '.L' to buffer
        RTS

*******************************************
* GET_IM USES THE SIZE STORED ON D5 TO    *
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
GET_IM  CMPI.B  #0,D5       
        BEQ     GETBYTE
        CMPI.B  #1,D5
        BEQ     GETWORD
        CMPI.B  #2,D5
        BEQ     GETLONG
        
GETBYTE MOVE.B  (A2)+,D5            *this may be superfluous - i believe trailing instructions are always words
        *PUSH D5 TO BUFFER
GETWORD MOVE.W  (A2)+,D5
        *PUSH D5 TO BUFFER
GETLONG MOVE.L  (A2)+,D5
        *PUSH D5 TO BUFFER
        RTS
        
*******************************************
*  GET345 gets the opmode from bits 345   *
* precondition - instruction code format  * 
*    stores size in bits 345              *
*******************************************
GET345  ASL.B   #2,D5
        ASR.B   #5,D5       *isolate 345 bits to 012
        ANDI.B  #7,D5       *mask with 0111
        CMPI.B  #7,D5       *CHECK IF == 7
        BEQ     REGEXT
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
        
*Absolute and immediate addressing modes require
*checking the register for extension
*000 is absolute short
*001 is absolute long
REGEXT  MOVE.B  D4,D5
        ASL.B   #5,D5
        ASR.B   #5,D5       *Isolate bits 012 
        CMPI.B  #1,D5
        BGT     BADREG      *DETERMINE what to do here
        BEQ     LONGADD
        BLT     WORDADD
*retrieves
WORDADD MOVE.W  (A2)+,D5
        *PUSH D5 TO BUFFER
LONGADD MOVE.L  (A2)+,D5
        *PUSH D5 TO BUFFER
        RTS
        
**************************************************************
* GET012 is used to get the register number held on bits 012 *
* PRECONDITION - D5 will contain the binary instructtion for *
* an opcode whose format contains eamode on bits 345 and reg *
* on 012.                                                    *
* POSTCONDITION - D5 will contain REGISTER NUMBER            *
**************************************************************
GET012  ANDI.W  #7,D5
        ADDI.B  #$30,D5     *CONVERT D5 TO ASCII
        *PUSH D5 TO BUFFER

        

*///////////////////////////////////////////////////////////

* Put variables and constants here
   
opADDI  DC.W    'ADDI'
opSUBI  DC.W    'SUBI'
sizeB   DC.B    '.B'
sizeW   DC.B    '.W'
sizeL   DC.B    '.L'
msgDAT  DC.W    'DATA'

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
