;Fourier series visualizer program for Dosbox
;Author: Eyal Kaghanovich
;This was my final project for 10th grade's computer architecture and assembly class



.MODEL SMALL
.STACK 100h
.DATA
    ; Labels for X-axis
    NEG_3PI DB '-3pi', '$'
    NEG_2PI DB '-2pi', '$'
    NEG_PI  DB '-pi', '$'
    ZERO    DB '0', '$'
    POS_PI  DB 'pi', '$'
    POS_2PI DB '2pi', '$'
    POS_3PI DB '3pi', '$'
    
    ; Labels for Y-axis
    NEG_1_5 DB '-1.5', '$'
    NEG_1   DB '-1', '$'
    NEG_0_5 DB '-0.5', '$'
    POS_0_5 DB '0.5', '$'
    POS_1   DB '1', '$'
    POS_1_5 DB '1.5', '$'
    
    CURRENT_TERMS DW INITIAL_TERMS  ; Current number of terms in Fourier series
    X_OFFSET DW 0                   ; Current X-axis offset in degrees (0 = centered)
    
    ; Sine lookup table (0 to 90 degrees in 1-degree increments)
    ; Values are scaled by 100 to work with integers
    SINE_TABLE DW 0, 2, 3, 5, 7, 9, 10, 12, 14, 16, 17, 19, 21, 22, 24, 26, 28, 29, 31, 33
               DW 34, 36, 37, 39, 41, 42, 44, 45, 47, 48, 50, 52, 53, 55, 56, 58, 59, 60, 62, 63
               DW 64, 66, 67, 68, 70, 71, 72, 73, 75, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 87
               DW 87, 88, 89, 90, 91, 91, 92, 93, 94, 94, 95, 96, 96, 97, 97, 98, 98, 98, 99, 99
               DW 99, 100, 100, 100, 100, 100, 100, 100, 99, 99, 99, 98, 98, 98, 97, 97, 96, 96, 95, 94
    
    ; Constants for scaling
    SCREEN_WIDTH    EQU 320
    SCREEN_HEIGHT   EQU 200
    X_CENTER        EQU 160    ; Center x-coordinate
    Y_CENTER        EQU 100    ; Center y-coordinate
    VERTICAL_SCALE  EQU 67     ; 67 pixels per unit (200/1.5 ≈ 133/2)
    INITIAL_TERMS   EQU 3      ; Start with 3 terms
    MAX_TERMS       EQU 21     ; Maximum number of terms (after 6 clicks)
    MODULATED_MAX_TERMS EQU 27 ; Maximum number of terms for modulated sine wave
    
    ; Add menu text strings
    WELCOME_MSG     DB 'Welcome to the Fourier Series Visualization Program!', 13, 10
                   DB 'This program demonstrates how different periodic functions can be', 13, 10
                   DB 'approximated using Fourier series.', 13, 10
                   DB 'Press SPACE to add more terms to the approximation.', 13, 10
                   DB 'Use LEFT/RIGHT arrows to shift the view.', 13, 10
                   DB 'Press ` (backtick) to return to this menu.', 13, 10
                   DB 'Press ESC to exit.', 13, 10, 10, '$'
    
    MENU_MSG       DB 'Please choose a function to visualize:', 13, 10
                   DB '1. Square Wave', 13, 10
                   DB '2. Full-Wave Rectified Sine', 13, 10
                   DB '3. Non-symmetric Triangle Wave', 13, 10
                   DB '4. Sawtooth Wave', 13, 10
                   DB '5. Pulse Train', 13, 10
                   DB '6. Step Function', 13, 10
                   DB '7. Piecewise Linear Function', 13, 10
                   DB '8. Modulated Sine Wave', 13, 10
                   DB 'Enter your choice (1-8): $'
    
    INVALID_MSG    DB 'Invalid choice. Please try again.', 13, 10, '$'
    
    CHOICE         DB 0    ; Variable to store user's choice
    
    ; Add flags for which functions to draw
    DRAW_SQUARE    DB 0
    DRAW_RECTIFIED DB 0
    DRAW_TRIANGLE  DB 0
    DRAW_SAWTOOTH  DB 0
    DRAW_PULSE     DB 0
    DRAW_STEP      DB 0
    DRAW_PIECEWISE DB 0
    DRAW_MODULATED DB 0

.CODE

; Function to calculate sine of an angle (in 0-359 degrees range)
; Input: AX = angle in degrees (0-359)
; Output: AX = sine value scaled by 100 (-100 to 100)
CALC_SIN PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE ANGLE_POSITIVE
    ADD AX, 360
    
ANGLE_POSITIVE:
    ; Determine quadrant and convert to 0-90 range
    MOV BX, AX              ; Save original angle
    CMP AX, 90
    JLE FIRST_QUADRANT
    
    CMP AX, 180
    JLE SECOND_QUADRANT
    
    CMP AX, 270
    JLE THIRD_QUADRANT
    
    ; Fourth quadrant (270-359)
    SUB AX, 270
    MOV CX, 90
    SUB CX, AX              ; CX = 90 - (angle-270) = 360-angle
    MOV AX, CX
    MOV CX, 4               ; Quadrant 4
    JMP LOOKUP_SINE
    
FIRST_QUADRANT:             ; 0-90 degrees
    MOV CX, 1               ; Quadrant 1
    JMP LOOKUP_SINE
    
SECOND_QUADRANT:            ; 91-180 degrees
    MOV CX, 180
    SUB CX, AX              ; CX = 180-angle
    MOV AX, CX
    MOV CX, 2               ; Quadrant 2
    JMP LOOKUP_SINE
    
THIRD_QUADRANT:             ; 181-270 degrees
    SUB AX, 180             ; AX = angle-180
    MOV CX, 3               ; Quadrant 3
    JMP LOOKUP_SINE
    
LOOKUP_SINE:
    ; Now AX is in 0-90 range, lookup in table
    SHL AX, 1               ; Multiply by 2 because each table entry is a word (2 bytes)
    
    ; Get value from table
    MOV SI, OFFSET SINE_TABLE
    ADD SI, AX
    MOV AX, [SI]            ; AX = sin(angle) * 100
    
    ; Apply sign based on quadrant
    CMP CX, 3               ; Check if in 3rd or 4th quadrant
    JB SINE_POSITIVE
    NEG AX                  ; Negate for 3rd and 4th quadrants
    
SINE_POSITIVE:
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_SIN ENDP

; Function to calculate cosine of an angle
; Input: AX = angle in degrees (0-359)
; Output: AX = cosine value scaled by 100 (-100 to 100)
CALC_COS PROC
    ADD AX, 90              ; cos(x) = sin(x+90)
    CMP AX, 360             ; Check if overflow
    JL NO_OVERFLOW
    SUB AX, 360             ; Wrap around
NO_OVERFLOW:
    CALL CALC_SIN           ; Calculate sine
    RET
CALC_COS ENDP

; Function to calculate square wave
; Input: AX = angle in degrees (0-359)
; Output: AX = square wave value scaled by 100 (-100 to 100)
CALC_SQUARE PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE SQUARE_POSITIVE
    ADD AX, 360
    
SQUARE_POSITIVE:
    ; For 0-179 degrees, return +100
    ; For 180-359 degrees, return -100
    CMP AX, 180
    JL SQUARE_HIGH
    
    MOV AX, -100            ; Negative part of square wave
    JMP SQUARE_DONE
    
SQUARE_HIGH:
    MOV AX, 100             ; Positive part of square wave
    
