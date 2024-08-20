*****************************************************************
*  UltimateDrive Marinetti Link Layer
*  Contributors:  Dagen Brock
*
*
* Marinetti3 Programming Guide
* https://www.apple2.org/marinetti/Mar30ProgGuide.pdf
*
* Call Structure Overview
* A   : Module’s direct page if one was loaded as OMF, else $0000
* X   : Call number
* Y   : Marinetti UserID
*       (While loaded, modules are considered a part of Marinetti,
*        and as such, all memory allocations must use Marinetti’s
*        UserID, and not the module’s)
* DBK : Unknown
* DP  : Marinetti’s direct page
* S   : RTL address then parameter
*
* My Notes:
* - First call during boot:              m=0 a=0 x=0 y=3112     interfacev
* - Second call after returning version: m=0 a=0 x=6 y=3112     moduleinfo
***************************************

*                        XPL
                        mx  %00
                        REL
                        TYP $BC

                        LNK udnet.l                 ;
terrok                  equ $0000
parmstack               equ 4
myllintvers             equ 2

entry                   brl udriveok
                        dw  $7771
                        str 'UltimateDrive'         ; just for debugging? not sure if needed

udriveok                nop
                        nop                      
                        jmp (routines,x)

routines                dw  UDLinkInterfaceV
                        dw  UDLinkStartup
                        dw  UDLinkShutdown
                        dw  UDLinkModuleInfo
                        dw  udgetpacket
                        dw  udsendpacket
                        dw  udconnect
                        dw  udreconstatus
                        dw  udreconnect
                        dw  uddisconnect
                        dw  udgetvariables
                        dw  UDLinkConfigure
                        dw  udconfigfname


* Returns the maximum link layer module interface which this link layer module supports.
UDLinkInterfaceV
                        brl intvok
intvok                  nop
                        nop
                        lda #myllintvers
                        sta parmstack,s

                        lda #terrok
                        clc
                        rtl



* Starts the link layer module once it is loaded. The module should
* perform any initialisation tasks short of actually starting a connection.
UDLinkStartup
UDLinkShutdown
                        brl :okaaaa


* Marinetti 3.0 Programmers’ Guide Page 168
* Stack passes in a LONG ptr to 27byte buffer which we fill like below.
* linkInfoBlkPtr  Points to a fixed length 27 byte response buffer as follows:
*                 +00 liMethodID   word      The connect method. See the conXXX
*                                            equates at the end of this document
*                                            (actually marinetti_equates.s)
*                 +02 liName 21    bytes     Pstring name of the module
*                 +23 liVersion    longword  rVersion (type $8029 resource layout) of
*                                            the module
*                 +27 liFlags      word      Contains the following flags:
*                        bit15    This link layer uses the built in Apple IIGS serial ports
*                        bit14    This link layer is being executed in an emulator
*                        bits13-1 Reserved – set to zeros
*                        bit0     Indicates whether the module contains an rIcon resource
*
UDLinkModuleInfo        brl intmodok

intmodok                nop
                        nop

                        PHB                         ; let's return the whole thing on the stack, trololol...
                        PHK
                        PLB
                        TSC
                        PHD
                        TCD
                        SEP $30
                        LDY #UDLinkModuleInfoDataL-1
]L1                     LDA UDLinkModuleInfoData,Y
                        STA [1+parmstack],Y
                        DEY
                        BPL ]L1
                        REP $30
                        PLD
                        PLA
                        STA 3,S
                        PLA
                        STA 3,S
                        PLB
                        LDA #terrok
                        CLC
                        RTL


UDLinkModuleInfoData
                        dw  conUltimateDrive
ll_name                 str 'UltimateDrive'
                        ds  21-{*-ll_name}          ; pad using subexpression for merlin32
ll_vers                 adrl #$1
ll_flags                dw  0
UDLinkModuleInfoDataL   =   *-UDLinkModuleInfoData


