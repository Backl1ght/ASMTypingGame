;数据段存放各种数字
;扩展段存放各种字符串
;由于太长，放在代码段前面会导致未知运行错误
;故放于本文件的最后

;代码段
;----------------------------------------------------------
CODE1 SEGMENT
    ASSUME CS:CODE1,DS:DATA1,SS:STACKS,ES:EXS

;主程序
;**********************************************************
MAIN	PROC	FAR
        MOV 	AX,DATA1
        MOV 	DS,AX
        MOV		AX,EXS
        MOV 	ES,AX 				;BIOS 10H AH=13 显示字符串需要ES:BP
INITIAL:
        CALL 	INIT 				;初始界面
        CMP 	flag,0 				;新游戏
        JE 		NEWGAME
        CMP 	flag,2 				;退出
        JE 		END_MAIN
        CALL 	SETTING 			;设置界面，设置游戏难度
        JMP 	INITIAL
NEWGAME:
        CALL 	INIT_GAME			;初始化，设置参数
        CALL	GAME				;游戏开始
        JMP 	INITIAL
END_MAIN:
        MOV 	AH,4CH
        INT 	21H
MAIN	ENDP
;**********************************************************

;保存寄存器
;**********************************************************
PUSH_REG	MACRO
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH 	DI
        PUSHF
ENDM
;**********************************************************

;取出寄存器
;**********************************************************
POP_REG 	MACRO
        POPF
        POP 	DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
ENDM
;**********************************************************

;写字符
;**********************************************************
WRITE 	MACRO	PAGE,ROW,COL,COLOR,CHAR
        PUSH_REG
        MOV		BH,PAGE 			;页
        MOV		DH,ROW 				;行
        MOV		DL,COL 				;列
        MOV		AH,02H				;移动光标
        INT 	10H
        MOV		AL,CHAR 			;字符
        MOV		BL,COLOR 			;颜色
        MOV		CX,1 				;个数
        MOV		AH,09H				;写字符
        INT 	10H
        POP_REG
ENDM
;**********************************************************

;移动光标
;**********************************************************
MV_CUR 	MACRO	PAGE,ROW,COL
        PUSH_REG
        MOV		BH,PAGE 			;页
        MOV		DH,ROW 				;行
        MOV		DL,COL 				;列
        MOV		AH,02H				;移动光标
        INT 	10H
        POP_REG
ENDM
;**********************************************************

;取模运算
;**********************************************************
MODULUS	MACRO 	NUM1,NUM2
        PUSH_REG
        MOV 	AX,NUM1
        MOV 	BX,NUM2
        ADD 	AX,BX
        MOV 	DX,0
        DIV		BX
        MOV 	NUM1,DX 			;NUM1=(NUM1+NUM2)%NUM2
        POP_REG
ENDM
;**********************************************************

;蜂鸣器发声
;**********************************************************
RING	MACRO	WAIT
        PUSH_REG
GET_FREQUENCE:
        LEA 	DI,music_key
        MOV 	AX,56
        MUL 	music
        ADD 	DI,AX
        ADD 	DI,music_ptr
        MOV 	AL,[DI]
        DEC 	AL
        SAL 	AL,1
        XOR 	AH,AH
        LEA		SI,music_freq
        ADD 	SI,AX
        MOV 	DI,[SI]
        INC 	music_ptr
        MODULUS music_ptr,56
SOUND:
        MOV 	AL,0B6H 			;设置计时器模式
        OUT		43H,AL
        MOV 	DX,12H
        MOV 	AX,348CH			;获取声音的频率
        DIV 	DI
        OUT 	42H,AL
        MOV 	AL,AH
        OUT 	42H,AL
        IN 		AL,61H
        MOV 	AH,AL
        OR 		AL,3
        OUT 	61H,AL
        MOV 	BX,WAIT
WAIT1:
        MOV 	CX,2800
DELAY:
        LOOP 	DELAY
        DEC 	BX
        JNZ 	WAIT1
        MOV 	AL,AH
        OUT 	61H,AL
