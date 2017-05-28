*-----------------------------------------------------------
* Title      :Final Project
* Written by :Flying Giraffe Squad
* Date       :04/26/17
* Description:Disassembler for the 68k
*-----------------------------------------------------------

*------------------ Register Assignments -------------------
* A0 = TRAP RESERVED
* A1 = TRAP RESERVED
* A2 = Start Address
* A3 = End Address
* A4 = Safe Output 'Pointer'
*
* D0 = TRAP RESERVED
* D1 = TRAP RESERVED
* D2 = PROC VAR IN I/O
* D3 = PROC VAR IN OPCODE
* D4 = PROC VAR IN OPCODE
*------------------------------------------------------------

    ORG    $1000
START:      *print welcome message
            MOVE.W  #14,D0
            LEA     WELCOME,A1
            TRAP    #15
            
            *ask start address
ADDRINP1    LEA     ENTRSTRT,A1
            TRAP    #15
            
            *receive input to A1
            MOVEA.W #SafeStrA1,A1
            MOVE.W  #2,D0
            TRAP    #15
            
            *check for $ symbol
            CMP.B   #$24,(SafeStrA1)
            BEQ     VALIDINP1
            *print error
            MOVE.W  #14,D0
            LEA     ERRNOTHEX,A1
            TRAP    #15
            *JMP to input
            JMP     ADDRINP1
VALIDINP1   JSR     STRING2HEX
            *move start address to addr2
            MOVEA.L  D2,A2
            
            *ASSUMING VALID INPUT
            
            *ask end address
ADDRINP2    MOVE.W  #14,D0
            LEA     ENTREND,A1
            TRAP    #15
            
            *receive input to A1
            MOVEA.W #SafeStrA1,A1
            MOVE.W  #2,D0
            TRAP    #15
            
            *check for $ symbol
            CMP.B   #$24,(SafeStrA1)
            BEQ     VALIDINP2
            *print error
            MOVE.W  #14,D0
            LEA     ERRNOTHEX,A1
            TRAP    #15
            *JMP to input
            JMP     ADDRINP2
VALIDINP2   JSR     STRING2HEX
            *move end address to addr3
            MOVEA.L  D2,A3
            
            *ASSUMING VALID INPUT
            
            
************* O/I PHASE - DONE ***************
************ BEGIN OPCODE PHASE **************
            
            
            * Set loop counter = 0
            MOVE.B  #$00,(LoopCounter)
            
            * reset to default output
            JSR     OUTPUTRESET
            JSR     ADDRRESET
            
            *giant switch statement for first hex digit of opcode
            *moves most significant digit from D2 to LSD in D3
            SUBA.W  #2,A2
            CLR.L   D3
OPCLOOP1    CMP.B   #31,(LoopCounter)
            BNE     CONTLOOP
            
            * else, pause
            JSR     PAUSEOUTPUT
            
CONTLOOP    ADD.B   #1,(LoopCounter)
            ADDA.W  #2,A2
            MOVE.W  (A2),D4
            CLR.L   D3
            MOVE.W  #$F000,D3
            AND.W   D4,D3
            LSR.W   #8,D3
            LSR.W   #4,D3
            *load current word to D4
            MOVE.W  (A2),D4
            
            JSR     PREPMASKCHK *prepares D5 for mask checking
            
            
            
            *************************
            *  PRINT ADDRESS HERE!  *
            *************************
            
            *prepare for Trap task 14
            MOVE.W  #14,D0
            
            *switch
            CMP.B   #$0,D3
            BEQ     LBL0000
            CMP.B   #$1,D3
            BEQ     LBL0001
            CMP.B   #$2,D3
            BEQ     LBL0010
            CMP.B   #$3,D3
            BEQ     LBL0011
            CMP.B   #$4,D3
            BEQ     LBL0100
            CMP.B   #$5,D3
            BEQ     LBL0101
            CMP.B   #$6,D3
            BEQ     LBL0110
            CMP.B   #$7,D3
            BEQ     LBL0111
            CMP.B   #$8,D3
            BEQ     LBL1000
            CMP.B   #$9,D3
            BEQ     LBL1001
            CMP.B   #$A,D3
            BEQ     LBL1010
            CMP.B   #$B,D3
            BEQ     LBL1011
            CMP.B   #$C,D3
            BEQ     LBL1100
            CMP.B   #$D,D3
            BEQ     LBL1101
            CMP.B   #$E,D3
            BEQ     LBL1110
            CMP.B   #$F,D3
            BEQ     LBL1111
            
LBL0000     *********** 0000 **********
            CLR.L   D3
            * MASK CHECKING *
            JSR     MASK345
            CMP.B   #$01,D5
            BEQ     DATA_0000
            CMP.B   #$05,D5
            BEQ     DATA_0000
            CMP.B   #$06,D5
            BEQ     DATA_0000
            
            JSR     MASK67
            CMP.B   #$03,D5
            BEQ     DATA_0000
            
            * OPCODE CHECKING *
            * test %xxxx XXXX xxxx xxxx
            MOVE.W  #$0F00,D3
            AND.W   D4,D3
            * == %xxxx 0110 xxxx xxxx
            CMP.W   #$0600,D3
            BEQ     ADDI0000
            * == %xxxx 0100 xxxx xxxx
            CMP.W   #$0400,D3
            BEQ     SUBI0000
            * else, INVALID
            JMP     DATA_0000
            
            
