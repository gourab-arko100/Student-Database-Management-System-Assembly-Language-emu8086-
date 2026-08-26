

.MODEL SMALL

; -----MACRO DEFINITIONS-----

SHOW MACRO MSG_ADDR
    LEA DX, MSG_ADDR
    MOV AH, 9
    INT 21H
ENDM

NEWLINE MACRO
    MOV AH, 2
    MOV DL, 13
    INT 21H
    MOV DL, 10
    INT 21H
ENDM

.STACK 100H

.DATA

; -----GLOBAL CONSTANTS & CONFIGURATION-----

TEACHER_ID   DW 9999
TEACHER_PASS DW 1234

count        DW 5
currIndex    DW ?

; -----STUDENT DATABASE (PARALLEL ARRAYS)-----

studentIDs    DW 1001, 1002, 1003, 1004, 1005, 5 DUP(0)
passwords     DW 1111, 2222, 3333, 4444, 5555, 5 DUP(0)

; ===== FIX: initials changed from DB to DW =====
; 3 initials per student, each stored as a WORD (low byte holds the letter)
; total = 10 students * 3 initials = 30 WORDS


initials      DW 'A','A','A',  'B','B','B',  'C','C','C',  'D','D','D',  'E','E','E',  15 DUP(' ')

; -----DATA: MARKS & RESULTS (PARALLEL ARRAYS)-----

marksQuiz     DW 20, 25, 15, 10, 22, 5 DUP(0)
marksLab      DW 14, 15, 10, 12, 13, 5 DUP(0)
marksMid      DW 22, 24, 15, 12, 20, 5 DUP(0)
marksFinal    DW 30, 34, 20, 15, 25, 5 DUP(0)

totalMarks    DW 86, 98, 60, 49, 80, 5 DUP(0)
percentage    DW 86, 98, 60, 49, 80, 5 DUP(0)

gradeLetter   DW 'B', 'A', 'D', 'F', 'B', 5 DUP('-')

; =====MESSAGES & UI=====

msgMain      DB 13, 10, '=== MAIN MENU ===', 13, 10, '1. Login', 13, 10, '2. Exit', 13, 10, 'Choice: $'

msgTMenu     DB 13, 10, 13, 10, '--- TEACHER MENU ---', 13, 10, '1. Register New Student', 13, 10, '2. View All Students', 13, 10, '3. Update Marks', 13, 10, '4. Search Student', 13, 10, '5. Sort by Total', 13, 10, '6. Class Stats', 13, 10, '7. Spreadsheet View', 13, 10, '8. Edit Name', 13, 10, '9. Logout', 13, 10, 'Choice: $'

msgSMenu     DB 13, 10, 13, 10, '--- STUDENT MENU ---', 13, 10, '1. View My Profile & Result', 13, 10, '2. Logout', 13, 10, 'Choice: $'

msgLogin     DB 13, 10, '--- LOGIN PAGE ---', 13, 10, 'Enter ID: $'
msgPass      DB 13, 10, 'Enter Password: $'
msgFail      DB 13, 10, 'Login Failed! Invalid Credentials.$'
msgFull      DB 13, 10, 'Error: Database is Full!$'
msgSucc      DB 13, 10, 'Success! Student Registered.$'
msgErr4Dig   DB 13, 10, 'Error: Must be 4 digits (1000-9999).$'

msgAskID     DB 13, 10, 'New Student ID (4 Digits): $'
msgAskPass   DB 13, 10, 'New Password (4 Digits): $'
msgAskInit   DB 13, 10, 'Enter 3 Initials: $'

msgList      DB 13, 10, 'ID    | Initials', 13, 10, '$'
msgSpace     DB '  | $'
msgProfile   DB 13, 10, 'My ID: $'

msgEnterID   DB 13, 10, 'Enter Student ID to Modify: $'
msgNotFound  DB 13, 10, 'Error: Student ID Not Found.$'
msgNameUpd   DB 13, 10, 'Name Updated Successfully.$'
msgInvalidMark DB 13, 10, 'Error: Mark exceeds limit! Try again.$'