RING_END:
        POP_REG
ENDM
;**********************************************************

;写字符串
;Print String
;**********************************************************
P_STR	MACRO 	PAGE,ROW,COL,STR,LEN,COLOR
        MOV 	BP,STR 				;串地址
        MOV 	AH,13H				;显示字符串
        MOV		BH,PAGE				;显示页数
        MOV 	DH,ROW 				;初始行
        MOV 	DL,COL				;初始列
        MOV 	CX,LEN	 			;串长
        MOV 	AL,1				;光标跟随移动
        MOV 	BL,COLOR 			;字符属性
        INT 	10H 				;CALL BIOS
ENDM
;**********************************************************

;查找屏幕中是否有CHAR
;若有将其高亮显示，并让蜂鸣器发声
;**********************************************************
FIND	MACRO	CHAR
        LOCAL 	LOOP1,LOOP2,NEXT1,NEXT2,FIND_END
        PUSH_REG

        add 	CHAR,'A'
        sub 	CHAR,'a'			;键盘输入为小写，界面显示为大写
        mov 	aim,CHAR 			;故需进行转换才能正确查找

        ;遍历屏幕查找aim
        MOV		CH,24
LOOP1:
        MOV		CL,79
LOOP2:
        MOV 	BH,2				;2页
        MOV		DH,CH 				;行
        MOV		DL,CL 				;列
        MOV		AH,02H				;移动光标
        INT 	10H
        MOV		BH,2				;2页
        MOV 	AH,08H				;读字符及属性
        INT 	10H
        CMP		AH,spec_color		;高亮?
        JE 		NEXT2
        CMP 	AL,aim
        JNE		NEXT2

        WRITE 	2,CH,CL,spec_color,aim 	;有aim
        INC		hit 				;击中的字符数+1

        RING	100					;发声1S
        JMP 	FIND_END
NEXT2:
        DEC 	CL
        CMP 	CL,0
        JGE 	LOOP2
NEXT1:
        DEC 	CH
        CMP		CH,0
        JGE 	LOOP1
FIND_END:
        POP_REG
ENDM
;**********************************************************

;初始界面
;**********************************************************
INIT	PROC	NEAR
        PUSH_REG
SET:
        MOV 	AH,05H				;设置显示页
        MOV 	AL,0				;页数为0
        INT 	10H 				;CALL BIOS

        MOV 	flag,0
        LEA 	AX,init_msg 		;串地址
        P_STR 	0,7,0,AX,603,base_color

        ;显示功能选项，默认选中第一项(开始新游戏)
        LEA 	AX,msg1
        P_STR 	0,18,0,AX,65,spec_color

        LEA 	AX,msg2
        P_STR 	0,19,0,AX,65,base_color

        LEA 	AX,msg3
        P_STR 	0,20,0,AX,65,base_color

CHOOSE:
        MOV 	AH,00H
        INT 	16H
        CMP 	AL,0DH
        JE 		SET_END
        CMP 	AL,'w'
        JE 		UP
        CMP 	AL,'s'
        JE 		DOWN
        JMP 	CHOOSE
UP:
        DEC 	flag
        JMP 	NEXT
DOWN:
        INC 	flag
NEXT:;循环读取下一个字符，重新显示所选功能
        LEA 	AX,msg1
        P_STR 	0,18,0,AX,65,base_color
        LEA 	AX,msg2
        P_STR 	0,19,0,AX,65,base_color
        LEA 	AX,msg3
        P_STR 	0,20,0,AX,65,base_color

        MODULUS flag,3 				;flag=(flag+3)%3,将flag控制在0-2

         ;將所选的功能已不同的颜色显示
        CMP 	flag,0
        JE 		P_NEWGAME
        CMP 	flag,1
        JE 		P_SET
        ;P_EXIT
        LEA 	AX,msg3
        P_STR 	0,20,0,AX,65,spec_color
        JMP 	CHOOSE