ADDI0000    ****** ADDI *****
            LEA     ADDI,A1
            JSR     OUTPUTSTR
            JMP     SKP1_0000  
            ***** /ADDI *****          
            
SUBI0000    ****** SUBI *****
            LEA     SUBI,A1
            JSR     OUTPUTSTR
            JMP     SKP1_0000
            ***** /SUBI *****
            
SKP1_0000   * ADDI and SUBI share size code
            * switch %0000 0000 XX00 0000
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT0000B   * byte
            CMP.B   #$00,D3
            BNE     PRNT0000W
            LEA     B,A1
            JSR     OUTPUTSTR
PRNT0000W   * word
            CMP.B   #$40,D3
            BNE     PRNT0000L
            LEA     W,A1
            JSR     OUTPUTSTR
PRNT0000L   * long
            CMP.B   #$80,D3
            BNE     PRNT0000INV
            LEA     L,A1
            JSR     OUTPUTSTR
PRNT0000INV * invalid
            CMP.B   #$C0,D3
            BEQ     DATA_0000
            JMP     DONE_0000
            

DONE_0000   JSR     OUTPUTPRNT
            * <<INSERT EA CODE>> *
            JMP     OPCCONT1
            
DATA_0000   JMP     OPCDATA
            ********** /0000 **********
            
            
            
LBL0001     *********** 0001 **********
            CLR.L   D3
            ***** MOVE.B ****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$05,D5
            BEQ     DATA_0001
            CMP.B   #$06,D5
            BEQ     DATA_0001
            
            JSR     MASK678 * dest mode *
            CMP.B   #$01,D5
            BEQ     DATA_0001
            CMP.B   #$05,D5
            BEQ     DATA_0001
            CMP.B   #$06,D5
            BEQ     DATA_0001
            CMP.B   #$07,D5
            BNE     SKP1_0001
            
            JSR     MASK9AB * dest reg * (only if dest mode == 7)
            CMP.B   #$04,D5
            BEQ     DATA_0001
            
SKP1_0001   *** CONFIRMED ***
            LEA     MOVEB,A1
            JSR     OUTPUTSTR
            JMP     DONE_0001
            **** /MOVE.B ****
            
            
DONE_0001   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0001   JMP     OPCDATA
            ********** /0001 **********
            
            
            
LBL0010     *********** 0010 **********
            CLR.L   D3
            

            
            * test %xxxx xxxX XXxx xxxx
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
            * == %xxxx xxx0 01xx xxxx
            CMP.W   #$0040,D3
            BEQ     MOVEAL0010
MOVEL0010   ***** MOVE.L ****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$05,D5
            BEQ     DATA_0010
            CMP.B   #$06,D5
            BEQ     DATA_0010
            
            JSR     MASK678 * dest mode *
            CMP.B   #$01,D5
            BEQ     DATA_0010
            CMP.B   #$05,D5
            BEQ     DATA_0010
            CMP.B   #$06,D5
            BEQ     DATA_0010
            CMP.B   #$07,D5
            BNE     SKP1_0010
            
            JSR     MASK9AB * dest reg * (only if dest mode == 7)
            CMP.B   #$04,D5
            BEQ     DATA_0010
SKP1_0010   *** CONFIRMED ***
            LEA     MOVEL,A1
            JSR     OUTPUTSTR
            JMP     DONE_0010
            **** /MOVE.L ****
            
MOVEAL0010  **** MOVEA.L ****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$05,D5
            BEQ     DATA_0010
            CMP.B   #$06,D5
            BEQ     DATA_0010
            
            *** CONFIRMED ***
            LEA     MOVEAL,A1
            JSR     OUTPUTSTR
            JMP     DONE_0010
            *** /MOVEA.L ****
            

DONE_0010   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0010   JMP     OPCDATA
            ********** /0010 **********
            
            
            
LBL0011     *********** 0011 **********
            CLR.L   D3
            * test %xxxx xxxX XXxx xxxx
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
            * == %xxxx xxx0 01xx xxxx
            CMP.W   #$0040,D3
            BEQ     MOVEAW0011
MOVEW0011   ***** MOVE.W ****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$05,D5
            BEQ     DATA_0011
            CMP.B   #$06,D5
            BEQ     DATA_0011
            
            JSR     MASK678 * dest mode *
            CMP.B   #$01,D5
            BEQ     DATA_0011
            CMP.B   #$05,D5
            BEQ     DATA_0011
            CMP.B   #$06,D5
            BEQ     DATA_0011
            CMP.B   #$07,D5
            BNE     SKP1_0011
            
            JSR     MASK9AB * dest reg * (only if dest mode == 7)
            CMP.B   #$04,D5
            BEQ     DATA_0011