msgMarkMenu  DB 13, 10, 13, 10, 'Which mark to update?', 13, 10, '1. Quiz (Max 25)', 13, 10, '2. Lab (Max 15)', 13, 10, '3. Midterm (Input 50 -> Conv 25)', 13, 10, '4. Final (Input 150 -> Conv 35)', 13, 10, '5. Back', 13, 10, 'Choice: $'

msgInQuiz    DB 13, 10, 'Enter Quiz Mark (Out of 25): $'
msgInLab     DB 13, 10, 'Enter Lab Mark (Out of 15): $'
msgInMid     DB 13, 10, 'Enter Midterm Mark (Out of 50, will convert to 25): $'
msgInFin     DB 13, 10, 'Enter Final Mark (Out of 150, will convert to 35): $'
msgSaved     DB ' [Saved]$'

msgMarksUpd  DB 13, 10, 'Marks Updated & Grades Recalculated.$'

msgSheetHead DB 13, 10, 'ID   | Qz | Lb | Md | Fn | Tot | Gr', 13, 10, '-----------------------------------$'
msgBar       DB ' | $'

msgResHead   DB 13, 10, 'ID     | Total | Grade', 13, 10, '$'
msgSortDone  DB 13, 10, 'Database Sorted by Total Marks (Descending).$'

msgStatHead  DB 13, 10, '--- CLASS STATISTICS ---', 13, 10, '$'
msgHigh      DB 13, 10, 'Highest Total: $'
msgLow       DB 13, 10, 'Lowest Total:  $'
msgAvg       DB 13, 10, 'Class Average: $'
msgTopper    DB 13, 10, 'Topper ID: $'

msgResult    DB 13, 10, '--- RESULT ---', 13, 10, 'Quiz: $'
msgLabLbl    DB '  Lab: $'
msgMidLbl    DB '  Mid: $'
msgFinLbl    DB '  Final: $'
msgTotLbl    DB 13, 10, 'Total: $'
msgGrdLbl    DB '  Grade: $'

; --- Variables for Input/Output Procedures ---
digit        DB ?
number       DW ?
tempID       DW ?
tempPass     DW ?
tempInit     DB 3 DUP(?)

.CODE

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

MAIN_LOOP:
    SHOW msgMain

    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE  DO_LOGIN
    CMP AL, '2'
    JE  EXIT_PROG
    JMP MAIN_LOOP

DO_LOGIN:
    CALL LOGIN_PROC
    JMP MAIN_LOOP

EXIT_PROG:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP


; -----PROCEDURE: LOGIN_PROC-----

LOGIN_PROC PROC
    NEWLINE
    SHOW msgLogin
    CALL ReadNum
    MOV BX, number

    SHOW msgPass
    CALL ReadNum
    MOV CX, number

    CMP BX, TEACHER_ID
    JNE CHECK_STUDENT
    CMP CX, TEACHER_PASS
    JNE LOGIN_FAIL

    CALL TEACHER_MENU
    RET

CHECK_STUDENT:
    PUSH BX
    PUSH CX

    MOV CX, count
    CMP CX, 0
    JE RESTORE_FAIL

    MOV SI, 0

SEARCH_LOOP:
    MOV AX, studentIDs[SI]
    CMP AX, BX
    JNE NEXT_ST

    MOV AX, passwords[SI]
    POP CX
    PUSH CX
    CMP AX, CX
    JE LOGIN_SUCCESS_S

NEXT_ST:
    ADD SI, 2
    LOOP SEARCH_LOOP

RESTORE_FAIL:
    POP CX
    POP BX
    JMP LOGIN_FAIL

LOGIN_SUCCESS_S:
    POP CX
    POP BX
    MOV currIndex, SI
    CALL STUDENT_MENU
    RET