P_NEWGAME:
        LEA 	AX,msg1
        P_STR 	0,18,0,AX,65,spec_color
        JMP 	CHOOSE
P_SET:
        LEA 	AX,msg2
        P_STR 	0,19,0,AX,65,spec_color
        JMP 	CHOOSE
SET_END:
        POP_REG
        RET
INIT 	ENDP
;**********************************************************

;设置界面
;**********************************************************
SETTING PROC  	NEAR
        PUSH_REG
SETINIT:
        MOV 	AH,05H				;设置显示页
        MOV 	AL,1				;页数为1
        INT 	10H 				;CALL BIOS

        LEA 	AX,set_msg 			;串地址
        P_STR 	1,7,0,AX,603,base_color

        MOV 	BX,10

        MOV 	DX,0 				;将速度转换为难度级别(除以10后-1)
        MOV 	AX,roll_gap
        DIV 	BX
        DEC 	AX
        MOV 	roll_gap,AX

        MOV 	DX,0 				;将速度转换为难度级别(除以10后-1)
        MOV 	AX,char_gap
        DIV 	BX
        DEC 	AX
        MOV 	char_gap,AX

        MOV 	BX,char_gap
        ADD 	BL,'0' 				;int 2 char
        WRITE   1,9,44,spec_color,BL

        MOV 	BX,roll_gap
        ADD 	BL,'0' 				;int 2 char
        WRITE   1,10,44,base_color,BL

        LEA 	BX,music_name
        MOV 	AX,music
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,11,38,BX,25,base_color

        LEA 	BX,color_name
        MOV 	AX,color
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,12,38,BX,25,base_color

        MOV 	flag,0
CHOOSE:
        MOV 	AH,00H 				;从键盘读取字符
        INT 	16H
        CMP 	AL,0DH 				;enter?
        JE 		SET_END

        CMP 	AL,'w'
        JE 		UP
        CMP 	AL,'s'
        JE 		DOWN
        CMP 	AL,'a'
        JE 		DECREASE
        CMP 	AL,'d'
        JE 		INCREASE
UP:
        DEC 	flag
        MODULUS flag,4				;flag=(flag+3)%3,将flag控制在0-2
        JMP 	NEXT
DOWN:
        INC 	flag
        MODULUS flag,4				;flag=(flag+3)%3,将flag控制在0-2
        JMP		NEXT
INCREASE:
         CMP 	flag,0
         JE 		INC_CHAR
         CMP 	flag,1
         JE 		INC_ROLL
         CMP 	flag,3
         JE 		INC_COLOR
         INC		music
         MODULUS music,5 			;music：0-4
         JMP		NEXT
INC_CHAR:
        INC 	char_gap
        MODULUS char_gap,9 			;hard:0-8
        JMP		NEXT
INC_ROLL:
        INC 	roll_gap
        MODULUS roll_gap,9 			;hard:0-8
        JMP 	NEXT
INC_COLOR:
        INC 	color
        MODULUS color,5
        JMP 	NEXT
DECREASE:
         CMP 	flag,0
         JE 		DEC_CHAR
         CMP 	flag,1
         JE 		DEC_ROLL
         CMP 	flag,3
         JE 		DEC_COLOR
         DEC 	music
         MODULUS music,5 			;music：0-4
         JMP		NEXT
DEC_CHAR:
        DEC 	char_gap
        MODULUS char_gap,9 			;hard:0-8
        JMP		NEXT
DEC_ROLL:
        DEC 	roll_gap
        MODULUS roll_gap,9 			;hard:0-8
        JMP 	NEXT
DEC_COLOR:
        DEC 	color
        MODULUS color,5
        JMP 	NEXT