SKP1_0011   *** CONFIRMED ***
            LEA     MOVEW,A1
            JSR     OUTPUTSTR
            JMP     DONE_0011
            **** /MOVE.W ****
            
MOVEAW0011  **** MOVEA.W ****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$05,D5
            BEQ     DATA_0011
            CMP.B   #$06,D5
            BEQ     DATA_0011
            
            *** CONFIRMED ***
            LEA     MOVEAW,A1
            JSR     OUTPUTSTR
            JMP     DONE_0011
            *** /MOVEA.W ****
            
            
DONE_0011   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0011   JMP     OPCDATA
            ********** /0011 **********
            
            

LBL0100     *********** 0100 **********
            CLR.L   D3
            * test %xxxx XXXX XXxx xxxx
            MOVE.L  #$0FC0,D3
            AND.L   D4,D3
            * == %xxxx 1110 10xx xxxx
            CMP.W   #$0E80,D3
            BNE     SKP1_0100
            ****** JSR ******
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$02,D5
            BEQ     SKP1_JSR
            CMP.B   #$07,D5
            BNE     DATA_0100
            
            JSR     MASK012 * source reg *
            CMP.B   #$00,D5
            BEQ     SKP1_JSR
            CMP.B   #$01,D5
            BEQ     SKP1_JSR
            JMP     DATA_0100
            
SKP1_JSR    *** CONFIRMED ***
            LEA     JSR,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            ***** /JSR ******
            
SKP1_0100   * test %xxxx xxxX XXxx xxxx
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
            * == %xxxx xxx0 01xx xxxx
            CMP.W   #$01C0,D3
            BNE     SKP2_0100
            ****** LEA ******
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     SKP1_LEA
            CMP.B   #$02,D5
            BEQ     SKP1_LEA
            CMP.B   #$07,D5
            BNE     DATA_0100
            
            JSR     MASK012 * source reg *
            CMP.B   #$00,D5
            BEQ     SKP1_LEA
            CMP.B   #$01,D5
            BEQ     SKP1_LEA
            JMP     DATA_0100
SKP1_LEA    *** CONFIRMED ***
            LEA     LEA,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            ***** /LEA ******
            
SKP2_0100   CMP.W   #$4E71,D4
            BNE     SKP3_0100
            ****** NOP ******
            *** CONFIRMED ***
            LEA     NOP,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            ***** /NOP ******
            
SKP3_0100   CMP.W   #$4E75,D4
            BNE     SKP4_0100
            ****** RTS ******
            *** CONFIRMED ***
            LEA     RTS,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            ******/RTS ******
            
SKP4_0100   * test %xxxx XXXX XXxx xxxx
            MOVE.W  #$0FC0,D3
            AND.W   D4,D3
            *   == %xxxx 0010 11xx xxxx
            CMP.W   #$02C0,D3
            BNE     SKP5_0100
            ** MOVEFROMCCR **
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     DATA_0100
            CMP.B   #$07,D5
            BNE     MOVECCR_SKP
            
            JSR     MASK012 * source reg; if mode 111 *
            CMP.B   #$00,D5
            BEQ     MOVECCR_SKP
            CMP.B   #$01,D5
            BEQ     MOVECCR_SKP
            JMP     DATA_0100

MOVECCR_SKP *** CONFIRMED ***
            LEA     MOVEFROMCCR,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            * /MOVEFROMCCR **

SKP5_0100   * test %xxxx XxXX Xxxx xxxx
            MOVE.W  #$0B80,D3
            AND.W   D4,D3
            *   == %xxxx 1x00 1xxx xxxx
            CMP.W   #$0880,D3
            BNE     SKP6_0100
            ***** MOVEM *****
            * MASK CHECKING *
            MOVE.W  #$0400,D5
            AND.W   D4,D5
            CMP.W   #$0400,D5
            BEQ     SKP1_MOVEM
            
            * Reg to Memory *
            JSR     MASK345 * source mode *
            CMP.W   #$03,D5
            BEQ     DATA_0100
            JMP     SKP2_MOVEM
            
SKP1_MOVEM  * Memory to Reg *
            JSR     MASK345 * source mode *
            CMP.W   #$04,D5
            BEQ     DATA_0100
            JMP     SKP2_MOVEM
            
SKP2_MOVEM  CMP.B   #$00,D5
            BEQ     DATA_0100
            CMP.B   #$01,D5
            BEQ     DATA_0100
            CMP.B   #$05,D5
            BEQ     DATA_0100
            CMP.B   #$06,D5
            BEQ     DATA_0100
            CMP.B   #$07,D5
            BNE     SKP3_MOVEM
            
            JSR     MASK012 * source reg; if mode 111 *
            CMP.B   #$00,D5
            BEQ     SKP3_MOVEM
            CMP.B   #$01,D5
            BEQ     SKP3_MOVEM
            JMP     DATA_0100