SQUARE_DONE:
    POP DX
    POP CX
    POP BX
    RET
CALC_SQUARE ENDP

; Function to calculate Fourier series approximation of square wave
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX          ; Save original angle
    XOR DI, DI          ; DI will accumulate the sum
    ; CX already contains number of terms
    MOV BX, 1          ; Current harmonic (n)
    
FOURIER_LOOP:
    PUSH CX             ; Save loop counter
    PUSH BX             ; Save current harmonic
    
    ; Calculate n*angle
    MOV AX, SI         ; Load original angle
    IMUL BX            ; Multiply angle by harmonic number (n*angle)
    
    ; Calculate sin(n*angle)
    CALL CALC_SIN      ; Result in AX, scaled by 100
    
    ; Divide by current harmonic (n)
    POP BX             ; Restore current harmonic
    PUSH BX            ; Save it again for later
    CWD                ; Sign-extend AX into DX
    IDIV BX            ; AX = sin(n*angle)/n
    
    ; Scale by 4/pi (approximately 127/100)
    MOV BX, 127
    IMUL BX            ; DX:AX = result * 127
    MOV BX, 100
    IDIV BX            ; AX = (result * 127) / 100
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next odd harmonic
    POP BX             ; Restore current harmonic
    ADD BX, 2          ; Next odd number
    
    POP CX             ; Restore loop counter
    LOOP FOURIER_LOOP
    
    MOV AX, DI         ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_FOURIER ENDP

; Function to calculate Fourier series approximation of rectified sine wave
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (0 to 100)
CALC_RECTIFIED_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    
    ; Calculate the constant term (2/π)
    MOV AX, 64              ; 2/π * 100 ≈ 64
    MOV DI, AX              ; DI = constant term
    
    ; Loop through harmonics
    MOV BX, 1               ; Start with n=1
    
RECTIFIED_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save n
    
    ; Calculate the angle for this harmonic (2n*angle)
    MOV AX, SI              ; Original angle
    SHL BX, 1               ; BX = 2n
    IMUL BX                 ; AX = 2n*angle
    SHR BX, 1               ; Restore BX = n
    
    ; Calculate cosine of 2n*angle
    CALL CALC_COS           ; AX = cos(2n*angle) * 100
    
    ; Calculate the coefficient for this harmonic: 4/(pi*(4n^2-1))
    PUSH AX                 ; Save cos(2n*angle)
    
    ; Calculate 4n^2-1
    MOV AX, BX              ; AX = n
    IMUL AX                 ; AX = n^2
    SHL AX, 2               ; AX = 4n^2
    DEC AX                  ; AX = 4n^2-1
    
    ; Safety check
    CMP AX, 0
    JE SKIP_TERM
    
    ; Scale numerator (4) for precision
    MOV CX, AX              ; Save denominator
    MOV AX, 400             ; 4 * 100 (scaled for integer math)
    
    ; Divide by denominator
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; AX = 4/(4n^2-1) * 100
    
    ; Divide by pi (≈ 3.14)
    MOV CX, 314             ; π * 100
    PUSH DX                 ; Save DX
    MOV DX, 0
    MOV BX, 100             ; Scale up for better precision
    IMUL BX                 ; AX = previous result * 100
    DIV CX                  ; AX = result / 3.14 (scaled)
    POP DX                  ; Restore DX
    
    ; Get the cosine term
    POP BX                  ; Retrieve cos(2n*angle)
    
    ; Multiply coefficient by cosine
    IMUL BX                 ; DX:AX = coefficient * cos(2n*angle)
    MOV CX, 100
    IDIV CX                 ; Scale back down
    
    ; Negate the term (alternating series)
    NEG AX
    
    ; Add to the accumulator
    ADD DI, AX
    
SKIP_TERM:
    ; Next harmonic
    POP BX                  ; Restore n
    INC BX                  ; Next n
    
    POP CX                  ; Restore counter
    LOOP RECTIFIED_FOURIER_LOOP
    
    ; Return the accumulated value
    MOV AX, DI
    
    ; Ensure result is in 0-100 range
    CMP AX, 0
    JGE CHECK_UPPER_RECTIFIED
    XOR AX, AX              ; If negative, clamp to 0
    
CHECK_UPPER_RECTIFIED:
    CMP AX, 100
    JLE RECTIFIED_DONE
    MOV AX, 100             ; If > 100, clamp to 100
    
RECTIFIED_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_RECTIFIED_FOURIER ENDP

; Function to calculate non-symmetric triangle wave
; Input: AX = angle in degrees (0-359)
; Output: AX = triangle wave value scaled by 100 (-100 to 100)
CALC_TRIANGLE PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE TRIANGLE_POSITIVE
    ADD AX, 360
    
TRIANGLE_POSITIVE:
    ; For 0-120 degrees: Rise from -100 to 100 (fast rise)
    CMP AX, 120
    JG CHECK_FALLING
    
    ; Calculate rising slope: y = mx + b
    ; m = 200/120 = 1.67, scaled by 100 = 167
    MOV BX, 167
    IMUL BX              ; DX:AX = angle * 167
    MOV BX, 100
    IDIV BX              ; AX = (angle * 167) / 100
    SUB AX, 100          ; Shift down to start at -100
    JMP TRIANGLE_DONE
    
CHECK_FALLING:
    ; For 120-360 degrees: Fall from 100 to -100 (slow fall)
    ; Calculate falling slope: y = mx + b
    ; m = -200/240 = -0.83, scaled by 100 = -83
    SUB AX, 120          ; Adjust angle to start from 0
    MOV BX, 83
    IMUL BX              ; DX:AX = adjusted_angle * 83
    MOV BX, 100
    IDIV BX              ; AX = (adjusted_angle * 83) / 100
    NEG AX               ; Make slope negative
    ADD AX, 100          ; Start from 100
    
TRIANGLE_DONE:
    POP DX
    POP CX
    POP BX
    RET
CALC_TRIANGLE ENDP

; Function to calculate Fourier series approximation of non-symmetric triangle wave
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_TRIANGLE_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    XOR DI, DI              ; DI will accumulate the sum
    MOV BX, 1               ; Current harmonic (n)
    
TRIANGLE_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate n*angle for sin(nx)
    MOV AX, SI             ; Load original angle
    IMUL BX                ; Multiply angle by harmonic number
    
    ; Calculate sin(nx)
    CALL CALC_SIN          ; Result in AX, scaled by 100
    
    ; Scale by 1/n^2
    POP BX                 ; Restore n
    PUSH BX                ; Save n again
    
    ; Square n
    MOV CX, BX
    IMUL CX               ; DX:AX = n^2
    
    ; Save sine result temporarily
    PUSH AX               ; Save sine result
    MOV AX, BX            ; Get n
    MOV BX, AX            ; Save n in BX
    POP AX                ; Restore sine result
    
    ; Now divide by n^2
    CWD                   ; Sign-extend AX into DX
    IDIV BX              ; First division by n
    CWD
    IDIV BX              ; Second division by n
    
    ; Scale result
    MOV BX, 150          ; Scale factor to make wave more visible
    IMUL BX
    MOV BX, 100
    IDIV BX
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX                ; Restore harmonic number
    INC BX                ; Next harmonic
    
    POP CX                ; Restore loop counter
    LOOP TRIANGLE_FOURIER_LOOP
    
    MOV AX, DI            ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_TRIANGLE_FOURIER ENDP