NEXT:
        LEA 	DI,color_num
        MOV 	AX,color
        SAL 	AX,1
        ADD 	DI,AX
        MOV 	BX,[DI]
        MOV 	spec_color,BH
        MOV 	base_color,BL


        ;重新显示
        LEA 	AX,set_msg 			;串地址
        P_STR 	1,7,0,AX,603,base_color

        MOV 	BX,char_gap
        ADD 	BL,'0' 			;int 2 char
        WRITE   1,9,44,base_color,BL

        MOV 	BX,roll_gap
        ADD 	BL,'0' 			;int 2 char
        WRITE   1,10,44,base_color,BL

        LEA 	BX,music_name
        MOV 	AX,music
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,11,38,BX,25,base_color

        LEA 	BX,color_name
        MOV 	AX,color
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,12,38,BX,25,base_color

        ;将所选功能以闪烁的方式显示
        CMP 	flag,0
        JE 		P_CHAR
        CMP 	flag,1
        JE 		P_ROLL
        CMP 	flag,3
        JE 		P_COLOR
        ;P_MSC:
        LEA 	BX,music_name
        MOV 	AX,music
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,11,38,BX,25,spec_color
        JMP		CHOOSE
P_CHAR:
        MOV 	BX,char_gap
        ADD 	BL,'0' 			;int 2 char
        WRITE   1,9,44,spec_color,BL
        JMP 	CHOOSE
P_ROLL:
        MOV 	BX,roll_gap
        ADD 	BL,'0' 			;int 2 char
        WRITE   1,10,44,spec_color,BL
        JMP 	CHOOSE
P_COLOR:
        LEA 	BX,color_name
        MOV 	AX,color
        MOV 	CX,25
        MUL 	CX
        ADD 	BX,AX
        P_STR 	1,12,38,BX,25,spec_color
        JMP		CHOOSE
SET_END:
        ;保存设置
        MOV 	BX,10 			;难度转换回时间间隔
        MOV 	AX,roll_gap
        INC 	AX
        MUL 	BX
        MOV 	roll_gap,AX

        MOV 	AX,char_gap
        INC 	AX
        MUL 	BX
        MOV 	char_gap,AX

        POP_REG
        RET
SETTING ENDP
;**********************************************************

;游戏初始化
;初始化roll_last和char_last等
;**********************************************************
INIT_GAME	PROC	NEAR
        PUSH_REG
SET:
        MOV 	AH,05H				;设置显示页
        MOV 	AL,2				;页数为2
        INT 	10H 				;CALL BIOS

        MOV 	music_ptr,0

        MOV		AH,07H				;向上滚动窗口
        MOV		AL,0				;滚动的行,0-清屏
        MOV		BH,base_color
        MOV		CH,0				;高行数
        MOV		CL,0				;左列数
        MOV		DH,24				;低行数
        MOV		DL,79				;右列数
        INT 	10H					;CALL BIOS

        MOV		AH,2CH
        INT 	21H
        AND		DH,DH 				;获取当前时间(0.01S)
        MOV		roll_last,DX		;设置roll_last
        MOV		char_last,DX		;设置char_last
        MOV 	sum,0				;初始化总字符数
        MOV 	hit,0				;初始化正确输入字符数

        MOV 	AH,0CH
        MOV 	AL,00H				;
        INT		21H					;清空键盘缓存

INIT_END:
        POP_REG
        RET
INIT_GAME	ENDP
;**********************************************************

;游戏主体
;**********************************************************
GAME	PROC	FAR
        PUSH_REG
        MOV		CX,10
GAMING:
        CALL	ROLL_DOWN			;向下滚屏?
        CALL	NEW_CHAR			;是否生成新字符？

        CALL	LISTEN				;检测键盘输入

        JMP		GAMING
GAME_END:
        POP_REG
        RET
GAME	ENDP
;**********************************************************

;向下滚屏
;**********************************************************
ROLL_DOWN	PROC	NEAR
            PUSH_REG
GET_GAP:
            MOV		AH,2CH
            INT 	21H
            AND		DH,DH
            SUB		DX,roll_last
            CMP		DX,0
            JGE 	JUDGE
            ADD		DX,100			;计算当前时间与上一次滚屏的时间间隔
