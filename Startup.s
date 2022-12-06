;/****************************************Copyright (c)**************************************************
;**                               广州周立功单片机发展有限公司
;**                                     研    究    所
;**                                        产品一部 
;**
;**                                 http://www.zlgmcu.com
;**
;**--------------文件信息--------------------------------------------------------------------------------
;**文   件   名: Startup.s
;**创   建   人: 陈明计
;**最后修改日期: 2004年3月3日
;**描        述: lpc21xx的启动代码，包含异常向量入口、初始化堆栈的代码等
;**              每个工程应当有独立的这个文件的拷贝，并进行相应的修改   
;**--------------历史版本信息----------------------------------------------------------------------------
;** 创建人: 陈明计
;** 版  本: v1.0
;** 日　期: 2004年2月2日
;** 描　述: 原始版本
;**
;**------------------------------------------------------------------------------------------------------
;** 修改人: 
;** 版  本: 
;** 日　期: 
;** 描　述: 
;**
;**--------------当前版本修订------------------------------------------------------------------------------
;** 修改人:
;** 日　期:
;** 描　述:
;**
;**------------------------------------------------------------------------------------------------------
;********************************************************************************************************/

;定义堆栈的大小
FIQ_STACK_LEGTH         EQU         0
IRQ_STACK_LEGTH         EQU         9*8             ;每层嵌套需要9个字堆栈，允许8层嵌套
ABT_STACK_LEGTH         EQU         0
UND_STACK_LEGTH         EQU         0

NoInt       EQU 0x80

USR32Mode   EQU 0x10
SVC32Mode   EQU 0x13
SYS32Mode   EQU 0x1f
IRQ32Mode   EQU 0x12
FIQ32Mode   EQU 0x11

PINSEL2     EQU 0xE002C014


;引入的外部标号在这声明
    IMPORT  FIQ_Exception                   ;快速中断异常处理程序
    IMPORT  __main                          ;C语言主程序入口 
    IMPORT  TargetResetInit                 ;目标板基本初始化

    IMPORT  SoftwareInterrupt

;给外部使用的标号在这声明
    EXPORT  Reset
    EXPORT  __rt_div0
    EXPORT  __user_initial_stackheap
	EXPORT bottom_of_heap
	EXPORT	StackUsr
    
	CODE32

    PRESERVE8	 ;这个东东一定要加，，，，不加好像不行。。。。	 在KEIL v2.5时没有发现这个东东

    AREA    vectors,CODE,READONLY

    ARM