; Function to calculate sawtooth wave
; Input: AX = angle in degrees (0-359)
; Output: AX = sawtooth wave value scaled by 100 (-100 to 100)
CALC_SAWTOOTH PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE SAWTOOTH_POSITIVE
    ADD AX, 360
    
SAWTOOTH_POSITIVE:
    ; Calculate sawtooth: 2x/360 - 1 (positive slope)
    ; First multiply by 200 (to get -100 to +100 range)
    MOV BX, 200
    IMUL BX              ; DX:AX = angle * 200
    
    ; Divide by 360
    MOV BX, 360
    IDIV BX              ; AX = (angle * 200) / 360
    
    ; Subtract 100 to center around zero
    SUB AX, 100
    
    POP DX
    POP CX
    POP BX
    RET
CALC_SAWTOOTH ENDP

; Function to calculate Fourier series approximation of sawtooth wave
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_SAWTOOTH_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    ADD SI, 90              ; Phase adjustment 
    XOR DI, DI              ; DI will accumulate the sum
    MOV BX, 1               ; Current harmonic (n)
    
SAWTOOTH_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate n*angle for sin(nx)
    MOV AX, SI             ; Load original angle
    IMUL BX                ; Multiply angle by harmonic number
    
    ; Calculate sin(nx)
    CALL CALC_SIN          ; Result in AX, scaled by 100
    
    ; Negate term - sawtooth wave Fourier coefficients alternate sign
    NEG AX
    
    ; Scale by 1/n - divide sine by harmonic number
    POP BX                 ; Restore n
    PUSH BX                ; Save n again
    CWD                    ; Sign-extend AX into DX
    IDIV BX                ; AX = sin(nx)/n
    
    ; Scale to proper amplitude (approximately 60)
    MOV CX, 60             ; Amplitude scaling factor
    IMUL CX                ; DX:AX = (sin(nx)/n) * 60
    MOV CX, 100
    IDIV CX                ; AX = result / 100 (normalize)
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX
    INC BX
    
    POP CX                 ; Restore loop counter
    LOOP SAWTOOTH_FOURIER_LOOP
    
    ; Add constant term (DC offset) if needed
    ; For sawtooth, the average value is 0, so no offset needed
    
    MOV AX, DI            ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_SAWTOOTH_FOURIER ENDP

; Function to calculate pulse train
; Input: AX = angle in degrees (0-359)
; Output: AX = pulse train value scaled by 100 (-100 to 100)
CALC_PULSE PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE PULSE_POSITIVE
    ADD AX, 360
    
PULSE_POSITIVE:
    ; For 0-89 degrees, return +100 (pulse width 90°, or 1/4 of period)
    CMP AX, 90
    JL PULSE_HIGH
    
    ; For 90-359 degrees, return -100
    MOV AX, -100
    JMP PULSE_DONE
    
PULSE_HIGH:
    MOV AX, 100
    
PULSE_DONE:
    POP DX
    POP CX
    POP BX
    RET
CALC_PULSE ENDP

; Function to calculate Fourier series approximation of pulse train
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_PULSE_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    XOR DI, DI              ; DI will accumulate the sum
    
    ; Add constant term - DC component (duty cycle)
    MOV AX, -75             ; Adjusted constant term for better alignment
    ADD DI, AX
    
    MOV BX, 1               ; Current harmonic (n)
    
PULSE_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate n*angle for cosine term
    MOV AX, SI              ; Load original angle
    IMUL BX                 ; Multiply angle by harmonic number (n*angle)
    
    ; Calculate cos(n*angle)
    CALL CALC_COS           ; Result in AX, scaled by 100
    
    ; Determine coefficient based on harmonic
    POP BX                  ; Restore n
    PUSH BX                 ; Save it again
    
    ; For a pulse with 25% duty cycle, the coefficient is (2/π)sin(nπ/4)/n
    ; First calculate sin(nπ/4)
    MOV AX, BX              ; n
    MOV CX, 45              ; π/4 in degrees = 45°
    IMUL CX                 ; n*45
    
    CALL CALC_SIN           ; sin(nπ/4)
    
    ; Divide by n and scale by 2/π
    MOV CX, AX              ; Save sin(nπ/4)
    POP BX                  ; Restore harmonic number
    PUSH BX                 ; Save it again
    MOV AX, CX              ; Restore sin(nπ/4)
    
    CWD                     ; Sign-extend AX into DX
    IDIV BX                 ; AX = sin(nπ/4)/n
    
    ; Scale by 2/π * adjustment factor
    MOV CX, 110             ; Increased scaling factor for better visibility and alignment
    IMUL CX                 ; DX:AX = (sin(nπ/4)/n) * 110
    MOV CX, 100
    IDIV CX                 ; AX = coefficient
    
    ; Save coefficient
    MOV CX, AX
    
    ; Calculate cos(n*angle) again
    MOV AX, SI              ; Original angle
    POP BX                  ; Restore n
    PUSH BX                 ; Save n again
    IMUL BX                 ; AX = n * angle
    CALL CALC_COS           ; AX = cos(n*angle)
    
    ; Multiply coefficient by cos(n*angle)
    IMUL CX                 ; DX:AX = cos(n*angle) * coefficient
    MOV CX, 100
    IDIV CX                 ; Normalize back
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX                  ; Restore current harmonic
    INC BX                  ; Next harmonic
    
    POP CX                  ; Restore loop counter
    LOOP PULSE_FOURIER_LOOP
    
    MOV AX, DI             ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_PULSE_FOURIER ENDP

; Function to calculate step function
; Input: AX = angle in degrees (0-359)
; Output: AX = step function value scaled by 100 (-100 to 100)
CALC_STEP PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE STEP_POSITIVE
    ADD AX, 360
    
STEP_POSITIVE:
    ; Define steps (3 steps over 360 degrees)
    ; 0-119: First step (-100)
    CMP AX, 120
    JGE CHECK_SECOND_STEP
    MOV AX, -100
    JMP STEP_DONE
    
CHECK_SECOND_STEP:
    ; 120-239: Second step (0)
    CMP AX, 240
    JGE CHECK_THIRD_STEP
    MOV AX, 0
    JMP STEP_DONE
    
CHECK_THIRD_STEP:
    ; 240-359: Third step (100)
    MOV AX, 100
    
STEP_DONE:
    POP DX
    POP CX
    POP BX
    RET
CALC_STEP ENDP

; Function to calculate Fourier series approximation of step function
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_STEP_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    ADD SI, 90              ; Increase phase adjustment from 60 to 90 degrees to shift further left
    XOR DI, DI              ; DI will accumulate the sum
    MOV BX, 1               ; Current harmonic (n)
    