LOGIN_FAIL:
    SHOW msgFail
    RET
LOGIN_PROC ENDP


; -----PROCEDURE: TEACHER_MENU-----

TEACHER_MENU PROC
T_LOOP:
    SHOW msgTMenu
    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE DO_REG
    CMP AL, '2'
    JE DO_VIEW
    CMP AL, '3'
    JE DO_MARKS
    CMP AL, '4'
    JE DO_SEARCH
    CMP AL, '5'
    JE DO_SORT
    CMP AL, '6'
    JE DO_STATS
    CMP AL, '7'
    JE DO_SHEET
    CMP AL, '8'
    JE DO_EDITNAME
    CMP AL, '9'
    JE T_EXIT
    JMP T_LOOP

DO_REG:      CALL REGISTER_STUDENT     
            JMP T_LOOP
DO_VIEW:     CALL VIEW_ALL
            JMP T_LOOP
DO_MARKS:    CALL ENTER_MARKS
            JMP T_LOOP
DO_SEARCH:   CALL SEARCH_STUDENT
            JMP T_LOOP
DO_SORT:     CALL SORT_STUDENTS
            JMP T_LOOP
DO_STATS:    CALL CLASS_STATS
            JMP T_LOOP
DO_SHEET:    CALL VIEW_SPREADSHEET
            JMP T_LOOP
DO_EDITNAME: CALL EDIT_STUDENT_NAME
            JMP T_LOOP

T_EXIT:
    RET
TEACHER_MENU ENDP


; -----PROCEDURE: STUDENT_MENU-----

STUDENT_MENU PROC
S_LOOP:
    SHOW msgSMenu
    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE SHOW_PROFILE_FULL
    CMP AL, '2'
    JE S_EXIT
    JMP S_LOOP

SHOW_PROFILE_FULL:
    SHOW msgProfile
    MOV SI, currIndex
    MOV AX, studentIDs[SI]
    CALL PrintNum
    CALL SHOW_STUDENT_RESULT
    JMP S_LOOP

S_EXIT:
    RET
STUDENT_MENU ENDP


; -----PROCEDURE: REGISTER_STUDENT-----


REGISTER_STUDENT PROC
    ; Check capacity
    MOV AX, count
    CMP AX, 10
    JGE FULL_ERR

; ---------- Input + validate ID ----------
REG_ID_AGAIN:
    SHOW msgAskID
    CALL ReadNum
    MOV AX, number

    ; Range check 1000-9999
    CMP AX, 1000
    JL ID_INVALID
    CMP AX, 9999
    JG ID_INVALID

    ; Duplicate ID check (scan existing IDs 0..count-1)
    PUSH AX                 ; save new ID in stack
    MOV CX, count
    MOV DI, 0               ; DI = offset into studentIDs (0,2,4,...)

CHECK_DUP_LOOP:
    CMP CX, 0
    JE  DUP_OK
    MOV BX, studentIDs[DI]
    CMP BX, AX              ; compare existing with new ID
    JE  DUP_FOUND
    ADD DI, 2
    DEC CX
    JMP CHECK_DUP_LOOP

DUP_FOUND:
    POP AX
    ;
    ; SHOW msgDupID
    SHOW msgNotFound
    JMP REG_ID_AGAIN

DUP_OK:
    POP AX                  ; restore new ID

    ; Store ID at index = count (word offset count*2)
    MOV SI, count
    ADD SI, SI
    MOV studentIDs[SI], AX

; ---------- Input + validate Password ----------
REG_PASS_AGAIN:
    SHOW msgAskPass
    CALL ReadNum
    MOV AX, number

    CMP AX, 1000
    JL PASS_INVALID
    CMP AX, 9999
    JG PASS_INVALID

    MOV passwords[SI], AX