* Marinetti 3.0 Programmers’ Guide Page 150-151
* When called, the desktop will be displayed, and the following tool sets will guarantee to have been started.
* Other tool sets may have also been started, but the module should check before using them and start them
* if necessary, and shut them down again on exit.
*   Tool Set Name           Tool Set No.
*   Tool Locator            #01 $01
*   Memory Manager          #02 $02
*   Miscellaneous Toolset   #03 $03
*   Quickdraw II            #04 $04
*   Event Manager           #05 $05
*   Integer Math Toolset    #11 $0B
*   Text Toolset            #12 $0C
*   Window Manager          #14 $0E
*   Menu Manager            #15 $0F
*   Control Manager         #16 $10
*   System Loader           #17 $11
*   Quickdraw II Auxilliary #18 $12
*   LineEdit Toolset        #20 $14
*   Dialog Manager          #21 $15
*   Scrap Manager           #22 $16
*   TCP/IP                  #54 $36
* NOTE: The module's resource fork is not available during calls to the module. Attempts by a module
* to open its resource fork may cause the module and Marinetti to crash
*
* Called with two LONGS on stack, `connectHandle` and `disconnectHandle`
UDLinkConfigure         phb
                        phk
                        plb

                        lda 9+2,s
                        sta cfghandle+2
                        lda 9,s
                        sta cfghandle               ; dp cfghandle (~~00/18e8) is now E0/8940
                        ldy #8                      ;
                        lda [cfghandle],y
                        iny
                        iny
                        ora [cfghandle],y           ; check if zero
                        beq zerolen
                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2                ; now cfgptr points to actual config area
                        lda [cfgptr]                ; test first word should match the config version
                        cmp #cfgvers                ;check version
                        beq versok

zerolen                                             ; CREATE new config
                        PushLong #cfglen
                        PushLong cfghandle
                        _SetHandleSize              ; set empty handle to size of our data

                        PushLong #UDDefaultCfg
                        PushLong cfghandle
                        PushLong #cfglen
                        _PtrToHand                  ; copy our default data over

versok

                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2


; get the slot number and dhcp setting
                        * ldy #20			; slot number
                        * lda [cfgptr],y
                        * ora	#$0100	; menu id offset
                        * sta	popupid

                        ldy #22			; dhcp flag
                        lda [cfgptr],y
                        sta	dhcp_val

                        pha
                        pha
                        _GetPort



; open up the dialog window

                        pha                         ; LONG result space
                        pha
                        pea 0                       ; LONG titlePtr
                        pea 0
                        pea 0                       ; LONG refCon
                        pea 1
                        pea 0                       ; LONG contentDrawPtr
                        pea 0
                        pea 0                       ; LONG defProcPtr
                        pea 0
                        pea 0                       ; WORD paramTableDesc (0= ptr to window template)
                        PushLong #window            ; LONG paramTableRef
                        pea $800e                   ; WORD resourceType
                        _NewWindow2                 ; open a dialog
                        PullLong ourwindow

                        PushLong ourwindow          ; make current grafPort
                        _SetPort

                        PushLong cfghandle
                        _HLock                      ; lock handle from compaction/movement

                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2

; now set the strings for the three ip addresss

                        pha
                        ldy #4                      ; ipaddress hi
                        lda [cfgptr],y
                        pha
                        dey
                        dey
                        lda [cfgptr],y              ; ipaddress lo
                        pha
                        PushLong #work_buffer
                        pea 0
                        _TCPIPConvertIPToASCII
                        pla
                        PushLong ourwindow
                        PushLong #$4                ; ip address control
                        PushLong #work_buffer
                        _SetLETextByID


                        pha
                        ldy #8                      ; netmask hi
                        lda [cfgptr],y
                        pha
                        dey
                        dey
                        lda [cfgptr],y              ; netmask lo
                        pha
                        PushLong #work_buffer
                        pea 0
                        _TCPIPConvertIPToASCII
                        pla
                        PushLong ourwindow
                        PushLong #$6                ; netmask control
                        PushLong #work_buffer
                        _SetLETextByID

                        pha
                        ldy #12                     ; gateway hi
                        lda [cfgptr],y
                        pha
                        dey
                        dey
                        lda [cfgptr],y              ; gateway lo
                        pha
                        PushLong #work_buffer
                        pea 0
                        _TCPIPConvertIPToASCII
                        pla
                        PushLong ourwindow
                        PushLong #$8                ; gateway control
                        PushLong #work_buffer
                        _SetLETextByID