SKP3_MOVEM  *** CONFIRMED ***
            LEA     MOVEM,A1
            JSR     OUTPUTSTR
            * test %xxxx xxxX xxxx xxxx
            MOVE.W  #$0100,D3
            AND.W   D4,D3
PRNT0100W   * word
            CMP.W   #$0000,D3
            BNE     PRNT0100L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_0101
PRNT0100L   * long
            CMP.W   #$0100,D3
            BNE     DATA_0100
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            **** /MOVEM *****

SKP6_0100   * test %xxxx XXXX XXxx xxxx
            MOVE.W  #$0FC0,D3
            AND.W   D4,D3
            *  == %xxxx 0100 11xx xxxx
            CMP.W   #$04C0,D3
            BNE     SKP7_0100
            *** MOVETOCCR ***
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     DATA_0100
            CMP.B   #$05,D5
            BEQ     DATA_0100
            CMP.B   #$06,D5
            BEQ     DATA_0100
            *** CONFIRMED ***
            LEA     MOVETOCCR,A1
            JSR     OUTPUTSTR
            JSR     OUTPUTPRNT
            * <ea> OUTPUT HERE
            LEA     TOCCR,A1
            JSR     OUTPUTSTR
            LEA     SafeOutStr,A1 * ALTERNATIVE TO JSR OUTPUTPRNT (to avoid address print)
            TRAP    #15
            JSR     OUTPUTRESET
            JMP     OPCCONT1
            ** /MOVETOCCR ***

SKP7_0100   * test %xxxx XXXX XXxx xxxx
            MOVE.W  #$0FC0,D3
            AND.W   D4,D3
            *  == %xxxx 0110 11xx xxxx
            CMP.W   #$00C0,D3
            BNE     DATA_0100
            *** MOVEFROMSR **
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     DATA_0100
            CMP.B   #$05,D5
            BEQ     DATA_0100
            CMP.B   #$06,D5
            BEQ     DATA_0100
            CMP.B   #$07,D5
            BNE     MOVETOCCR_S
            
            JSR     MASK012 * source reg; if mode 111 *
            CMP.B   #$00,D5
            BEQ     MOVETOCCR_S
            CMP.B   #$01,D5
            BEQ     MOVETOCCR_S
            JMP     DATA_0100
MOVETOCCR_S *** CONFIRMED ***
            LEA     MOVEFROMSR,A1
            JSR     OUTPUTSTR
            JMP     DONE_0100
            ** /MOVEFROMSR **

DONE_0100   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0100   JMP     OPCDATA
            ********** /0100 **********



LBL0101     *********** 0101 **********
            CLR.L   D3
            ****** ADDQ *****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     DATA_0101
            CMP.B   #$05,D5
            BEQ     DATA_0101
            CMP.B   #$06,D5
            BEQ     DATA_0101
            CMP.B   #$07,D5
            BNE     SKP1_ADDQ
            
            JSR     MASK012 * source reg; if mode 111 *
            CMP.B   #$00,D5
            BEQ     SKP1_ADDQ
            CMP.B   #$01,D5
            BEQ     SKP1_ADDQ
            JMP     DATA_0101
SKP1_ADDQ   *** CONFIRMED ***
            LEA     ADDQ,A1
            JSR     OUTPUTSTR
            * == %xxxx xxx0 xxxx xxxx
            MOVE.W  #$0100,D3
            AND.W   D4,D3
            BNE     OPCDATA
            * switch %0000 0000 XX00 0000
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT0101B   * byte
            CMP.B   #$00,D3
            BNE     PRNT0101W
            LEA     B,A1
            JSR     OUTPUTSTR
            JMP     DONE_0101
PRNT0101W   * word
            CMP.B   #$40,D3
            BNE     PRNT0101L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_0101
PRNT0101L   * long
            CMP.B   #$80,D3
            BNE     DATA_0101
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_0101
            ***** /ADDQ *****
            
DONE_0101   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0101   JMP     OPCDATA
            ********** /0101 **********
            
            
            
LBL0110     *********** 0110 **********
            CLR.L   D3
            * test %xxxx XXXX xxxx xxxx
            MOVE.W  #$0F00,D3
            AND.W   D4,D3
            *   == %xxxx 0100 xxxx xxxx
            CMP.W   #$0400,D3
            BNE     SKP1_0110
            ****** BCC ******
            *** CONFIRMED ***
            LEA     BCC,A1
            JSR     OUTPUTSTR
            JMP     DONE_0110
            ***** /BCC ******
            
SKP1_0110   *   == %xxxx 1100 xxxx xxxx
            CMP.W   #$0C00,D3
            BNE     SKP2_0110
            ****** BGE ******
            *** CONFIRMED ***
            LEA     BGE,A1
            JSR     OUTPUTSTR
            JMP     DONE_0110
            ***** /BGE ******
            