JUDGE:								;判断是否需要滚屏
            CMP		DX,roll_gap
            JB		ROLL_END
DO_ROLL:
            MOV		AH,07H			;向上滚动窗口
            MOV		AL,1			;滚动的行
            MOV		BH,base_color
            MOV		CH,0			;高行数
            MOV		CL,0			;左列数
            MOV		DH,24			;低行数
            MOV		DL,79			;右列数
            INT 	10H				;CALL BIOS

            MOV		AH,2CH
            INT 	21H
            AND		DH,DH
            MOV		roll_last,DX 	;重置上一次滚屏的时间
ROLL_END:
            POP_REG
            RET
ROLL_DOWN	ENDP
;**********************************************************

;是否生成新字符？
;**********************************************************
NEW_CHAR	PROC	NEAR
            PUSH_REG

GET_GAP:
            MOV		AH,2CH
            INT 	21H
            AND		DH,DH 			;get current time
            SUB		DX,char_last
            CMP		DX,0
            JGE 	JUDGE
            ADD		DX,100			;计算当前时间与上一次生成字符的时间间隔
JUDGE:								;判断是否需要生成新的字符
            CMP		DX,char_gap
            JB		CHAR_END
DO_NEWCHAR:
            MOV		LEFT,1
            MOV 	RIGHT,81
            CALL	RAND 			;随机位置(0-79)
            MOV		AX,RANDOM
            DEC		AX
            MOV		LEFT,1
            MOV		RIGHT,26		;随机字符('A'-'Z')
            CALL	RAND
            MOV		CX,RANDOM
            DEC		CX
            ADD		CX,'A' 			;int 2 char

            WRITE	2,0,AL,base_color,CL 	;生成字符

            INC 	sum 			;字符总数+1

            MOV		AH,2CH
            INT 	21H
            AND		DH,DH 			;get current time
            MOV		char_last,DX 	;重置上一次生成字符的时间
CHAR_END:
            POP_REG
            RET
NEW_CHAR	ENDP
;**********************************************************

;检测键盘输入
;**********************************************************
LISTEN	PROC	NEAR
        PUSH_REG
GET_STATUS:
        MOV		AH,01H				;从键盘缓冲队列取队首
        INT 	16H
        JZ  	LISTEN_END			;键盘缓冲队列为空
        MOV 	AH,07H				;BIOS 16H 01H 功能不会移动队首指针
        INT 	21H					;搭配DOS 21H 07H 功能读取字符

        CMP 	AL,1BH				;Esc?
        JE 		DO_PAUSE 			;按下ESC键暂停游戏，显示分数
        CMP 	AL,'a'				;a-z?
        JB		NEXT_STATUS
        CMP 	AL,'z'
        JG 		NEXT_STATUS
        FIND	AL
        JMP 	GET_STATUS 			;other
DO_PAUSE:
        CALL 	PAUSING
NEXT_STATUS:
        JMP 	GET_STATUS
LISTEN_END:
        POP_REG
        RET
LISTEN	ENDP
;**********************************************************

;暂停
;**********************************************************
PAUSING	PROC	NEAR
        PUSH_REG

        MOV 	AH,05H				;设置显示页
        MOV 	AL,3				;页数为3
        INT 	10H 				;CALL BIOS

        LEA 	AX,pause_msg 		;串地址
        P_STR 	3,7,0,AX,603,base_color

        MOV		BX,sum 				;显示总的字符数
        MV_CUR 	3,9,30 				;移动光标
        CALL 	PRINT

        MOV		BX,hit 				;显示输入正确的字符数
        MV_CUR 	3,9,46
        CALL 	PRINT

        MV_CUR 	3,10,39				;显示命中率
        MOV 	AX,hit 				;TODO：保留小数点后两位
        MOV		BX,100
        MUL		BX
        MOV 	BX,sum
        CMP 	BX,0
        JE 		P3					;防止除零，sum=0 -> rate=0
        DIV 	BX
        MOV 	BX,AX