* NOTE: SKIPPED MAC ADDRESS LSB SETTING...

; set the mtu value

                        ldy #28                     ; mtu value
                        lda [cfgptr],y
                        pha
                        PushLong #PSTR_00000007+1
                        pea 4
                        pea 0
                        _Int2Dec
                        PushLong ourwindow
                        PushLong mtu_id
                        PushLong #PSTR_00000007
                        _SetLETextByID

                        PushLong cfghandle
                        _HUnlock


MODALLLLLOOOOOP                                     ;**********************************************************************
modalloop                                           ; interface with taskmaster

                        pha
                        pha
                        PushLong #eventrecord
                        pea 0
                        pea 0
                        PushLong #$80000000         ;event hook
                        pea 0                       ;beep procedure
                        pea 0
                        pea $0008
                        _DoModalWindow
                        pla
                        plx

                        cmp #0
                        beq modalloop
_modal_chk_cancel       cmp cancel_id               ; cancel button
                        bne _modal_chk_save
                        brl configexit
_modal_chk_save         cmp save_id
                        beq letsgo
                        bra modalloop

letsgo
                        PushLong cfghandle
                        _HUnlock
                        lda	[cfghandle]	; use the handle to get the address of the config area
                        sta	cfgptr
                        ldy	#2
                        lda	[cfghandle],y
                        sta	cfgptr+2
	
; now get back and store the returned values

                        PushLong ourwindow
                        PushLong mtu_id
                        PushLong #work_buffer
                        _GetLETextByID

                        pha
                        PushLong #work_buffer+1
                        pea	4
                        pea	0
                        _Dec2Int
                        pla
                        cmp	#576
                        bcc	mtu_bad
                        cmp	#1601
                        bcc mtu_ok
mtu_bad 
	                    brl	show_alert
mtu_ok 
                        ldy	#28
                        sta	UDConfiguration+28
                        sta MarinettiVariables+lvmtu
                        sta [cfgptr],y

                        ; SLOT
                        * pha
                        * pha
                        * pha
                        * PushLong ourwindow
                        * PushLong #9	; menu popup id
                        * _getctlhandlefromid
                        * _getctlvalue
                        * pla
                        * and	#$ff
                        * ldy #20			; slot number
                        * sta [cfgptr],y

                        pha
                        pha
                        pha
                        PushLong ourwindow
                        PushLong #$e	; dhcp checkbox
                        _GetCtlHandleFromID
                        _GetCtlValue
                        pla
                        ldy #22			; dhcp flag
                        sta [cfgptr],y
                        cmp	#0
                        beq	non_dhcp
                        brl	dhcp_ok


non_dhcp               
                        PushLong ourwindow
                        PushLong #$a                ; ip address control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne ip_ok
                        brl show_alert
ip_ok                   
                        PushLong #response_buffer
                        PushLong #work_buffer
                        _TCPIPConvertIPToHex
                        ldy #2                      ; ip address
                        lda response_buffer
                        sta [cfgptr],y
                        iny
                        iny
                        lda response_buffer+2
                        sta [cfgptr],y

                        PushLong ourwindow
                        PushLong #$b                ; netmask control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne netm_ok
                        brl show_alert
netm_ok                 
                        PushLong #response_buffer
                        PushLong #work_buffer
                        _TCPIPConvertIPToHex
                        ldy #6                      ; netmask
                        lda response_buffer
                        sta [cfgptr],y
                        iny
                        iny
                        lda response_buffer+2
                        sta [cfgptr],y

                        PushLong ourwindow
                        PushLong #$c                ; gateway control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne gate_ok
                        brl show_alert