SKP2_0110   *   == %xxxx 1101 xxxx xxxx
            CMP.W   #$0D00,D3
            BNE     SKP3_0110
            ****** BLT ******
            *** CONFIRMED ***
            LEA     BLT,A1
            JSR     OUTPUTSTR
            JMP     DONE_0110
            ***** /BLT ******
            
SKP3_0110   *   == %xxxx 0000 xxxx xxxx
            CMP.W   #$0000,D3
            BNE     DATA_0110
            ****** BRA ******
            *** CONFIRMED ***
            LEA     BRA,A1
            JSR     OUTPUTSTR
            JMP     DONE_0110
            ***** /BRA ******
            
DONE_0110   JSR     OUTPUTPRNT
            JMP     OPCCONT1
            
DATA_0110   JMP     OPCDATA
            ********** /0110 **********



LBL0111     *********** 0111 **********
            CLR.L   D3
            * test %xxxx xxxX xxxx xxxx
            MOVE.W  #$0100,D3
            AND.W   D4,D3
            *  == %xxxx xxx0 xxxx xxxx
            CMP.W   #$0000,D3
            BNE     DATA_0111
            ***** MOVEQ *****
            *** CONFIRMED ***
            LEA     MOVEQ,A1
            JSR     OUTPUTSTR
            JMP     DONE_0111
            **** /MOVEQ *****

DONE_0111   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_0111   JMP     OPCDATA
            ********** /0111 **********
            
            
            
LBL1000     *********** 1000 **********
            CLR.L   D3
            * test %xxxx xxxX XXxx xxxx
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
            *  == %xxxx xxx0 11xx xxxx
            CMP.W   #$00C0,D3
            BNE     SKP1_1000
            ****** DIVU *****
            * MASK CHECKING *
            JSR     MASK345 * source mode *
            CMP.B   #$01,D5
            BEQ     DATA_1000
            CMP.B   #$05,D5
            BEQ     DATA_1000
            CMP.B   #$06,D5
            BEQ     DATA_1000
            *** CONFIRMED ***
            LEA     DIVU,A1
            JSR     OUTPUTSTR
            JMP     DONE_1000
            ***** /DIVU *****
            
SKP1_1000   ******* OR ******
            LEA     OR,A1
            JSR     OUTPUTSTR
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT1000B   * byte
            CMP.B   #$00,D3
            BNE     PRNT1000W
            LEA     B,A1
            JSR     OUTPUTSTR
            JMP     DONE_1000
PRNT1000W   * word
            CMP.B   #$40,D3
            BNE     PRNT1000L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_1000
PRNT1000L   * long
            CMP.B   #$80,D3
            BNE     DATA_1000
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_1000
            ****** /OR ******


DONE_1000   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_1000   JMP     OPCDATA
            ********** /1000 **********



LBL1001     *********** 1001 **********
            CLR.L   D3
            ****** SUB ******
            LEA     SUB,A1
            JSR     OUTPUTSTR
            * switch %0000 000X XX00 0000
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
PRNT1001B   * byte
            CMP.B   #$00,D3
            BNE     PRNT1001W
            LEA     B,A1
            JSR     OUTPUTSTR
PRNT1001W   * word
            CMP.B   #$40,D3
            BNE     PRNT1001L
            LEA     W,A1
            JSR     OUTPUTSTR
PRNT1001L   * long
            CMP.B   #$80,D3
            BNE     PRNT1001INV
            LEA     L,A1
            JSR     OUTPUTSTR
PRNT1001INV * invalid
            CMP.B   #$C0,D3
            BEQ     DATA_1001
            JMP     DONE_1001
            ***** /SUB ******
            
            
DONE_1001   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_1001   JMP     OPCDATA
            ********** /1001 **********


            
LBL1010     *********** 1010 **********
            **** INVALID ****
            JMP     OPCDATA
            ********** /1010 **********
            
            
            
LBL1011     *********** 1011 **********
            **** INVALID ****
            JMP     OPCDATA
            ********** /1011 **********
            
            
            
LBL1100     *********** 1100 **********
            CLR.L   D3
            * test %xxxx xxxX XXxx xxxx
            MOVE.W  #$01C0,D3
            AND.W   D4,D3
            *   == %xxxx xxx1 11xx xxxx
            CMP.W   #$01C0,D3
            BNE     SKP1_1100
            ****** MULS *****
            LEA     MULS,A1
            JSR     OUTPUTSTR
            JMP     DONE_1100
            ***** /MULS *****

SKP1_1100   ****** AND ******
            LEA     AND,A1
            JSR     OUTPUTSTR
            * switch %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT1100B   * byte
            CMP.B   #$00,D3
            BNE     PRNT1100W
            LEA     B,A1
            JSR     OUTPUTSTR
            JMP     DONE_1100
PRNT1100W   * word
            CMP.B   #$40,D3
            BNE     PRNT1100L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_1100
PRNT1100L   * long
            CMP.B   #$80,D3
            BNE     DATA_1100
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_1100
            ***** /AND ******
            
DONE_1100   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_1100   JMP     OPCDATA
            ********** /1100 **********
            
            