; ---------- Input Initials (DW storage) ----------
    ; initials: 3 WORDS per student => 6 bytes per student
    SHOW msgAskInit
    MOV AX, count
    MOV BX, 6
    MUL BX
    MOV DI, AX              ; DI = initials byte offset

    ; Read 3 chars, store as WORDs (AL=char, AH=0)
    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI], AX

    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI+2], AX

    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI+4], AX

    ; (Optional but recommended) swallow Enter if user pressed it
    MOV AH, 1
    INT 21H
    CMP AL, 13
    JE  INIT_DONE
    ; if not Enter, it's a real char—ignore it (or handle as you like)
INIT_DONE:

; ---------- Initialize Marks + Results ----------
    MOV marksQuiz[SI], 0
    MOV marksLab[SI], 0
    MOV marksMid[SI], 0
    MOV marksFinal[SI], 0
    MOV totalMarks[SI], 0
    MOV percentage[SI], 0
    MOV gradeLetter[SI], 'F'

    ; Commit
    INC count
    SHOW msgSucc
    RET

ID_INVALID:
    SHOW msgErr4Dig
    JMP REG_ID_AGAIN

PASS_INVALID:
    SHOW msgErr4Dig
    JMP REG_PASS_AGAIN

FULL_ERR:
    SHOW msgFull
    RET
REGISTER_STUDENT ENDP



; -----PROCEDURE: VIEW_ALL-----


VIEW_ALL PROC
    SHOW msgList

    MOV CX, count
    CMP CX, 0
    JE VIEW_DONE

    MOV SI, 0  ; ID word index (0,2,4,...)
    MOV DI, 0  ; initials byte offset (0,6,12,...)

PRINT_LOOP:
    NEWLINE

    MOV AX, studentIDs[SI]
    CALL PrintNum

    SHOW msgSpace

    ; print 3 initials (WORD each): DL = low byte (AL)
    MOV AX, initials[DI]
    MOV DL, AL
    MOV AH, 2
    INT 21H

    MOV AX, initials[DI+2]
    MOV DL, AL
    MOV AH, 2
    INT 21H

    MOV AX, initials[DI+4]
    MOV DL, AL
    MOV AH, 2
    INT 21H

    ADD SI, 2
    ADD DI, 6
    LOOP PRINT_LOOP

VIEW_DONE:
    RET
VIEW_ALL ENDP


; -----PROCEDURE: ReadNum-----

ReadNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV number, 0
    MOV CX, 0

READ_KEY:
    MOV AH, 1
    INT 21H
    CMP AL, 13
    JE STOP_READ

    SUB AL, '0'
    MOV digit, AL

    MOV AX, number
    MOV BX, 10
    MUL BX
    MOV BL, digit
    MOV BH, 0
    ADD AX, BX
    MOV number, AX
    JMP READ_KEY

STOP_READ:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadNum ENDP


; -----PROCEDURE: PrintNum-----

PrintNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX, 0
    JNE START_PR
    MOV DL, '0'
    MOV AH, 2
    INT 21H
    JMP END_PR

START_PR:
    MOV BX, 10
    MOV CX, 0

DIV_LOOP:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIV_LOOP

POP_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 2
    INT 21H
    LOOP POP_LOOP

END_PR:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNum ENDP


; -----PROCEDURE: ENTER_MARKS----- 


ENTER_MARKS PROC
    SHOW msgEnterID
    CALL ReadNum
    MOV BX, number

    MOV CX, count
    MOV SI, 0
FIND_LOOP:
    CMP CX, 0
    JE ID_NOT_FOUND
    MOV AX, studentIDs[SI]
    CMP AX, BX
    JE FOUND_FOR_MARKS
    ADD SI, 2
    DEC CX
    JMP FIND_LOOP

FOUND_FOR_MARKS:
MARK_MENU_LOOP:
    SHOW msgMarkMenu
    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE UPD_QUIZ_IN
    CMP AL, '2'
    JE UPD_LAB_IN
    CMP AL, '3'
    JE UPD_MID_IN
    CMP AL, '4'
    JE UPD_FINAL_IN
    CMP AL, '5'
    JE MARK_EXIT
    JMP MARK_MENU_LOOP