STEP_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate n*angle
    MOV AX, SI              ; Load original angle
    IMUL BX                 ; Multiply angle by harmonic
    
    ; Calculate sin(n*angle)
    CALL CALC_SIN           ; Result in AX, scaled by 100
    
    ; Compute the coefficient for each term
    ; For a 3-step function, we use a different formula than square wave
    POP BX                  ; Restore n
    PUSH BX                 ; Save n again
    
    ; For step function with steps at 120° and 240°
    ; Coefficient is approximately (1-cos(n*120°))/n*pi
    
    ; First calculate n*120 degrees
    MOV AX, 120
    IMUL BX
    
    ; Calculate cos(n*120°)
    CALL CALC_COS           ; Result in AX, scaled by 100
    
    ; Calculate 1-cos(n*120°)
    MOV CX, 100
    SUB CX, AX              ; CX = 100 - cos(n*120°)
    
    ; Now we need to divide by n
    POP BX                  ; Restore n
    PUSH BX                 ; Save it again
    MOV AX, CX
    CWD                     ; Sign-extend AX into DX
    IDIV BX                 ; AX = (1-cos(n*120°))/n
    
    ; Divide by pi (approximately 314/100)
    MOV BX, 314
    ; IMUL AX, 100            ; Scale up before division
    MOV CX, 100
    IMUL CX                   ; Scale up before division
    CWD
    IDIV BX
    
    ; Scale the result for better visibility
    MOV CX, 150
    IMUL CX
    MOV CX, 100
    IDIV CX
    
    ; Calculate sin(n*theta) again for the final computation
    MOV CX, AX              ; Save coefficient
    MOV AX, SI              ; Original angle
    POP BX                  ; Restore n
    PUSH BX                 ; Save it again
    IMUL BX                 ; AX = n * angle
    CALL CALC_SIN           ; AX = sin(n*angle)
    
    ; Multiply coefficient by sin(n*angle)
    IMUL CX                 ; DX:AX = sin(n*angle) * coefficient
    MOV CX, 100
    IDIV CX                 ; AX = result / 100 (normalize)
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX                  ; Restore current harmonic
    INC BX                  ; Next harmonic
    
    POP CX                  ; Restore loop counter
    LOOP STEP_FOURIER_LOOP
    
    ; Add constant offset (average of step values)
    MOV AX, 0               ; Average of -100, 0, and 100 is 0
    ADD DI, AX
    
    ; Apply final scaling to match the amplitude
    MOV AX, DI
    MOV CX, 140             ; Further reduce scaling factor from 180 to 140
    IMUL CX
    MOV CX, 100
    IDIV CX                 ; AX = Fourier series with adjusted amplitude
    
    ; Apply small vertical offset correction to better align with step function
    SUB AX, 6               ; Reduce from 10 to 6 to shift upward by ~4 pixels
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_STEP_FOURIER ENDP

; Function to calculate piecewise linear function
; Input: AX = angle in degrees (0-359)
; Output: AX = piecewise linear function value scaled by 100 (-100 to 100)
CALC_PIECEWISE PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Normalize angle to 0-359 range
    MOV CX, 360
    CWD                     ; Sign-extend AX into DX
    IDIV CX                 ; DX = AX mod 360
    MOV AX, DX
    
    ; Make angle positive if negative
    CMP AX, 0
    JGE PIECEWISE_POSITIVE
    ADD AX, 360
    
PIECEWISE_POSITIVE:
    ; From 0° to 90°: Linear increase from -100 to 0
    CMP AX, 90
    JG CHECK_SECTION2
    
    ; y = m*x + b
    ; m = 100/90 = 1.11, scaled by 100 = 111
    MOV BX, 111
    IMUL BX              ; DX:AX = angle * 111
    MOV BX, 100
    IDIV BX              ; AX = (angle * 111) / 100
    SUB AX, 100          ; Shift down to start at -100
    JMP PIECEWISE_DONE
    
CHECK_SECTION2:
    ; From 90° to 180°: Linear increase from 0 to 100
    CMP AX, 180
    JG CHECK_SECTION3
    
    SUB AX, 90           ; Adjust angle to start from 0
    MOV BX, 111
    IMUL BX              ; DX:AX = adjusted_angle * 111
    MOV BX, 100
    IDIV BX              ; AX = (adjusted_angle * 111) / 100
    JMP PIECEWISE_DONE
    
CHECK_SECTION3:
    ; From 180° to 270°: Linear decrease from 100 to 50
    CMP AX, 270
    JG CHECK_SECTION4
    
    SUB AX, 180          ; Adjust angle to start from 0
    MOV BX, 56           ; (50-100)/90 * 100 = -56
    IMUL BX              ; DX:AX = adjusted_angle * 56
    MOV BX, 100
    IDIV BX              ; AX = (adjusted_angle * 56) / 100
    NEG AX               ; Make slope negative
    ADD AX, 100          ; Start from 100
    JMP PIECEWISE_DONE
    
CHECK_SECTION4:
    ; From 270° to 360°: Linear decrease from 50 to -100
    SUB AX, 270          ; Adjust angle to start from 0
    MOV BX, 167          ; ((-100)-50)/90 * 100 = -167
    IMUL BX              ; DX:AX = adjusted_angle * 167
    MOV BX, 100
    IDIV BX              ; AX = (adjusted_angle * 167) / 100
    NEG AX               ; Make slope negative
    ADD AX, 50           ; Start from 50
    
PIECEWISE_DONE:
    POP DX
    POP CX
    POP BX
    RET
CALC_PIECEWISE ENDP

; Function to calculate Fourier series approximation of piecewise linear function
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_PIECEWISE_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    XOR DI, DI              ; DI will accumulate the sum
    
    ; Add constant term (average value over the period)
    MOV AX, -13             ; Approximate average value of the piecewise function
    ADD DI, AX
    
    MOV BX, 1               ; Current harmonic (n)
    
PIECEWISE_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate n*angle for sine term
    MOV AX, SI             ; Load original angle
    IMUL BX                ; Multiply angle by harmonic number
    
    ; Calculate sin(n*angle)
    CALL CALC_SIN          ; Result in AX, scaled by 100
    
    ; Calculate coefficient for sine term (an)
    ; Store sine result temporarily
    PUSH AX
    
    ; Calculate coefficient for n
    ; For our piecewise function, approximate with a complex coefficient formula
    ; Use n and various constants to simulate a decaying oscillatory pattern
    MOV AX, 85             ; Base amplitude
    CWD
    IDIV BX                ; AX = 85/n
    
    ; Adjust sign based on harmonic number
    TEST BX, 1             ; Check if n is odd
    JNZ SINE_TERM_POS
    NEG AX                 ; If n is even, negate
SINE_TERM_POS:
    
    MOV CX, AX             ; Save coefficient
    
    ; Restore sine value
    POP AX
    
    ; Multiply coefficient by sin(nx)
    IMUL CX                ; DX:AX = sin(nx) * coefficient
    MOV CX, 100
    IDIV CX                ; AX = (sin(nx) * coefficient) / 100
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Calculate n*angle for cosine term
    MOV AX, SI              ; Load original angle
    POP BX                  ; Restore n
    PUSH BX                 ; Save n again
    IMUL BX                 ; Multiply angle by harmonic number
    
    ; Calculate cos(n*angle)
    CALL CALC_COS           ; Result in AX, scaled by 100
    
    ; Calculate coefficient for cosine term (bn)
    ; Store cosine result temporarily
    PUSH AX
    
    ; Calculate coefficient for n
    MOV AX, 80              ; Base amplitude
    MOV CX, BX              ; n
    IMUL CX                 ; DX:AX = 80 * n (scale with n, then decay)
    MOV CX, 10
    DIV CX                  ; AX = (80 * n) / 10 = 8 * n
    
    MOV CX, BX              ; Get n again
    MOV BX, AX              ; Save coefficient so far
    MOV AX, CX              ; n
    IMUL AX                 ; DX:AX = n^2
    MOV CX, AX              ; CX = n^2
    MOV AX, BX              ; Restore coefficient
    
    CWD
    IDIV CX                 ; AX = (8 * n) / n^2 = 8 / n
    
    ; Adjust sign based on a pattern
    TEST BX, 2              ; Check if n mod 4 is 2 or 3
    JZ COSINE_SIGN_CHECK2
    NEG AX
    JMP COSINE_TERM_READY
    