LBL1101     *********** 1101 **********
            CLR.L   D3
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
            *   == %xxxx xxxx 11xx xxxx
            CMP.W   #$00C0,D3
            BNE     SKP1_1101
            ****** ADDA *****
            LEA     ADDA,A1
            JSR     OUTPUTSTR
            * test %xxxx xxxX xxxx xxxx
            MOVE.W  #$0100,D3
            AND.W   D4,D3
PRNT1101W   * word
            CMP.W   #$0000,D3
            BNE     PRNT1101L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_1101
PRNT1101L   * long
            CMP.W   #$0100,D3
            BNE     DATA_1101
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_1101
            ***** /ADDA *****
            
SKP1_1101   ****** ADD ******
            LEA     ADD,A1
            JSR     OUTPUTSTR
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT1101B2  * byte
            CMP.B   #$00,D3
            BNE     PRNT1101W2
            LEA     B,A1
            JSR     OUTPUTSTR
            JMP     DONE_1101
PRNT1101W2  * word
            CMP.B   #$40,D3
            BNE     PRNT1101L2
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_1101
PRNT1101L2  * long
            CMP.B   #$80,D3
            BNE     DATA_1101
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_1101
            ***** /ADD ******
            
DONE_1101   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_1101   JMP     OPCDATA
            ********** /1101 **********
            
            
            
LBL1110     *********** 1110 **********
            CLR.L   D3
            * test %xxxx xxxX xxxx xxxx
            MOVE.W  #$0100,D3
            AND.W   D4,D3
            *   == %xxxx xxx1 xxxx xxxx
            CMP.W   #$0100,D3
            BNE     SKP6_1110
            **** LEFT OPERATIONS ****
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
            *   == %xxxx xxxx 11xx xxxx
            CMP.W   #$00C0,D3
            BNE     SKP3_1110
            ****** MEMORY ******
            * test %xxxx XXXx xxxx xxxx
            MOVE.W  #$0E00,D3
            AND.W   D4,D3
            *   == %xxxx 000x xxxx xxxx
            CMP.W   #$0000,D3
            BNE     SKP1_1110
            *** ASL (mem) ***
            LEA     ASL_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /ASL (mem) ***
            
SKP1_1110   *   == %xxxx 001x xxxx xxxx
            CMP.W   #$0200,D3
            BNE     SKP2_1110
            *** LSL (mem) ***
            LEA     LSL_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /LSL (mem) ***
            
SKP2_1110   *   == %xxxx 011x xxxx xxxx
            CMP.W   #$0600,D3
            BNE     DATA_1110
            *** ROL (mem) ***
            LEA     ROL_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /ROL (mem) ***
            
SKP3_1110   **** NON-MEMORY ****
            * test %xxxx xxxx xxxX Xxxx
            MOVE.W  #$0018,D3
            AND.W   D4,D3
            *   == %xxxx xxxx xxx0 0xxx
            CMP.W   #$0000,D3
            BNE     SKP4_1110
            ****** ASL ******
            LEA     ASL,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /ASL ******
            
SKP4_1110   *   == %xxxx xxxx xxx0 1xxx
            CMP.W   #$0008,D3
            BNE     SKP5_1110
            ****** LSL ******
            LEA     LSL,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /LSL ******
            
SKP5_1110   *   == %xxxx xxxx xxx1 1xxx
            CMP.W   #$0018,D3
            BNE     DATA_1110
            ****** ROL ******
            LEA     ROL,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /ROL ******

SKP6_1110   **** RIGHT OPERATIONS ***
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
            *   == %xxxx xxxx 11xx xxxx
            CMP.W   #$00C0,D3
            BNE     SKP9_1110
            ****** MEMORY ******
            * test %xxxx XXXx xxxx xxxx
            MOVE.W  #$0E00,D3
            AND.W   D4,D3
            *   == %xxxx 000x xxxx xxxx
            CMP.W   #$0000,D3
            BNE     SKP7_1110
            *** ASR (mem) ***
            LEA     ASR_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /ASR (mem) ***
            
SKP7_1110   *   == %xxxx 001x xxxx xxxx
            CMP.W   #$0200,D3
            BNE     SKP8_1110
            *** LSR (mem) ***
            LEA     LSR_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /LSR (mem) ***
            
SKP8_1110   *   == %xxxx 011x xxxx xxxx
            CMP.W   #$0600,D3
            BNE     DATA_1110
            *** ROR (mem) ***
            LEA     ROR_MEM,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            ** /ROR (mem) ***
            
SKP9_1110   **** NON-MEMORY ****
            * test %xxxx xxxx xxxX Xxxx
            MOVE.W  #$0018,D3
            AND.W   D4,D3
            *   == %xxxx xxxx xxx0 0xxx
            CMP.W   #$0000,D3
            BNE     SKP10_1110
            ****** ASR ******
            LEA     ASR,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /ASR ******
            