P3:
        CALL 	PRINT

        MV_CUR 	3,16,0

        MOV 	AH,00H
        INT 	16H
        CMP 	AL,1BH 				;Esc?
        JNE  	CONTINUE 			;游戏继续
EXIT:
        CALL 	MAIN 				;返回主界面

CONTINUE:
        MOV 	AH,05H				;设置显示页
        MOV 	AL,2				;页数为2
        INT 	10H 				;CALL BIOS

        POP_REG
        RET
PAUSING ENDP
;**********************************************************

;产生随机数，范围为[left,right],存于random
;访问I/O 41H端口，获取其记录的数值
;再线性同余处理后得出随机数
;设置好上下界后调用即可
;**********************************************************
RAND	PROC	NEAR
        PUSH_REG

GET_RAND:
        MOV 	AX, 233   			;产生从1到AX之间的随机数
        MOV 	DX, 41H 			;用端口41H（RAM refresh counter）
        OUT 	DX, AX  			;向DX（41H）端口发送消息
        IN 		AL, DX   			;从DX（41H)读取消息，即为产生的随机数AX
        MUL		SEED 				;使随机数更随机

SET_RAND:
        MOV		BX,LEFT
        MOV		CX,RIGHT
        SUB 	CX,BX 				;区间长度为RIGHT-LEFT+1
        INC		CX
        DIV		CX					;获取[0,CX-1]的随机数
        ADD		DX,BX 				;[BX,BX+CX-1],即[left,right]
        MOV		RANDOM,DX

        MOV		SEED,DX				;重设随机数种子

RAND_END:
        POP_REG
        RET
rand	ENDP
;**********************************************************

;将BX所存数输出
;将要输出的数赋给BX后直接调用即可
;**********************************************************
PRINT	PROC	NEAR
        PUSH_REG

        MOV		AX,BX
        MOV		BX,10
        MOV		CX,0
        CMP		AX,0				;特判输出为0
        JNE 	LOOP1
        PUSH 	AX
        INC 	CX
        JMP 	LOOP2
LOOP1:
        CMP		AX,0				;从各位开始，依次将每一位入栈
        JE		LOOP2
        MOV		DX,0
        DIV		BX
        PUSH 	DX
        INC		CX
        JMP		LOOP1
LOOP2:
        POP 	DX 					;依次出栈并打印
        ADD		DL,30H				;int 2 char
        MOV 	AH,0EH 				;显示字符，光标随之移动
        MOV 	AL,DL 				;字符
        MOV 	BL,base_color 		;属性,04h -> 黑底红字
        INT 	10H 				;CALL BIOS
        LOOP 	LOOP2
PRINT_END:
        MOV		DL,0AH
        INT		21H
        MOV		DL,0DH
        INT		21H

        POP_REG
        RET
PRINT	ENDP
;**********************************************************
CODE1 ENDS
;----------------------------------------------------------

;堆栈段
;----------------------------------------------------------
STACKS SEGMENT
    stk		db		1000	dup(?)
STACKS ENDS
;----------------------------------------------------------