gate_ok                 
                        PushLong #response_buffer
                        PushLong #work_buffer
                        _TCPIPConvertIPToHex
                        ldy #10                     ; gateway
                        lda response_buffer
                        sta [cfgptr],y
                        iny
                        iny
                        lda response_buffer+2
                        sta [cfgptr],y

dhcp_ok                 

configexit              

                        PushLong ourwindow
                        _CloseWindow
                        _SetPort

                        PushLong cfghandle
                        _HUnlock

                        * brk $ff


                        pla
                        sta 7,s
                        pla
                        sta 7,s
                        pla
                        pla
                        plb
                        rtl


	
show_alert 

                        pha
                        pea   $0051
                        pea	0
                        pea	0
                        PushLong #alertstr
                        _AlertWindow	; warn that an invalid string was entered
                        pla

                        brl	modalloop
	

                        brl :okaaaa
ourwindow               ds  4


eventrecord             =   *
eventwhat               ds  2
eventmessage            ds  4
eventwhen               ds  4
eventwhere              ds  4
eventmodifiers          ds  2
taskdata                ds  4
taskmask                adrl $001fffef
lastclicktick           ds  4
clickcount              ds  2
taskdata2               ds  4
taskdata3               ds  4
taskdata4               ds  4
lastclickpoint          ds  4



; cfgdata  data
UDDefaultCfg
cfgvers                 =   1
; connect data
cfgversion              dw  cfgvers                 ; +0 version
cfg_ip                  db  192,168,0,123           ; +2 ip
cfg_netmask             db  255,255,255,223         ; +6 netmask
cfg_gateway             db  192,168,0,103           ; +10 gateway
cfg_mac                 hex 00,08,dc,11,11,11       ; +14 OUI of WIZnet
cfg_slot                dw  4                       ; +20 slot
use_dhcp                dw  0                       ; offset 22
cfg_vers                dw  ^ll_vers                ; offset 24
                        dw  ll_vers                 ; offset 26
cfg_mtu                 dw  1460                    ; offset 28
                        ds  64-{*-UDDefaultCfg}     ; pad to 64 to be less brittle on version changes

cfglen                  =   64

UDConfiguration         ds  cfglen                  ; 30 total - this is our actual buffer



udgetpacket
udsendpacket
udconnect
udreconstatus
udreconnect
uddisconnect
udgetvariables
udconfigfname
:okaaaa                 lda #terrok
                        clc
                        rtl

work_buffer             ds  17
response_buffer         ds 4

alertstr                str '/Invalid value entered!/^#4'
                        hex 00

; my direct space on marinetti's direct page $E0-$FF available
* tmppkthandle gequ $e0
* cnt			gequ $e4
cfghandle               equ $E8
cfgptr                  equ $EC
* ap			gequ $f0
* eth_packet	gequ $f2
* ipmask		gequ $f4
* ipgw		gequ $f8


MarinettiVariables      ds lvlen
;link layer variables as defined by marinetti
lvversion	            equ $0000
lvconnected	            equ $0002
lvipaddress	            equ $0004
lvrefcon	            equ $0008
lverrors	            equ $000c
lvmtu		            equ $0010
lvlen		            equ $0012


                        put marinetti_equates
                        put udnetrz

                        use Mem.Macs                ;standard merlin32 (and merlin16) macros
                        use Util.Macs               ;standard merlin32 (and merlin16) macros
                        use Window.Macs             ;standard merlin32 (and merlin16) macros
                        use Qd.Macs                 ;standard merlin32 (and merlin16) macros
                        use Ctl.Macs                ;standard merlin32 (and merlin16) macros
                        use Int.Macs                ;standard merlin32 (and merlin16) macros
]tcpiptoolnum           equ $36
                        use TCPIP.MACS.S            ;from Marinetti sources