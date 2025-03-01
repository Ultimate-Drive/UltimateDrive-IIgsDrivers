*---------------------------------------------*
* Genesys created Merlin data structures
* Simple Software Systems International, Inc.
* Merlin.SCG 1.0b4
*
*
* In order to see the comments correctly please enter
* 'FIXS' in the command box of the Merlin Editor
*

*
* Control List Definitions
*

CTLLST_00001003 equ *
 adrl CTLTMP_00000001 ;control 1
 adrl CTLTMP_00000002 ;control 2
 adrl CTLTMP_00000003 ;control 3
 adrl CTLTMP_00000004 ;control 4 - ip address control
 adrl CTLTMP_00000005 ;control 5
 adrl CTLTMP_00000006 ;control 6 - netmask control
 adrl CTLTMP_00000007 ;control 7
 adrl CTLTMP_00000008 ;control 8 - gateway control
 adrl CTLTMP_00000009 ;control 9
 adrl CTLTMP_0000000A ;control 10
 adrl CTLTMP_0000000B ;control 11 - dhcp check
 adrl CTLTMP_0000000C ;control 12
 adrl CTLTMP_0000000D ;control 13
 adrl CTLTMP_0000000E ;control 14
 adrl 0 ;end of control list
*
* Control Templates
*

CTLTMP_00000001 equ *
 dw 9 ;pCount
 adrl $1 ;ID (1)
 dw 7,18,16,135 ;rect
 adrl $81000000 ;static text
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl LETXTBOX_00000001 ;text reference
 dw LETXTBOX_00000001_LEN ;text size
 dw 0 ;justification

CTLTMP_00000002 equ *
 dw 8 ;pCount
 adrl $2 ;ID (2)
 dw 17,16,20,386 ;rect
 adrl $87FF0003 ;
 dw $0001 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon

CTLTMP_00000003 equ *
 dw 9 ;pCount
 adrl $3 ;ID (3)
 dw 39,18,50,101 ;rect
 adrl $81000000 ;static text
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl LETXTBOX_00000002 ;text reference
 dw LETXTBOX_00000002_LEN ;text size
 dw 0 ;justification

CTLTMP_00000004 equ *
 dw 8 ;pCount
 adrl $4 ;ID (4)
 dw 36,104,49,224 ;rect
 adrl $83000000 ;line edit
 dw $0000 ;flag
 dw $7000 ;moreFlags
 adrl 0 ;refCon
 dw 20 ;max size
 adrl PSTR_00000001 ;default

CTLTMP_00000005 equ *
 dw 9 ;pCount
 adrl $5 ;ID (5)
 dw 53,18,63,99 ;rect
 adrl $81000000 ;static text
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl LETXTBOX_00000003 ;text reference
 dw LETXTBOX_00000003_LEN ;text size
 dw 0 ;justification

CTLTMP_00000006 equ *
 dw 8 ;pCount
 adrl $6 ;ID (6)
 dw 52,104,64,224 ;rect
 adrl $83000000 ;line edit
 dw $0001 ;flag
 dw $7000 ;moreFlags
 adrl 0 ;refCon
 dw 20 ;max size
 adrl PSTR_00000002 ;default

CTLTMP_00000007 equ *
 dw 9 ;pCount
 adrl $7 ;ID (7)
 dw 67,18,76,101 ;rect
 adrl $81000000 ;static text
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl LETXTBOX_00000004 ;text reference
 dw LETXTBOX_00000004_LEN ;text size
 dw 0 ;justification

CTLTMP_00000008 equ *
 dw 8 ;pCount
 adrl $8 ;ID (8)
 dw 67,104,80,224 ;rect
 adrl $83000000 ;line edit
 dw $0000 ;flag
 dw $7000 ;moreFlags
 adrl 0 ;refCon
 dw 20 ;max size
 adrl PSTR_00000003 ;default

CTLTMP_00000009 equ *
 dw 7 ;pCount
cancel_id adrl $9 ;ID (9)
 dw 78,290,91,380 ;rect
 adrl $80000000 ;simple button
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl PSTR_00000004 ;title