;数据段1
;----------------------------------------------------------
DATA1 SEGMENT
    seed		dw		?			;随机数种子
    random		dw		?			;随机数
    left		dw		?			;随机数下界
    right		dw		?			;随机数上界

    char_gap	dw		90			;字母生成的时间间隔，单位：0.01s
    roll_gap	dw 		90			;向下滚屏的时间间隔，单位：0.01s
    char_last	dw 		?			;上一次生成字符的时间
    roll_last	dw 		?			;上一次滚屏的时间
    sum			dw 		0			;总的字符数
    hit			dw 		0			;击中的字符数

    aim 		db 		?			;查找的目标字符

    flag 		dw 		? 			;初始化界面中：标识进入游戏(0)、进入设置界面(1)或退出游戏(2)
                                    ;设置界面中：标识修改字符生成速度(0)、字符下落速度(1)或游戏音乐(2)

    music 		dw 		0 			;游戏音乐Index

    music_freq 	dw 		262
                dw		294
                dw		330
                dw		349
                dw		392
                dw		440
                dw		494 		;各个音阶的频率,1,2,...,7

    music_key 	db 		1,1,5,5,6,6,5,4,4,3,3,2,2,1,1,1,5,5,6,6,5,4,4,3,3
                db		2,2,1,1,1,5,5,6,6,5,4,4,3,3,2,2,1,1,1,5,5,6,6,5,1,1,1,1,1,1,1 			;小星星
                db 		3,1,6,5,6,6,1,6,6,6,3,1,2,5,3,2,5,6,1,6,2,3,1,6,5
                db 		3,1,6,5,6,3,1,6,6,5,6,1,6,2,3,1,6,5,3,1,6,5,6,3,1,6,6,1,1,1,1 			;鸿雁
                db 		1,3,3,2,1,3,2,1,3,3,2,1,1,1,1,6,1,2,3,3,3,0,5,6,1
                db 		1,1,6,1,2,3,2,3,5,5,6,1,1,6,1,2,3,2,3,2,2,1,2,1,1,1,1,1,1,1,1 			;小情歌
                db		5,3,2,2,1,1,1,1,1,1,1,6,5,5,6,6,6,6,1,2,3,5,5,5,5
                db		1,1,2,2,2,1,1,7,1,1,1,1,6,5,5,6,6,6,6,1,1,2,3,5,5,5,5,3,2,2,2 			;夜空中最亮的星
                db 		1,3,3,2,1,3,2,1,3,3,2,1,1,1,1,6,1,2,3,3,3,0,5,6,1
                db		3,3,2,3,2,1,1,1,2,2,1,1,5,5,6,5,6,5,7,6,6,5,6,1,3,2,1,1,1,1,1	 		;爱拼才会赢


    music_ptr 	dw 		?

      color 		dw 		0 			;颜色Index
      base_color 	db 		07H 		;基础颜色
      spec_color 	db 		04H 		;高亮颜色
      ;高位为高亮颜色，低位为基础颜色
      color_num 	dw 		0407H 		;红 白
                  dw 		0402H		;红 绿
                  dw 		0207H		;绿 白
                  dw 		8407H		;闪烁红 白
                  dw 		0704H		;白 红
DATA1 ENDS
;----------------------------------------------------------

;扩展段
;----------------------------------------------------------
EXS	SEGMENT
    ;暂停界面
    pause_msg	db 		'                *************************************************',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         sum:          score:                  *',0ah,0dh
                db 		'                *         your rate is    %                     *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         press esc to exit                     *',0ah,0dh
                db 		'                *         or other key to continue              *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *************************************************',0ah,0dh
    ;初始界面
    init_msg	db 		'                *************************************************',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         A little word game                    *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         Produced by _Backl1ght                *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         press w,s and enter to choose         *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *************************************************',0ah,0dh

    msg1		db		'                          New Game                               ',0ah,0dh
    msg2		db		'                          Settings                               ',0ah,0dh
    msg3		db 		'                          Exit                                   ',0ah,0dh

    set_msg		db 		'                *************************************************',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *         new char speed :                      *',0ah,0dh
                db 		'                *         roll down speed:                      *',0ah,0dh
                db 		'                *         game music :                          *',0ah,0dh
                db 		'                *         game color :                          *',0ah,0dh
                db 		'                *         press wsad and enter to choose        *',0ah,0dh
                db 		'                *                                               *',0ah,0dh
                db 		'                *************************************************',0ah,0dh

    music_name 	db 		'little star              '
                db 		'hong yan                 '
                db 		'xiao qing ge             '
                db 		'lightest star            '
                db 		'ai pin cai hui ying      '

    color_name 	db 		'white(red)               '
                db 		'green(red)               '
                db 		'white(green)             '
                db 		'white(s_red)             '
                db 		'red(white)               '
EXS	ENDS
;----------------------------------------------------------
    END