UPD_QUIZ_IN:
    SHOW msgInQuiz
    CALL ReadNum
    MOV AX, number
    CMP AX, 25
    JG ERR_QUIZ
    MOV marksQuiz[SI], AX
    SHOW msgSaved
    JMP RECALC_AND_LOOP
ERR_QUIZ:
    SHOW msgInvalidMark
    JMP UPD_QUIZ_IN

UPD_LAB_IN:
    SHOW msgInLab
    CALL ReadNum
    MOV AX, number
    CMP AX, 15
    JG ERR_LAB
    MOV marksLab[SI], AX
    SHOW msgSaved
    JMP RECALC_AND_LOOP
ERR_LAB:
    SHOW msgInvalidMark
    JMP UPD_LAB_IN

UPD_MID_IN:
    SHOW msgInMid
    CALL ReadNum
    MOV AX, number
    CMP AX, 50
    JG ERR_MID

    MOV DX, 0
    MOV BX, 2
    DIV BX
    MOV marksMid[SI], AX
    SHOW msgSaved
    JMP RECALC_AND_LOOP
ERR_MID:
    SHOW msgInvalidMark
    JMP UPD_MID_IN

UPD_FINAL_IN:
    SHOW msgInFin
    CALL ReadNum
    MOV AX, number
    CMP AX, 150
    JG ERR_FIN

    MOV BX, 7
    MUL BX
    MOV BX, 30
    DIV BX
    MOV marksFinal[SI], AX
    SHOW msgSaved
    JMP RECALC_AND_LOOP
ERR_FIN:
    SHOW msgInvalidMark
    JMP UPD_FINAL_IN

RECALC_AND_LOOP:
    CALL CALC_GRADE_FOR_INDEX
    JMP MARK_MENU_LOOP

MARK_EXIT:
    RET

ID_NOT_FOUND:
    SHOW msgNotFound
    RET
ENTER_MARKS ENDP


; -----PROCEDURE: CALC_GRADE_FOR_INDEX----- 

CALC_GRADE_FOR_INDEX PROC
    MOV AX, 0
    ADD AX, marksQuiz[SI]
    ADD AX, marksLab[SI]
    ADD AX, marksMid[SI]
    ADD AX, marksFinal[SI]

    MOV totalMarks[SI], AX
    MOV percentage[SI], AX

    CMP AX, 90
    JGE GRADE_A
    CMP AX, 80
    JGE GRADE_B
    CMP AX, 70
    JGE GRADE_C
    CMP AX, 60
    JGE GRADE_D
    JMP GRADE_F

GRADE_A:
    MOV gradeLetter[SI], 'A'
    RET

GRADE_B:
    MOV gradeLetter[SI], 'B'
    RET

GRADE_C:
    MOV gradeLetter[SI], 'C'
    RET

GRADE_D:
    MOV gradeLetter[SI], 'D'
    RET

GRADE_F:
    MOV gradeLetter[SI], 'F'
    RET

CALC_GRADE_FOR_INDEX ENDP


; -----PROCEDURE: SHOW_STUDENT_RESULT----- 

SHOW_STUDENT_RESULT PROC
    SHOW msgResult
    MOV AX, marksQuiz[SI]
    CALL PrintNum

    SHOW msgLabLbl
    MOV AX, marksLab[SI]
    CALL PrintNum

    SHOW msgMidLbl
    MOV AX, marksMid[SI]
    CALL PrintNum

    SHOW msgFinLbl
    MOV AX, marksFinal[SI]
    CALL PrintNum

    SHOW msgTotLbl
    MOV AX, totalMarks[SI]
    CALL PrintNum

    SHOW msgGrdLbl
    MOV AX, gradeLetter[SI]
    MOV DL, AL
    MOV AH, 2
    INT 21H
    RET