SKP10_1110  *   == %xxxx xxxx xxx0 1xxx
            CMP.W   #$0008,D3
            BNE     SKP11_1110
            ****** LSR ******
            LEA     LSR,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /LSR ******
            
SKP11_1110  *   == %xxxx xxxx xxx1 1xxx
            CMP.W   #$0018,D3
            BNE     DATA_1110
            ****** ROR ******
            LEA     ROR,A1
            JSR     OUTPUTSTR
            JMP     SKP12_1110
            ***** /ROR ******




SKP12_1110  * PRINT SIZE
            * test %xxxx xxxx XXxx xxxx
            MOVE.W  #$00C0,D3
            AND.W   D4,D3
PRNT1110B   * byte
            CMP.B   #$00,D3
            BNE     PRNT1110W
            LEA     B,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
PRNT1110W   * word
            CMP.B   #$40,D3
            BNE     PRNT1110L
            LEA     W,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
PRNT1110L   * long
            CMP.B   #$80,D3
            BNE     DATA_1110
            LEA     L,A1
            JSR     OUTPUTSTR
            JMP     DONE_1110
            
            

DONE_1110   JSR     OUTPUTPRNT
            JMP     OPCCONT1

DATA_1110   JMP     OPCDATA
            ********** /1110 **********



LBL1111     *********** 1111 **********
            **** INVALID ****
            JMP     OPCDATA
            ********** /1111 **********
            
            
            
            
            
            
            
            
            
            
     

OPCDATA     ****** NOT VALID OPCODE ******
            LEA     OPCINVALID,A1
            TRAP    #15
            JMP     OPCCONT1  
            
OPCCONT1    *** LINE BREAK & LOOP BACK ***
            *LEA     DATASTUFF,A1 *testing output feel
            *TRAP    #15
            LEA     NEWLINE,A1
            TRAP    #15
            CMP.L   A2,A3
            BEQ     STOP
            JMP     OPCLOOP1


************ OPCODE PHASE - DONE *************
************* BEGIN PRINT PHASE **************


PRINTALL    
            JMP     STOP

STOP        JSR     PAUSEOUTPUT
            LEA     NEWLINE,A1
            TRAP    #15
            LEA     DONE,A1
            TRAP    #15
            SIMHALT
          
*********************** Subroutines ************************

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
PRINTOFFSET MOVE.L  A2,D2
            JSR     HEX2STRING
            MOVE.L  #CurAddrOut,A4
            MOVE.L  D2,(A4)
            JSR     ADDRPRNT
            JSR     ADDRRESET
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
            JSR     ADDRRESET
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
            
            
            
*-------------------- ADDRRESET -----------------------
* Resets the Current Address pointer (A4) to beginning,
* resets the data for new input
*------------------------------------------------------
ADDRRESET   * Set Safe Output Pointer
            MOVEA.L  #CurAddrOut,A4
            * Set CurAddrOut to #$202020202020202000FFFFFFFFFFFFFF
            MOVE.L  #$20202020,(A4)
            MOVE.L  #$20202020,$4(A4)
            MOVE.L  #$00FFFFFF,$8(A4)
            MOVE.L  #$FFFFFFFF,$C(A4)
            MOVEA.L #SafeOutStr,A4
            RTS 
            
*///////////////////////////////////////////////////////////




*//////////////////// <EA> Subroutines /////////////////////



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
            LSR.W   #$03,D5

END345      RTS

*************************************************************
* MASK67 masks word on D5 and puts result on D6             *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 78              *
*************************************************************
MASK67      CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$00C0,D5       *mask 0000000011000000
            MOVE.W  D5,D6
            LSR.W   #$06,D5
END67       RTS

*************************************************************
* MASK678 masks word on D5 and puts result on D6             *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 78              *
*************************************************************
MASK678     CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$01C0,D5       *mask 0000000111000000
            MOVE.W  D5,D6
            LSR.W   #$06,D5
END678      RTS

*************************************************************
* MASK9AB masks word on D5 and puts result on D6             *
* PRE - D4 contains instruction.                            *
* POST - D6 will contain the DATA from bits 78              *
*************************************************************
MASK9AB     CLR.L   D5
            CLR.L   D6
            MOVE.W  D4,D5
            ANDI.W  #$0E00,D5       *mask 0000111000000000
            MOVE.W  D5,D6
            LSR.W   #$08,D5
            LSR.W   #$01,D5
END9AB      RTS



*///////////////////////////////////////////////////////////
            

************* Constants, Variables, Messages ***************
CR          EQU     $0D
LF          EQU     $0A


