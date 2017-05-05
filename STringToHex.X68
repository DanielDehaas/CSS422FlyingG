*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

*readed in string A2 and A3 from the code before 
**we need to convert it to hex, so we use the logic from below
*this code  is currently for  A2. Reusable for A3 as well if
* value is  changed. 


*NOTE: address is changable, adjust it to whatever we need:)* 
    MOVEA.L #$56A, A5


*Store i = 8 for looping for 8 characters*     
    MOVE.B  #9, D1      


* here we are going to use the loop to scan for 
* potential letters and  numbers. This part is representing 
* the for llop from 8 to 0 at D1
STRTOHEX  

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
    BRA STRTOHEX         

POSSIBLE_NUM
*same logic as letter: check if full, fix
    CMP.B   #$30, D3    
    BLT     NOTFULL8   

*convert by -
    SUB.B   #$30, D3    
    MOVE.B  D3, (A5)+   

*go back
    BRA STRTOHEX  

       
NOTFULL8 
*used in possible num/leter
* fills  empty space with 0's if user didn't 
    MOVE.B  #$00, (A5)+ 

    BRA STRTOHEX         


* loop used to shift the data we need
* for the correct conversion. 
ADD$5LOGIC
*reset a5, make d1 = hex5
    MOVEA.L #$56A, A5  
*adjust for the next loop 
    MOVE.B  #5, D1  


*loop for d1 = 5 going down    
LOOP_D1_5 

*sub 1 attempt 
    SUB.B   #1, D1
*check if done and are at 0 already      
    CMP.B   #0, D1      
*///////////////////////////////////////////////////////////////////////////////////////////////////////
*if all done and correct, go to ????
    BEQ     ????       
    
*////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    MOVE.B (A5)+, D2    

*shifting logic
    LSL.L   #4, D2      
    ADD.B  (A5)+,D2     
    LSL.L   #8, D3      
    
*add result
    ADD.B   D2, D3      

*repeat till done
    BRA LOOP_D1_5            

SIMHALT             ; halt simulator


    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