SHOW_STUDENT_RESULT ENDP


; -----PROCEDURE: SEARCH_STUDENT----- 

SEARCH_STUDENT PROC
    SHOW msgEnterID
    CALL ReadNum
    MOV BX, number

    MOV CX, count
    MOV SI, 0
SEARCH_S_LOOP:
    CMP CX, 0
    JE S_NOT_FOUND
    MOV AX, studentIDs[SI]
    CMP AX, BX
    JE FOUND_S
    ADD SI, 2
    DEC CX
    JMP SEARCH_S_LOOP

FOUND_S:
    SHOW msgProfile
    MOV AX, studentIDs[SI]
    CALL PrintNum
    CALL SHOW_STUDENT_RESULT
    RET

S_NOT_FOUND:
    SHOW msgNotFound
    RET
SEARCH_STUDENT ENDP


; -----PROCEDURE: SORT_STUDENTS-----


SORT_STUDENTS PROC
    PUSH BP

    MOV CX, count
    DEC CX
    CMP CX, 0
    JLE SORT_EXIT

OUTER_LOOP:
    MOV SI, 0
    MOV BP, CX

INNER_LOOP:
    MOV DI, SI
    ADD DI, 2

    MOV AX, totalMarks[SI]
    CMP AX, totalMarks[DI]
    JGE NO_SWAP

    ; Swap IDs
    MOV AX, studentIDs[SI]
    MOV BX, studentIDs[DI]
    MOV studentIDs[SI], BX
    MOV studentIDs[DI], AX

    ; Swap Passwords
    MOV AX, passwords[SI]
    MOV BX, passwords[DI]
    MOV passwords[SI], BX
    MOV passwords[DI], AX

    ; Swap Quiz
    MOV AX, marksQuiz[SI]
    MOV BX, marksQuiz[DI]
    MOV marksQuiz[SI], BX
    MOV marksQuiz[DI], AX

    ; Swap Lab
    MOV AX, marksLab[SI]
    MOV BX, marksLab[DI]
    MOV marksLab[SI], BX
    MOV marksLab[DI], AX

    ; Swap Mid
    MOV AX, marksMid[SI]
    MOV BX, marksMid[DI]
    MOV marksMid[SI], BX
    MOV marksMid[DI], AX

    ; Swap Final
    MOV AX, marksFinal[SI]
    MOV BX, marksFinal[DI]
    MOV marksFinal[SI], BX
    MOV marksFinal[DI], AX

    ; Swap Total
    MOV AX, totalMarks[SI]
    MOV BX, totalMarks[DI]
    MOV totalMarks[SI], BX
    MOV totalMarks[DI], AX

    ; Swap Percentage
    MOV AX, percentage[SI]
    MOV BX, percentage[DI]
    MOV percentage[SI], BX
    MOV percentage[DI], AX

    ; Swap Grade
    MOV AX, gradeLetter[SI]
    MOV BX, gradeLetter[DI]
    MOV gradeLetter[SI], BX
    MOV gradeLetter[DI], AX

    ; Swap Initials (DW): 3 WORDS per student
    PUSH SI
    PUSH DI

    ; SI(word offset) -> initials byte offset = (SI/2)*6
    MOV AX, SI
    MOV DX, 0
    MOV BX, 2
    DIV BX              ; AX = SI/2
    MOV BX, 6
    MUL BX              ; AX = (SI/2)*6
    MOV SI, AX

    ; DI(word offset) -> initials byte offset = (DI/2)*6
    MOV AX, DI
    MOV DX, 0
    MOV BX, 2
    DIV BX              ; AX = DI/2
    MOV BX, 6
    MUL BX              ; AX = (DI/2)*6
    MOV DI, AX

    ; swap 3 WORD initials: [0], [2], [4]
    MOV AX, initials[SI]
    MOV BX, initials[DI]
    MOV initials[SI], BX
    MOV initials[DI], AX

    MOV AX, initials[SI+2]
    MOV BX, initials[DI+2]
    MOV initials[SI+2], BX
    MOV initials[DI+2], AX

    MOV AX, initials[SI+4]
    MOV BX, initials[DI+4]
    MOV initials[SI+4], BX
    MOV initials[DI+4], AX

    POP DI
    POP SI