;中断向量表
Reset
        LDR     PC, ResetAddr
        LDR     PC, UndefinedAddr
        LDR     PC, SWI_Addr
        LDR     PC, PrefetchAddr
        LDR     PC, DataAbortAddr
        DCD     0xb9205f80
        LDR     PC, [PC, #-0xff0]
        LDR     PC, FIQ_Addr

ResetAddr           DCD     ResetInit
UndefinedAddr       DCD     Undefined
SWI_Addr            DCD     SoftwareInterrupt
PrefetchAddr        DCD     PrefetchAbort
DataAbortAddr       DCD     DataAbort
Nouse               DCD     0
IRQ_Addr            DCD     0
FIQ_Addr            DCD     FIQ_Handler

;未定义指令
Undefined
        B       Undefined

;取指令中止
PrefetchAbort
        B       PrefetchAbort

;取数据中止
DataAbort
        B       DataAbort

;快速中断
FIQ_Handler
        STMFD   SP!, {R0-R3, LR}
        BL      FIQ_Exception
        LDMFD   SP!, {R0-R3, LR}
        SUBS    PC,  LR,  #4


;//传说中的加密
;标号一定要对齐，否则出错了，想到X也找不出来
; 程序加密
	IF :DEF: EN_CRP
        IF  . >= 0x1fc
        INFO    1,"\nThe data at 0x000001fc must be 0x87654321.\nPlease delete some source before this line."
        ENDIF
CrpData
    WHILE . < 0x1fc
    NOP
    WEND
CrpData1
    DCD     0x87654321          ;/*When the Data is 为0x87654321,user code be protected. 当此数为0x87654321时，用户程序被保护 */
    ENDIF

;/*********************************************************************************************************
;** 函数名称: InitStack
;** 功能描述: 初始化堆栈
;** 输　入:   无
;** 输　出 :  无
;** 全局变量: 无
;** 调用模块: 无
;** 
;** 作　者: 陈明计
;** 日　期: 2004年2月2日
;**-------------------------------------------------------------------------------------------------------
;** 修　改: 
;** 日　期: 
;**-------------------------------------------------------------------------------------------------------
;********************************************************************************************************/



InitStack    
        MOV     R0, LR

;设置中断模式堆栈
        MSR     CPSR_c, #0xd2
        LDR     SP, StackIrq
;设置快速中断模式堆栈
        MSR     CPSR_c, #0xd1
        LDR     SP, StackFiq
;设置中止模式堆栈
        MSR     CPSR_c, #0xd7
        LDR     SP, StackAbt
;设置未定义模式堆栈
        MSR     CPSR_c, #0xdb
        LDR     SP, StackUnd
;设置系统模式堆栈
        MSR     CPSR_c, #0xdf
        LDR     SP, =StackUsr

        MOV     LR, R0
		BX      LR
;        MOV     PC, LR
		
;/*********************************************************************************************************
;** 函数名称: ResetInit
;** 功能描述: 复位入口
;** 
;** 输　入: 无
;**
;** 输　出: 无
;**         
;** 全局变量: 无
;** 调用模块: 无
;**
;** 作　者: 陈明计
;** 日　期: 2004年2月2日
;**-------------------------------------------------------------------------------------------------------
;** 修改人: 陈明计
;** 日　期: 2004年3月3日
;**------------------------------------------------------------------------------------------------------
;********************************************************************************************************/
ResetInit       
        BL      InitStack               ;初始化堆栈
        BL      TargetResetInit         ;目标板基本初始化
                                        
        B       __main          ;跳转到c语言入口


;/*********************************************************************************************************
;** 函数名称: __user_initial_stackheap 
;** 功能描述: 库函数初始化堆和栈，不能删除
;** 
;** 输　入: 参考库函数手册
;**
;** 输　出: 参考库函数手册
;**         
;** 全局变量: 无
;** 调用模块: 无
;**
;** 作　者: 陈明计
;** 日　期: 2004年2月2日
;**-------------------------------------------------------------------------------------------------------
;** 修改人:
;** 日　期:
;**------------------------------------------------------------------------------------------------------
;********************************************************************************************************/
__user_initial_stackheap    
    LDR   R0,=bottom_of_heap
	BX    LR


;/*********************************************************************************************************
;** 函数名称: __rt_div0
;** 功能描述: 整数除法除数为0错误处理函数，替代原始的__rt_div0减少目标代码大小			 
;** 
;** 输　入: 参考库函数手册	  
;**
;** 输　出: 无
;**         
;** 全局变量: 无
;** 调用模块: 无
;**
;** 作　者: 陈明计	  
;** 日　期: 2004年2月2日    
;**-------------------------------------------------------------------------------------------------------
;** 修改人:
;** 日　期:
;**------------------------------------------------------------------------------------------------------
;********************************************************************************************************/
__rt_div0

        B       __rt_div0

StackIrq           DCD     IrqStackSpace + (IRQ_STACK_LEGTH - 1)* 4
StackFiq           DCD     FiqStackSpace + (FIQ_STACK_LEGTH - 1)* 4
StackAbt           DCD     AbtStackSpace + (ABT_STACK_LEGTH - 1)* 4
StackUnd           DCD     UndtStackSpace + (UND_STACK_LEGTH - 1)* 4

;/* 分配堆栈空间 */
        AREA    MyStacks, DATA, NOINIT, ALIGN=2
IrqStackSpace           SPACE   IRQ_STACK_LEGTH * 4  ;中断模式堆栈空间
FiqStackSpace           SPACE   FIQ_STACK_LEGTH * 4  ;快速中断模式堆栈空间
AbtStackSpace           SPACE   ABT_STACK_LEGTH * 4  ;中止义模式堆栈空间
UndtStackSpace          SPACE   UND_STACK_LEGTH * 4  ;未定义模式堆栈


;
;从以前的heap.s 和 stacks中移过来，，少了两个文件

        AREA    Heap, DATA, NOINIT
bottom_of_heap    SPACE   1

        AREA    Stacks, DATA, NOINIT
StackUsr		  SPACE   1

    END
;/*********************************************************************************************************
;**                            End Of File
;********************************************************************************************************/