COSINE_SIGN_CHECK2:
    TEST BX, 1              ; Additional sign adjustment
    JZ COSINE_TERM_READY
    NEG AX

COSINE_TERM_READY:
    MOV CX, AX              ; Save coefficient
    
    ; Restore cosine value
    POP AX
    
    ; Multiply coefficient by cos(nx)
    IMUL CX                 ; DX:AX = cos(nx) * coefficient
    MOV CX, 100
    IDIV CX                 ; AX = (cos(nx) * coefficient) / 100
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX                  ; Restore current harmonic
    INC BX                  ; Next harmonic
    
    POP CX                  ; Restore loop counter
    LOOP PIECEWISE_FOURIER_LOOP
    
    MOV AX, DI              ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_PIECEWISE_FOURIER ENDP

; Function to calculate modulated sine wave
; Input: AX = angle in degrees (0-359)
; Output: AX = modulated sine wave value scaled by 100 (-100 to 100)
CALC_MODULATED PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Save original angle
    MOV SI, AX
    
    ; Calculate carrier wave (higher frequency: 4x)
    SHL AX, 2           ; Multiply angle by 4 for carrier
    CALL CALC_SIN       ; Result in AX (-100 to 100)
    
    ; Save carrier value
    PUSH AX
    
    ; Calculate modulator wave (lower frequency: 0.5x)
    MOV AX, SI
    SHR AX, 1           ; Divide angle by 2 for modulator
    CALL CALC_SIN       ; Result in AX (-100 to 100)
    
    ; Scale modulator to range 0.3 to 1 (30 to 100 when scaled by 100)
    ADD AX, 100         ; Range 0 to 200
    MOV BX, 70          ; Range will be 70% of full
    IMUL BX             ; DX:AX = modulator * 70
    MOV BX, 200         ; Divide by full range
    IDIV BX             ; AX = scaled modulator (0 to 70)
    ADD AX, 30          ; Range 30 to 100 (0.3 to 1.0)
    
    ; Multiply carrier by modulator (both scaled by 100)
    POP BX              ; Restore carrier value
    IMUL BX             ; DX:AX = carrier * modulator
    MOV BX, 100         ; Normalize from 100*100 scaling
    IDIV BX             ; AX = final modulated value (-100 to 100)
    
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_MODULATED ENDP

; Function to calculate Fourier series approximation of modulated sine wave
; Input: AX = angle in degrees (0-359)
;        CX = number of terms to use
; Output: AX = Fourier series value scaled by 100 (-100 to 100)
CALC_MODULATED_FOURIER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    MOV SI, AX              ; Save original angle
    XOR DI, DI              ; DI will accumulate the sum
    
    ; For a modulated sine wave, we need sidebands
    ; around the carrier frequency
    
    ; Calculate DC component (usually near zero for AM modulation)
    ; For simplicity, we'll just start with the first harmonic
    
    MOV BX, 1               ; Current harmonic (n)
    
MODULATED_FOURIER_LOOP:
    PUSH CX                 ; Save loop counter
    PUSH BX                 ; Save current harmonic
    
    ; Calculate carrier term (at 4n)
    MOV AX, SI              ; Load original angle
    MOV CX, BX
    SHL CX, 2               ; 4 times the harmonic for carrier
    IMUL CX                 ; Multiply angle by 4n
    CALL CALC_SIN           ; Result in AX, scaled by 100
    
    ; Calculate coefficient (scaled based on harmonic)
    MOV CX, 30              ; Base amplitude (reduced from 50)
    IMUL CX                 ; DX:AX = sin(4nx) * 30
    MOV CX, 100
    IDIV CX                 ; Normalize
    
    ; Scale by 1/n
    POP BX                  ; Restore harmonic number
    PUSH BX                 ; Save it again
    CWD                     ; Sign-extend AX into DX
    IDIV BX                 ; AX = result / n
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Calculate lower sideband term (at 4n-1)
    MOV AX, SI              ; Load original angle
    MOV CX, BX
    SHL CX, 2               ; 4 times the harmonic
    DEC CX                  ; 4n-1 for lower sideband
    CMP CX, 0               ; Skip if frequency would be negative
    JLE SKIP_LOWER_SIDEBAND
    
    IMUL CX                 ; Multiply angle by (4n-1)
    CALL CALC_SIN           ; Result in AX, scaled by 100
    
    ; Calculate coefficient for lower sideband (half of carrier)
    MOV CX, 15              ; Half amplitude (reduced from 25)
    IMUL CX                 ; DX:AX = sin((4n-1)x) * 15
    MOV CX, 100
    IDIV CX                 ; Normalize
    
    ; Scale by 1/n
    POP BX                  ; Restore harmonic number
    PUSH BX                 ; Save it again
    CWD                     ; Sign-extend AX into DX
    IDIV BX                 ; AX = result / n
    
    ; Add to accumulator
    ADD DI, AX
    
SKIP_LOWER_SIDEBAND:
    
    ; Calculate upper sideband term (at 4n+1)
    MOV AX, SI              ; Load original angle
    MOV CX, BX
    SHL CX, 2               ; 4 times the harmonic
    INC CX                  ; 4n+1 for upper sideband
    
    IMUL CX                 ; Multiply angle by (4n+1)
    CALL CALC_SIN           ; Result in AX, scaled by 100
    
    ; Calculate coefficient for upper sideband (half of carrier)
    MOV CX, 15              ; Half amplitude (reduced from 25)
    IMUL CX                 ; DX:AX = sin((4n+1)x) * 15
    MOV CX, 100
    IDIV CX                 ; Normalize
    
    ; Scale by 1/n
    POP BX                  ; Restore harmonic number
    PUSH BX                 ; Save it again
    CWD                     ; Sign-extend AX into DX
    IDIV BX                 ; AX = result / n
    
    ; Add to accumulator
    ADD DI, AX
    
    ; Move to next harmonic
    POP BX                  ; Restore harmonic number
    INC BX                  ; Next harmonic
    
    POP CX                  ; Restore loop counter
    LOOP MODULATED_FOURIER_LOOP
    
    MOV AX, DI              ; Return final sum
    
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    RET
CALC_MODULATED_FOURIER ENDP

; Procedure to plot a point based on screen coordinates
; Input: CX = x-coordinate (0-319)
;        DX = y-coordinate (0-199)
;        AL = color
PLOT_POINT PROC
    PUSH AX
    PUSH BX
    
    ; Check if coordinates are within screen bounds
    CMP CX, 0
    JL SKIP_PLOT
    CMP CX, SCREEN_WIDTH-1
    JG SKIP_PLOT
    CMP DX, 0
    JL SKIP_PLOT
    CMP DX, SCREEN_HEIGHT-1
    JG SKIP_PLOT
    
    MOV AH, 0Ch             ; Write pixel function
    MOV BH, 0               ; Page number
    INT 10h
    
SKIP_PLOT:
    POP BX
    POP AX
    RET
PLOT_POINT ENDP

; Procedure to clear the screen
CLEAR_SCREEN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AH, 0          ; Set video mode
    MOV AL, 13h        ; 320x200 graphics mode
    INT 10h
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CLEAR_SCREEN ENDP

; Procedure to plot square wave
PLOT_SQUARE PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate square wave for this angle
    CALL CALC_SQUARE     ; Result in AX
    
    ; Scale square wave value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = square wave * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled square wave
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_SQUARE
    RET