CTLTMP_0000000A equ *
 dw 7 ;pCount
save_id adrl $A ;ID (10)
 dw 58,290,71,380 ;rect
 adrl $80000000 ;simple button
 dw $0001 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl PSTR_00000005 ;title

CTLTMP_0000000B equ *
 dw 8 ;pCount
 adrl $B ;ID (11)
 dw 23,104,35,136 ;rect
 adrl $82000000 ;check control
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl PSTR_00000006 ;title
dhcp_val dw 0 ;initial value

CTLTMP_0000000C equ *
 dw 9 ;pCount
 adrl $C ;ID (12)
 dw 25,18,34,87 ;rect
 adrl $81000000 ;static text
 dw $0000 ;flag
 dw $1000 ;moreFlags
 adrl 0 ;refCon
 adrl LETXTBOX_00000005 ;text reference
 dw LETXTBOX_00000005_LEN ;text size
 dw 0 ;justification

CTLTMP_0000000D         equ *
                        dw  9                       ;pCount
                        adrl $D                     ;ID (13)
                        dw  25,250,35,287           ;rect
                        adrl $81000000              ;static text
                        dw  $0000                   ;flag
                        dw  $1000                   ;moreFlags
                        adrl 0                      ;refCon
                        adrl LETXTBOX_00000006      ;text reference
                        dw  LETXTBOX_00000006_LEN   ;text size
                        dw  0                       ;justification

CTLTMP_0000000E equ *
 dw 8 ;pCount
mtu_id adrl $E ;ID (14)
 dw 23,290,37,342 ;rect
 adrl $83000000 ;line edit
 dw $0000 ;flag
 dw $7000 ;moreFlags
 adrl 0 ;refCon
 dw 20 ;max size
 adrl PSTR_00000007 ;default

PSTR_00000001 equ *
 dfb 13
 asc '192.168.0..zz'

PSTR_00000002 equ *
 dfb 13
 asc '255.255.255.0'

PSTR_00000003 equ *
 dfb 13
 asc '192.168.0.254'

PSTR_00000004 equ *
 dfb 6
 asc 'Cancel'

PSTR_00000005 equ *
 dfb 4
 asc 'Save'

PSTR_00000006 equ *
 dfb 0
 dfb $01

PSTR_00000007 
 dfb 4
 asc '1460'

LETXTBOX_00000001 equ *
 asc 'Ultimate Drive'
LETXTBOX_00000001_LEN equ *-LETXTBOX_00000001

LETXTBOX_00000002 equ *
 asc 'IP Address:'
LETXTBOX_00000002_LEN equ *-LETXTBOX_00000002

LETXTBOX_00000003 equ *
 asc 'Netmask:'
LETXTBOX_00000003_LEN equ *-LETXTBOX_00000003

LETXTBOX_00000004 equ *
 asc 'Gateway:'
LETXTBOX_00000004_LEN equ *-LETXTBOX_00000004

LETXTBOX_00000005 equ *
    asc 'DHCP:'
LETXTBOX_00000005_LEN equ *-LETXTBOX_00000005

LETXTBOX_00000006 equ *
 asc 'MTU:'
LETXTBOX_00000006_LEN equ *-LETXTBOX_00000006

*
* Window Definition
*
window
WPARAM1_00000FFA equ *
 dw $50 ;template size
 dw $00A0 ;frame bits
 adrl 0 ;no title
 adrl 0 ;window refcon
 dw 0,0,0,0 ;zoom rectangle
 adrl 0 ;standard colors
 dw 0,0 ;origin y/x
 dw 0,0 ;data height/width
 dw 0,0 ;max height/width
 dw 0,0 ;scroll vert/horiz
 dw 0,0 ;page vert/horiz
 adrl 0 ;info refcon
 dw 0 ;info height
 adrl 0 ;frame defproc
 adrl 0 ;info defproc
 adrl 0 ;content defproc
 dw 79,168,180,566 ;position
 adrl -1 ;plane
 adrl CTLLST_00001003 ;control reference
 dw 3 ;indescref

*-------------*
* end of data *
*-------------*