NO_SWAP:
    ADD SI, 2
    DEC BP
    JNE INNER_LOOP

    DEC CX
    JNE OUTER_LOOP

    SHOW msgSortDone

SORT_EXIT:
    POP BP
    RET
SORT_STUDENTS ENDP


; -----PROCEDURE: CLASS_STATS----- 

CLASS_STATS PROC
    MOV CX, count
    CMP CX, 0
    JE STATS_EMPTY

    MOV SI, 0
    MOV AX, totalMarks[SI]
    MOV BX, totalMarks[SI]
    MOV DX, 0
    MOV DI, SI

STATS_LOOP:
    MOV AX, totalMarks[SI]
    ADD DX, AX

    CMP AX, totalMarks[DI]
    JLE CHECK_MIN
    MOV DI, SI

CHECK_MIN:
    CMP AX, BX
    JGE NEXT_STAT
    MOV BX, AX

NEXT_STAT:
    ADD SI, 2
    LOOP STATS_LOOP

    PUSH DX
    SHOW msgStatHead

    SHOW msgHigh
    MOV AX, totalMarks[DI]
    CALL PrintNum

    SHOW msgLow
    MOV AX, BX
    CALL PrintNum

    SHOW msgAvg
    POP AX
    MOV DX, 0
    MOV BX, count
    DIV BX
    CALL PrintNum

    SHOW msgTopper
    MOV AX, studentIDs[DI]
    CALL PrintNum
    SHOW msgGrdLbl

    MOV AX, gradeLetter[DI]
    MOV DL, AL
    MOV AH, 2
    INT 21H
    RET

STATS_EMPTY:
    RET
CLASS_STATS ENDP


; -----PROCEDURE: VIEW_SPREADSHEET----- 

VIEW_SPREADSHEET PROC
    SHOW msgSheetHead

    MOV CX, count
    CMP CX, 0
    JE SHEET_EXIT
    MOV SI, 0

SHEET_LOOP:
    NEWLINE

    MOV AX, studentIDs[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, marksQuiz[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, marksLab[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, marksMid[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, marksFinal[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, totalMarks[SI]
    CALL PrintNum
    SHOW msgBar

    MOV AX, gradeLetter[SI]
    MOV DL, AL
    MOV AH, 2
    INT 21H

    ADD SI, 2
    LOOP SHEET_LOOP

SHEET_EXIT:
    RET
VIEW_SPREADSHEET ENDP


; -----PROCEDURE: EDIT_STUDENT_NAME-----


EDIT_STUDENT_NAME PROC
    SHOW msgEnterID
    CALL ReadNum
    MOV BX, number

    MOV CX, count
    MOV SI, 0
FIND_NAME_LOOP:
    CMP CX, 0
    JE NAME_NOT_FOUND
    MOV AX, studentIDs[SI]
    CMP AX, BX
    JE NAME_FOUND
    ADD SI, 2
    DEC CX
    JMP FIND_NAME_LOOP

NAME_FOUND:
    ; DI = (SI/2)*6
    MOV AX, SI
    MOV DX, 0
    MOV BX, 2
    DIV BX
    MOV BX, 6
    MUL BX
    MOV DI, AX

    SHOW msgAskInit

    ; Read 3 chars --- store as WORDs
    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI], AX

    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI+2], AX

    MOV AH, 1
    INT 21H
    MOV AH, 0
    MOV initials[DI+4], AX

    SHOW msgNameUpd
    RET

NAME_NOT_FOUND:
    SHOW msgNotFound
    RET
EDIT_STUDENT_NAME ENDP


END MAIN