PLOT_SQUARE ENDP

; Procedure to plot Fourier series of square wave
PLOT_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for this angle
    CALL CALC_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_FOURIER
    RET
PLOT_FOURIER ENDP

; Procedure to plot rectified sine wave
PLOT_RECTIFIED PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate sine for this angle
    CALL CALC_SIN        ; Result in AX
    
    ; Take absolute value of sine (for full-wave rectification)
    CMP AX, 0
    JGE SKIP_ABS        ; If value is positive, skip negation
    NEG AX              ; Make negative value positive
SKIP_ABS:
    
    ; Scale rectified sine value [0,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = rectified_sine * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled rectified sine
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_RECTIFIED
    RET
PLOT_RECTIFIED ENDP

; Procedure to plot Fourier series of rectified sine wave
PLOT_RECTIFIED_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for rectified sine
    CALL CALC_RECTIFIED_FOURIER  ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [0,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX               ; Invert Y (screen has origin at top-left)
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_RECTIFIED_FOURIER
    RET
PLOT_RECTIFIED_FOURIER ENDP

; Procedure to plot triangle wave
PLOT_TRIANGLE PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate triangle wave for this angle
    CALL CALC_TRIANGLE   ; Result in AX
    
    ; Scale triangle value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = triangle * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled triangle
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_TRIANGLE
    RET
PLOT_TRIANGLE ENDP

; Procedure to plot Fourier series of triangle wave
PLOT_TRIANGLE_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for triangle wave
    CALL CALC_TRIANGLE_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_TRIANGLE_FOURIER
    RET
PLOT_TRIANGLE_FOURIER ENDP

; Procedure to plot sawtooth wave
PLOT_SAWTOOTH PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate sawtooth wave for this angle
    CALL CALC_SAWTOOTH   ; Result in AX
    
    ; Scale sawtooth value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = sawtooth * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled sawtooth
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_SAWTOOTH
    RET
PLOT_SAWTOOTH ENDP

; Procedure to plot Fourier series of sawtooth wave
PLOT_SAWTOOTH_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for sawtooth wave
    CALL CALC_SAWTOOTH_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_SAWTOOTH_FOURIER
    RET
PLOT_SAWTOOTH_FOURIER ENDP

; Procedure to plot pulse train
PLOT_PULSE PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees with higher frequency
    MOV AX, CX
    MOV BX, 900          ; 9 * 100 (doubled frequency)
    IMUL BX              ; DX:AX = CX * 9 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate pulse train for this angle
    CALL CALC_PULSE      ; Result in AX
    
    ; Scale pulse value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = pulse * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled pulse
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_PULSE
    RET
PLOT_PULSE ENDP

; Procedure to plot Fourier series of pulse train
PLOT_PULSE_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees with higher frequency
    MOV AX, CX
    MOV BX, 900          ; 9 * 100 (doubled frequency)
    IMUL BX              ; DX:AX = CX * 9 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for pulse train
    CALL CALC_PULSE_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_PULSE_FOURIER
    RET
PLOT_PULSE_FOURIER ENDP

; Procedure to plot step function
PLOT_STEP PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate step function for this angle
    CALL CALC_STEP       ; Result in AX
    
    ; Scale step value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = step * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled step
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_STEP
    RET
PLOT_STEP ENDP

; Procedure to plot Fourier series of step function
PLOT_STEP_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for step function
    CALL CALC_STEP_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_STEP_FOURIER
    RET
PLOT_STEP_FOURIER ENDP

; Procedure to plot piecewise linear function
PLOT_PIECEWISE PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate piecewise function for this angle
    CALL CALC_PIECEWISE  ; Result in AX
    
    ; Scale piecewise value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = piecewise * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled piecewise
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_PIECEWISE
    RET
PLOT_PIECEWISE ENDP

; Procedure to plot Fourier series of piecewise linear function
PLOT_PIECEWISE_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for piecewise linear function
    CALL CALC_PIECEWISE_FOURIER    ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_PIECEWISE_FOURIER
    RET
PLOT_PIECEWISE_FOURIER ENDP

; Procedure to plot modulated sine wave
PLOT_MODULATED PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Calculate modulated sine for this angle
    CALL CALC_MODULATED  ; Result in AX
    
    ; Scale value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = modulated * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled modulated
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_MODULATED
    RET
PLOT_MODULATED ENDP

; Procedure to plot Fourier series of modulated sine wave
PLOT_MODULATED_FOURIER PROC
    ; Save current X position
    PUSH CX
    PUSH AX              ; Save color
    
    ; Calculate angle based on x-coordinate
    SUB CX, X_CENTER     ; Adjust to center (now [-160,160])
    
    ; Scale CX to angle in degrees
    MOV AX, CX
    MOV BX, 450          ; 4.5 * 100
    IMUL BX              ; DX:AX = CX * 4.5 * 100
    MOV BX, 100
    IDIV BX              ; AX = angle in degrees
    
    ; Add X offset
    ADD AX, [X_OFFSET]   ; Add current X offset
    
    ; Push number of terms for Fourier calculation
    PUSH CX
    MOV CX, [BP-2]       ; Get current number of terms
    
    ; Calculate Fourier series for modulated sine
    CALL CALC_MODULATED_FOURIER  ; Result in AX
    
    POP CX
    
    ; Scale Fourier value [-100,100] to screen y-coordinate
    MOV BX, VERTICAL_SCALE
    IMUL BX              ; DX:AX = Fourier * scale
    MOV BX, 100
    CWD                  ; Sign-extend AX into DX
    IDIV BX              ; AX = scaled Fourier value
    
    ; Convert to screen coordinates
    NEG AX
    ADD AX, Y_CENTER     ; Center on y-axis
    
    ; Draw the pixel
    MOV DX, AX
    POP AX               ; Restore color in AL
    POP CX               ; Restore X position
    
    CALL PLOT_POINT
    
    ; Move to next pixel
    INC CX
    CMP CX, SCREEN_WIDTH
    JL PLOT_MODULATED_FOURIER
    RET
PLOT_MODULATED_FOURIER ENDP

MAIN PROC
    MOV AX, @DATA       ; Initialize data segment
    MOV DS, AX
    
    ; Create stack frame
    PUSH BP
    MOV BP, SP
    SUB SP, 2           ; Local variable for terms counter
    
    ; Initialize terms counter
    MOV AX, INITIAL_TERMS
    MOV [BP-2], AX
    
    ; Clear screen and set text mode
    MOV AH, 0
    MOV AL, 3           ; Text mode 80x25
    INT 10h
    
    ; Display welcome message
    MOV AH, 9
    LEA DX, WELCOME_MSG
    INT 21h

MENU_START:    
MENU_LOOP:
    ; Display menu
    MOV AH, 9
    LEA DX, MENU_MSG
    INT 21h
    
    ; Get user input
    MOV AH, 1
    INT 21h
    SUB AL, '0'         ; Convert ASCII to number
    
    ; Store choice
    MOV [CHOICE], AL
    
    ; Clear all draw flags
    MOV [DRAW_SQUARE], 0
    MOV [DRAW_RECTIFIED], 0
    MOV [DRAW_TRIANGLE], 0
    MOV [DRAW_SAWTOOTH], 0
    MOV [DRAW_PULSE], 0
    MOV [DRAW_STEP], 0
    MOV [DRAW_PIECEWISE], 0
    MOV [DRAW_MODULATED], 0
    
    ; Validate and set appropriate flag
    CMP AL, 1
    JB INVALID_CHOICE
    CMP AL, 8            ; Updated to include modulated sine wave option
    JA INVALID_CHOICE
    
    CMP AL, 1
    JNE CHECK_CHOICE_2
    MOV [DRAW_SQUARE], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_2:
    CMP AL, 2
    JNE CHECK_CHOICE_3
    MOV [DRAW_RECTIFIED], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_3:
    CMP AL, 3
    JNE CHECK_CHOICE_4
    MOV [DRAW_TRIANGLE], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_4:
    CMP AL, 4
    JNE CHECK_CHOICE_5
    MOV [DRAW_SAWTOOTH], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_5:
    CMP AL, 5
    JNE CHECK_CHOICE_6
    MOV [DRAW_PULSE], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_6:
    CMP AL, 6
    JNE CHECK_CHOICE_7
    MOV [DRAW_STEP], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_7:
    CMP AL, 7
    JNE CHECK_CHOICE_8
    MOV [DRAW_PIECEWISE], 1
    JMP VALID_CHOICE
    
CHECK_CHOICE_8:
    MOV [DRAW_MODULATED], 1
    JMP VALID_CHOICE

INVALID_CHOICE:
    MOV AH, 9
    LEA DX, INVALID_MSG
    INT 21h
    JMP MENU_LOOP
    
VALID_CHOICE:
    ; Switch to graphics mode
    MOV AH, 0
    MOV AL, 13h
    INT 10h
    
    ; Reset X offset
    MOV [X_OFFSET], 0

MAIN_LOOP:
    CALL CLEAR_SCREEN
    
    ; Draw coordinate system (axes and labels)
    MOV CX, 0       ; Starting X coordinate
    MOV DX, 100     ; Y coordinate (middle of screen)
    MOV AL, 15      ; White color
    MOV AH, 0Ch     ; Write pixel function
    
    DRAW_X_AXIS:
        INT 10h     ; Draw pixel
        INC CX      ; Move right
        CMP CX, 320 ; Check if reached end of screen
        JNE DRAW_X_AXIS
    
    ; Draw Y-axis (vertical line) in white
    MOV CX, 160     ; X coordinate (middle of screen)
    MOV DX, 0       ; Starting Y coordinate
    
    DRAW_Y_AXIS:
        INT 10h     ; Draw pixel
        INC DX      ; Move down
        CMP DX, 200 ; Check if reached bottom of screen
        JNE DRAW_Y_AXIS
    
    ; Draw Y-axis labels
    ; +1.5 (at y=0)
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 2           ; Row
    MOV DL, 21          ; Column
    INT 10h
    MOV AH, 09h
    LEA DX, POS_1_5
    INT 21h
    
    ; +1 (at y=33)
    MOV AH, 02h
    MOV DH, 5
    MOV DL, 21
    INT 10h
    MOV AH, 09h
    LEA DX, POS_1
    INT 21h
    
    ; +0.5 (at y=67)
    MOV AH, 02h
    MOV DH, 8
    MOV DL, 21
    INT 10h
    MOV AH, 09h
    LEA DX, POS_0_5
    INT 21h
    
    ; -0.5 (at y=133)
    MOV AH, 02h
    MOV DH, 17
    MOV DL, 21
    INT 10h
    MOV AH, 09h
    LEA DX, NEG_0_5
    INT 21h
    
    ; -1 (at y=167)
    MOV AH, 02h
    MOV DH, 20
    MOV DL, 21
    INT 10h
    MOV AH, 09h
    LEA DX, NEG_1
    INT 21h
    
    ; -1.5 (at y=200)
    MOV AH, 02h
    MOV DH, 23
    MOV DL, 21
    INT 10h
    MOV AH, 09h
    LEA DX, NEG_1_5
    INT 21h

    ; Draw X-axis labels based on current offset
    ; Calculate which labels to show based on X_OFFSET
    MOV AX, [X_OFFSET]
    
    ; First label (leftmost)
    MOV AH, 02h         ; Set cursor position
    MOV BH, 0           ; Page number
    MOV DH, 13          ; Row (below x-axis)
    MOV DL, 3           ; Column (leftmost)
    INT 10h
    MOV AH, 09h         ; Display string
    
    CMP WORD PTR [X_OFFSET], 0
    JE SHOW_NEG_2PI_FIRST    ; If centered, show -2pi
    JL SHOW_NEG_3PI_FIRST    ; If offset negative, show -3pi
    LEA DX, NEG_PI          ; If offset positive, show -pi
    JMP DISPLAY_FIRST
    
SHOW_NEG_3PI_FIRST:
    LEA DX, NEG_3PI
    JMP DISPLAY_FIRST
    
SHOW_NEG_2PI_FIRST:
    LEA DX, NEG_2PI
    
DISPLAY_FIRST:
    INT 21h
    
    ; Second label
    MOV AH, 02h
    MOV DH, 13
    MOV DL, 12          ; Adjusted column position
    INT 10h
    MOV AH, 09h
    
    CMP WORD PTR [X_OFFSET], 0
    JE SHOW_NEG_PI_SECOND    ; If centered, show -pi
    JL SHOW_NEG_2PI_SECOND   ; If offset negative, show -2pi
    LEA DX, ZERO            ; If offset positive, show 0
    JMP DISPLAY_SECOND
    
SHOW_NEG_2PI_SECOND:
    LEA DX, NEG_2PI
    JMP DISPLAY_SECOND
    
SHOW_NEG_PI_SECOND:
    LEA DX, NEG_PI
    
DISPLAY_SECOND:
    INT 21h
    
    ; Third label (center)
    MOV AH, 02h
    MOV DH, 13
    MOV DL, 20          ; Center position
    INT 10h
    MOV AH, 09h
    
    CMP WORD PTR [X_OFFSET], 0
    JE SHOW_ZERO_THIRD      ; If centered, show 0
    JL SHOW_NEG_PI_THIRD    ; If offset negative, show -pi
    LEA DX, POS_PI         ; If offset positive, show pi
    JMP DISPLAY_THIRD
    
SHOW_NEG_PI_THIRD:
    LEA DX, NEG_PI
    JMP DISPLAY_THIRD
    
SHOW_ZERO_THIRD:
    LEA DX, ZERO
    
DISPLAY_THIRD:
    INT 21h
    
    ; Fourth label
    MOV AH, 02h
    MOV DH, 13
    MOV DL, 28          ; Adjusted column position
    INT 10h
    MOV AH, 09h
    
    CMP WORD PTR [X_OFFSET], 0
    JE SHOW_PI_FOURTH       ; If centered, show pi
    JL SHOW_ZERO_FOURTH     ; If offset negative, show 0
    LEA DX, POS_2PI        ; If offset positive, show 2pi
    JMP DISPLAY_FOURTH
    
SHOW_ZERO_FOURTH:
    LEA DX, ZERO
    JMP DISPLAY_FOURTH
    
SHOW_PI_FOURTH:
    LEA DX, POS_PI
    
DISPLAY_FOURTH:
    INT 21h
    
    ; Fifth label (rightmost)
    MOV AH, 02h
    MOV DH, 13
    MOV DL, 37          ; Adjusted rightmost position
    INT 10h
    MOV AH, 09h
    
    CMP WORD PTR [X_OFFSET], 0
    JE SHOW_2PI_FIFTH       ; If centered, show 2pi
    JL SHOW_PI_FIFTH        ; If offset negative, show pi
    LEA DX, POS_3PI        ; If offset positive, show 3pi
    JMP DISPLAY_FIFTH
    
SHOW_PI_FIFTH:
    LEA DX, POS_PI
    JMP DISPLAY_FIFTH
    
SHOW_2PI_FIFTH:
    LEA DX, POS_2PI
    
DISPLAY_FIFTH:
    INT 21h

    ; Constant for angle mapping: 8π radians = 1440 degrees
    ; 320 pixels = 1440 degrees, so 1 pixel = 4.5 degrees

    ; Draw selected function and its Fourier series based on flags
    CMP [DRAW_SQUARE], 1
    JE DRAW_SQUARE_WAVE
    JMP CHECK_RECTIFIED

DRAW_SQUARE_WAVE:
    ; Draw square wave and its Fourier series
    MOV AL, 2            ; Green color
    MOV CX, 0
    CALL PLOT_SQUARE
    MOV AL, 5            ; Purple color
    MOV CX, 0
    CALL PLOT_FOURIER
    JMP CHECK_RECTIFIED

CHECK_RECTIFIED:
    CMP [DRAW_RECTIFIED], 1
    JE DRAW_RECTIFIED_WAVE
    JMP CHECK_TRIANGLE_WAVE

DRAW_RECTIFIED_WAVE:
    ; Draw rectified sine and its Fourier series
    MOV AL, 3            ; Cyan color
    MOV CX, 0
    CALL PLOT_RECTIFIED
    MOV AL, 15           ; White color
    MOV CX, 0
    CALL PLOT_RECTIFIED_FOURIER
    JMP CHECK_TRIANGLE_WAVE

CHECK_TRIANGLE_WAVE:
    CMP [DRAW_TRIANGLE], 1
    JE DRAW_TRIANGLE_WAVE
    JMP CHECK_SAWTOOTH_WAVE

DRAW_TRIANGLE_WAVE:
    ; Draw triangle wave and its Fourier series
    MOV AL, 6            ; Orange color
    MOV CX, 0
    CALL PLOT_TRIANGLE
    MOV AL, 13           ; Light magenta color
    MOV CX, 0
    CALL PLOT_TRIANGLE_FOURIER
    JMP CHECK_SAWTOOTH_WAVE

CHECK_SAWTOOTH_WAVE:
    CMP [DRAW_SAWTOOTH], 1
    JE DRAW_SAWTOOTH_WAVE
    JMP CHECK_PULSE_WAVE

DRAW_SAWTOOTH_WAVE:
    ; Draw sawtooth wave and its Fourier series
    MOV AL, 9            ; Light blue color
    MOV CX, 0
    CALL PLOT_SAWTOOTH
    MOV AL, 11           ; Light cyan color
    MOV CX, 0
    CALL PLOT_SAWTOOTH_FOURIER
    JMP CHECK_PULSE_WAVE

CHECK_PULSE_WAVE:
    CMP [DRAW_PULSE], 1
    JE DRAW_PULSE_WAVE
    JMP CHECK_STEP_WAVE

DRAW_PULSE_WAVE:
    ; Draw pulse train and its Fourier series
    MOV AL, 4            ; Red color
    MOV CX, 0
    CALL PLOT_PULSE
    MOV AL, 12           ; Light red color
    MOV CX, 0
    CALL PLOT_PULSE_FOURIER
    JMP CHECK_STEP_WAVE

CHECK_STEP_WAVE:
    CMP [DRAW_STEP], 1
    JE DRAW_STEP_WAVE
    JMP CHECK_PIECEWISE

DRAW_STEP_WAVE:
    ; Draw step function and its Fourier series
    MOV AL, 14           ; Yellow color
    MOV CX, 0
    CALL PLOT_STEP
    MOV AL, 10           ; Light green color
    MOV CX, 0
    CALL PLOT_STEP_FOURIER
    JMP CHECK_PIECEWISE

CHECK_PIECEWISE:
    CMP [DRAW_PIECEWISE], 1
    JE DRAW_PIECEWISE_WAVE
    JMP CHECK_MODULATED

DRAW_PIECEWISE_WAVE:
    ; Draw piecewise linear function and its Fourier series
    MOV AL, 1            ; Blue color
    MOV CX, 0
    CALL PLOT_PIECEWISE
    MOV AL, 7            ; Light gray color
    MOV CX, 0
    CALL PLOT_PIECEWISE_FOURIER
    JMP CHECK_MODULATED

CHECK_MODULATED:
    CMP [DRAW_MODULATED], 1
    JE DRAW_MODULATED_WAVE
    JMP CHECK_KEYS

DRAW_MODULATED_WAVE:
    ; Draw modulated sine wave and its Fourier series
    MOV AL, 2            ; Green color (changed from gray)
    MOV CX, 0
    CALL PLOT_MODULATED
    MOV AL, 14           ; Yellow color (changed from white)
    MOV CX, 0
    CALL PLOT_MODULATED_FOURIER
    JMP CHECK_KEYS

CHECK_KEYS:
    ; Wait for keypress and handle keys
    MOV AH, 0
    INT 16h
    
    ; Check which key was pressed
    CMP AH, 4Bh          ; Left arrow
    JE DO_MOVE_LEFT
    
    CMP AH, 4Dh          ; Right arrow
    JE DO_MOVE_RIGHT
    
    CMP AL, 1Bh          ; ESC key
    JE DO_EXIT
    
    CMP AL, 20h          ; Space key
    JE DO_ADD_TERMS
    
    CMP AL, 60h          ; Backtick key (`)
    JE DO_RETURN_TO_MENU
    
    JMP MAIN_LOOP        ; If no key matched, just redraw

DO_MOVE_LEFT:
    ; Move viewport left by pi (180 degrees)
    MOV AX, [X_OFFSET]
    SUB AX, 180
    MOV [X_OFFSET], AX
    JMP MAIN_LOOP

DO_MOVE_RIGHT:
    ; Move viewport right by pi (180 degrees)
    MOV AX, [X_OFFSET]
    ADD AX, 180
    MOV [X_OFFSET], AX
    JMP MAIN_LOOP

DO_ADD_TERMS:
    ; Add three more terms if not at maximum
    MOV AX, [BP-2]       ; Get current number of terms
    
    ; Check which function is being displayed
    CMP [DRAW_MODULATED], 1
    JNE CHECK_OTHER_WAVES
    
    ; If modulated sine wave, use MODULATED_MAX_TERMS
    CMP AX, MODULATED_MAX_TERMS
    JGE CONTINUE_MAIN    ; If at maximum, just redraw
    ADD AX, 3            ; Add three more terms
    MOV [BP-2], AX       ; Store new number of terms
    JMP CONTINUE_MAIN
    
CHECK_OTHER_WAVES:
    ; For other waves, use regular MAX_TERMS
    CMP AX, MAX_TERMS
    JGE CONTINUE_MAIN    ; If at maximum, just redraw
    ADD AX, 3            ; Add three more terms
    MOV [BP-2], AX       ; Store new number of terms
CONTINUE_MAIN:
    JMP MAIN_LOOP

DO_RETURN_TO_MENU:
    ; Reset the terms counter
    MOV AX, INITIAL_TERMS
    MOV [BP-2], AX
    ; Return to text mode and show menu
    JMP MENU_START

DO_EXIT:
    ; Restore stack frame
    MOV SP, BP
    POP BP
    
    ; Exit program
    MOV AH, 4Ch         
    INT 21h
MAIN ENDP

END MAIN