WELCOME     DC.B    '================================================================================',CR,LF
            DC.B    '                        Welcome to the 68k Disassembler!                        ',CR,LF
            DC.B    '================================================================================',CR,LF
            DC.B    '    _______ __         __                                                       ',CR,LF
            DC.B    '   |    ___|  |.--.--.|__|.-----.-----.                                         ',CR,LF
            DC.B    '   |    ___|  ||  |  ||  ||     |  _  |                                         ',CR,LF
            DC.B    '   |___|   |__||___  ||__||__|__|___  |                                         ',CR,LF
            DC.B    '               |_____|          |_____|                                         ',CR,LF
            DC.B    '                      _______ __              ___   ___                         ',CR,LF
            DC.B    '                     |     __|__|.----.---.-.`  _|.`  _|.-----.                 ',CR,LF
            DC.B    '                     |    |  |  ||   _|  _  |   _||   _||  -__|                 ',CR,LF
            DC.B    '                     |_______|__||__| |___._|__|  |__|  |_____|                 ',CR,LF
            DC.B    '                                           _______                       __     ',CR,LF
            DC.B    '                                          |     __|.-----.--.--.---.-.--|  |    ',CR,LF
            DC.B    '                                          |__     ||  _  |  |  |  _  |  _  |    ',CR,LF
            DC.B    '                                          |_______||__   |_____|___._|_____|    ',CR,LF
            DC.B    '                                                      |__|                      ',CR,LF
            DC.B    '================================================================================',CR,LF
            DC.B    '                  Daniel Dehaas | Zach Selin | Regina Bloomstine                ',CR,LF
            DC.B    '================================================================================',CR,LF,CR,LF,0
ENTRSTRT    DC.B    'Please enter a starting address (Ex: $0000A000): ',0
ENTREND     DC.B    'Please enter an ending address (Ex: $000A200): ',0
ERRNOTHEX   DC.B    'Please begin your hex address entry with "$"',CR,LF,0
DONE        DC.B    '================================================================================',CR,LF
            DC.B    '                              Disassembly Finished                              ',CR,LF
            DC.B    '================================================================================',CR,LF,0
NEWLINE     DC.B    '',CR,LF,0

CONTINUE    DC.B    '<ENTER TO CONTINUE>',0

OPCINVALID  DC.B    'DATA    ',0

ADDI        DC.B    'ADDI.',0
SUBI        DC.B    'SUBI.',0
MOVEB       DC.B    'MOVE.B  ',0
MOVEL       DC.B    'MOVE.L  ',0
MOVEAL      DC.B    'MOVEA.L ',0
MOVEW       DC.B    'MOVE.W  ',0
MOVEAW      DC.B    'MOVEA.W ',0
JSR         DC.B    'JSR     ',0
LEA         DC.B    'LEA     ',0
MOVEFROMCCR DC.B    'MOVE CCR,',0   *SYNTAX FOR MOVE TO CCR IS: "MOVE CCR,<ea>"
MOVEM       DC.B    'MOVEM.',0
MOVETOCCR   DC.B    'MOVE ',0       *SYNTAX FOR MOVE TO CCR IS: "MOVE <ea>,CCR"
TOCCR       DC.B    ',CCR',0         *Prints AFTER <ea> is printed (ex <ea>, 'D7')
MOVEFROMSR  DC.B    'MOVE SR,',0    *SYNTAX FOR MOVE TO CCR IS: "MOVE SR,<ea>"
NOP         DC.B    'NOP     ',0
RTS         DC.B    'RTS     ',0
ADDQ        DC.B    'ADDQ.',0
BCC         DC.B    'BCC     ',0
BGE         DC.B    'BGE     ',0
BLT         DC.B    'BLT     ',0
BRA         DC.B    'BRA     ',0
MOVEQ       DC.B    'MOVEQ   ',0
DIVU        DC.B    'DIVU.W  ',0
OR          DC.B    'OR.',0
SUB         DC.B    'SUB.',0
AND         DC.B    'AND.',0
MULS        DC.B    'MULS.W  ',0
ADD         DC.B    'ADD.',0
ADDA        DC.B    'ADDA.',0
ASL         DC.B    'ASL.',0
ASR         DC.B    'ASR.',0
LSL         DC.B    'LSL.',0
LSR         DC.B    'LSR.',0
ROL         DC.B    'ROL.',0
ROR         DC.B    'ROR.',0
ASL_MEM     DC.B    'ASL     ',0
ASR_MEM     DC.B    'ASR     ',0
LSL_MEM     DC.B    'LSL     ',0
LSR_MEM     DC.B    'LSR     ',0
ROL_MEM     DC.B    'ROL     ',0
ROR_MEM     DC.B    'ROR     ',0

B           DC.B    'B',0
W           DC.B    'W',0
L           DC.B    'L',0

DATASTUFF   DC.B    '####',0



SafeStrA1   EQU     $0FB0
LoopCounter EQU     $0001FFFF   * For determining when to pause output
SafeOutStr  EQU     $00020000   * All output in string format will go here, with an
                                *  incrementing Addr inserting as we disassemble
                                *  Uses FULL memory offset (4 longs)
STRTOHEXOUT EQU     $0001FFF0   * Uses Long
CurAddrOut  EQU     $0001FFE0   * Uses FULL memory offset (4 longs)
JSRDATA1    EQU     $0001FFFE   * Uses Byte to be used in Subroutines for ANY purpose - defined by subroutine


    END    START        ; last line of source

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
