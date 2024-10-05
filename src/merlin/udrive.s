*****************************************************************
*  UltimateDrive Marinetti Link Layer
*  Contributors:  Dagen Brock (w/ heavy cribbing from uthernet)
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
terrlinkerror           equ $0004+$3600
terrnoreconsupprt       equ $0014+$3600             ;this module doesn't support reconnect
terruseraborted         equ $0015+$3600
terrmask                equ $00ff

parmstack               equ 4
parmstackb              equ 1+parmstack

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
                        dw  UDLinkConnect
                        dw  udreconstatus
                        dw  udreconnect
                        dw  uddisconnect
                        dw  udgetvariables
                        dw  UDLinkConfigure
                        dw  UDLinkConfigFileName


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

                        ldx #15
clear_loop                                          ; flush the buffer
                        stz work_buffer,x
                        dex
                        dex
                        bpl clear_loop


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
                        _HLock
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
                        ldx #configAlertMtuStr
                        ldy #^configAlertMtuStr
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
                        PushLong #$b	; dhcp checkbox
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
                        PushLong #$4                ; ip address control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne ip_ok
                        ldx #configAlertIPStr
                        ldy #^configAlertIPStr
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
                        PushLong #$6                ; netmask control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne netm_ok
                        ldx #configAlertNmStr
                        ldy #^configAlertNmStr
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
                        PushLong #$8                ; gateway control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne gate_ok
                        ldx #configAlertGwStr
                        ldy #^configAlertGwStr
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

                        pla
                        sta 7,s
                        pla
                        sta 7,s
                        pla
                        pla
                        plb
                        rtl


show_alert              stx alert_strp2+1
                        sty alert_strp+1
                        pha
                        pea   $0051
                        pea	0
                        pea	0
                        *   PushLong #configAlertIPStr
alert_strp              pea 0
alert_strp2              pea 0
                        _AlertWindow	; warn that an invalid string was entered
                        pla
 
                        brl	modalloop
	

                        brl :okaaaa

* I don't see how this is supposed to work.  [4] isn't being managed right
* but this is what the other sources have been doing. 
* Is this call not yet in use?  UDLinkConfigure doesn't seem to need it.
* I'm marking as done though I believe that "[4]" is buggy. 
* @todo: check marinetti code for relevance
UDLinkConfigFileName
                        TSC
                        PHD
                        TCD
                        SEP $30
                        LDA >:CONFIGFNAME
                        TAX
]L1                     LDA >:CONFIGFNAME,X
                        TXY
                        STA [4],Y
                        DEX
                        BPL ]L1
                        REP $30
                        PLD
                        PHB
                        PLA
                        STA 3,S
                        PLA
                        STA 3,S
                        PLB
                        LDA #terrok
                        CLC
                        RTL

:CONFIGFNAME STR 'UDRIVE.config'




UDLinkConnect

                        phb                         ;push data bank register
                        phk                         ;push program bank register
                        plb                         ;pull databank register
                        sty UserID                  ;marinetti memory request id

                        lda #terruseraborted
                        sta err_return

                        stz MarinettiVariables+lverrors      ; start with a clean slate
                        stz MarinettiVariables+lvipaddress   ;
                        stz MarinettiVariables+lvipaddress+2
                        lda cfg_mtu                 ; 1460 byte mtu default
                        sta MarinettiVariables+lvmtu

                        lda parmstackb+16,s         ; check the msg flag
                        bne showokk                 ; there is msg display routine
                        stz displayptr+1            ; no display routine so skip printing a mesasge
                        stz displayptr+1+1
                        bra joinn
showokk                 lda parmstackb+4,s          ; get the display pointer and update the code
                        sta displayptr+1
                        lda parmstackb+4+1,s        ; **** SHOULD BE TWO BY CMD LIKE A3 0A
                        sta displayptr+1+1
                        lda #linkstrs               ; connection started
                        * jsr showpstring
joinn                   

                        lda parmstackb,s            ; get handle to config space low
                        sta cfghandle
                        lda parmstackb+2,s          ; get handle to config space high
                        sta cfghandle+2
                        lda [cfghandle]             ; use the handle to get the address of the config area
; setting up zero page access to the config area
; check handle size if not same as data, resize and copy new
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2
; check if we already have a config saved
                        ldy #8
                        lda [cfghandle],y
                        iny
                        iny
                        ora [cfghandle],y
                        beq newconfig
; we need to copy in the previous saved config or set one up for the first time
; use the config area to see what marinetti has for us to use
;
; configuration is our working copy of the config
;
                        lda [cfgptr]                ; test first word should match the config version
                        cmp #cfgvers
                        beq docfg                   ; on to the target address

; we havn't set one yet so use the defaults and report we can't start
newconfig               

                        * pea defaultcfg|-16          ; source address for the copy - low
                        * pea defaultcfg              ;                             - high
                        * pea UDConfiguration|-16       ; target address for the copy - low
                        * pea UDConfiguration           ; target address for the copy - high
                        * pea cfglen|-16              ; cfglen how many bytes to copy
                        * pea cfglen
                        PushLong UDDefaultCfg
                        PushLong UDConfiguration
                        PushLong cfglen
                        _TCPIPPtrToPtr              ; copy data routine

                        brl err

docfg                   

                        pei cfgptr+2                ; source address for the copy - low
                        pei cfgptr                  ;                             - high
                        * pea UDConfiguration|-16       ; target address for the copy - low
                        * pea UDConfiguration           ; target address for the copy - high
                        * pea cfglen|-16              ; cfglen how many bytes to copy
                        * pea cfglen
                        PushLong UDConfiguration
                        PushLong cfglen
                        _TCPIPPtrToPtr              ; copy data routine

                        lda UDConfiguration+28        ; 1460 byte mtu default
                        sta MarinettiVariables+lvmtu

;
; so now that we have a copy of our configuration data lets start to get the card going
;

                        pha                         ; seed the random number generator
                        pha
                        pha
                        pha
                        _ReadTimeHex                ; we don't have EM started, so use the clock
                        plx
                        ply
                        pla
                        pla
                        phy
                        phx
                        _SetRandSeed

                        lda UDConfiguration+20
                        asl a
                        asl a
                        asl a
                        asl a
                        ora #$0080
                        sta wiz_slot_offset

                        ldx #0
wiz_1                                           ; Fixup address at location
                        lda fixup,x
                        sta ap
                        lda (ap)
                        and #$ff0f
                        ora wiz_slot_offset
                        sta (ap)
; Advance to next fixup location
                        inx
                        inx
                        cpx #fixups
                        bcc wiz_1

                        sep $30

; S/W Reset
                        lda #$80
fixup01                 sta >mode
wiz_3                   
fixup02                 lda >mode
                        bmi wiz_3

; Indirect Bus I/F mode, Address Auto-Increment, Ping Block
                        lda #$13
fixup03                 sta >mode

; Source Hardware Address Register: MAC Address
                        ldx #$00                    ; Hibyte
                        ldy #$09                    ; Lobyte
                        jsr set_addr
wiz_4b                  lda UDConfiguration+14,x
fixup04                 sta >data
                        inx
                        cpx #$06
                        bcc wiz_4b

; RX Memory Size Register: Assign 8KB to socket 0
; TX Memory Size Register: Assign 8KB to socket 0
                        ldx #$00                    ; Hibyte
                        ldy #$1A                    ; Lobyte
                        jsr set_addr
                        lda #$03
fixup05                 sta >data
fixup06                 sta >data

; Max Segment Size Registers (MTU-40=MSS) Sockets 0: Assign 1460 as default
                        ldx #$04                    ; Hibyte
                        ldy #$12                    ; Lobyte socket 0
                        jsr set_addr
                        sec
                        lda MarinettiVariables+lvmtu         ; mtu lo
                        sbc #40
                        tax
                        lda MarinettiVariables+lvmtu+1       ; mtu hi
                        sbc #0
fixup30                 sta >data
                        txa
fixup31                 sta >data

; Socket 0 Mode Register: MACRAW, MAC Filter
; Socket 0 Command Register: OPEN
                        ldy #$00
                        jsr set_addrsocket0
                        lda #$44
fixup07                 sta >data
                        lda #$01
fixup08                 sta >data

                        rep $30

                        lda UDConfiguration+22        ; do we try dhcp to request an ip address
                        beq no_dhcp

* jsr request_dhcp            ; go and try to get one
                        bcs no_dhcp                 ; do not save it if we did not get one

                        ldy #2                      ; copy our ip address, mask, gateway to parms
copy_tmp                
                        lda tmp_ip-2,y
                        sta UDConfiguration,y         ; keep it locally
                        iny
                        iny
                        cpy #14
                        bcc copy_tmp

                        lda tmp_dns                 ; check if primary empty
                        ora tmp_dns+2
                        beq mtu_offered

                        PushLong #tmp_dns           ; copy the new dns back to marinetti
                        _TCPIPSetDNS

mtu_offered             

                        lda tmp_mtu                 ; did the server tell us its mtu size
                        beq no_dhcp
                        cmp #1500
                        bcs no_dhcp
                        sta MarinettiVariables+lvmtu

no_dhcp                 

                        lda #wizversl               ; copy our version marker as it may have changed
                        sta UDConfiguration+24
                        lda #wizversh
                        sta UDConfiguration+26

                        pha                         ; now we must create a handle to pass back the updated data
                        pha
                        PushLong #cfglen
                        PushWord UserID
                        pea $18
                        pea 0
                        pea 0
                        _NewHandle
                        PullLong temphandle

                        PushLong #UDConfiguration     ; copy the data to the handle
                        PushLong temphandle
                        PushLong #cfglen
                        _PtrToHand

                        PushWord #conUthernet2      ; now tell marinetti the new data if we change
                        PushLong temphandle
                        _TCPIPSetConnectData

                        lda UDConfiguration+2         ; cfgip offset = 2
                        sta MarinettiVariables+lvipaddress
                        lda UDConfiguration+2+2    ; cfgip offset = 2
                        sta MarinettiVariables+lvipaddress+2

                        lda UDConfiguration+6         ; cfgipmask offset = 6
                        sta ipmask                  ; zero page var
                        lda UDConfiguration+6+2    ; cfgipmask offset = 6
                        sta ipmask+2

                        lda UDConfiguration+10        ; cfgipgw offset = 10
                        sta ipgw                    ; zero page var
                        lda UDConfiguration+10+2   ; cfgipgw offset = 10
                        sta ipgw+2

                        lda #setmacstr              ; display our connect data
                        * jsr showpstring

; initialize arp

                        sep $30

                        lda #0
                        ldx #6+4*ac_size-1        ; clear cache
clr                     sta arp_cache,x
                        dex
                        bpl clr

                        lda #$ff                    ; counter for netmask length - 1
                        sta gw_last

                        ldx #3
gw                      
                        lda ipmask,x
                        eor #$ff
                        cmp #$ff
                        beq next                    ; was bne
                        inc gw_last
next                    sta gw_mask,x
                        ora ipgw,x
                        sta gw_test,x
                        dex
                        bpl gw

; Gateway Address Register: Gateway Address
                        ldx #$00                    ; Hibyte
                        ldy #$01                    ; Lobyte
                        jsr set_addr
wiz_4                   lda UDConfiguration+10,x
fixup09                 sta >data
                        inx
                        cpx #$04
                        bcc wiz_4

; Subnet Address Register: Subnet Address
                        ldx #$00                    ; Hibyte
                        ldy #$05                    ; Lobyte
                        jsr set_addr
wiz_4a                  lda UDConfiguration+6,x
fixup10                 sta >data
                        inx
                        cpx #$04
                        bcc wiz_4a

; Source IP Address Register: IP Address
                        ldx #$00                    ; Hibyte
                        ldy #$0F                    ; Lobyte
                        jsr set_addr
wiz_4c                  lda UDConfiguration+2,x
fixup11                 sta >data
                        inx
                        cpx #$04
                        bcc wiz_4c

                        rep $30

                        lda #arp_idle               ; start out idle
                        sta arp_state

                        lda #true
                        sta MarinettiVariables+lvconnected
                        lda #terrok
                        sta err_return

err                     rep $30

                        pla
                        sta 21,s
                        pla
                        sta 21,s
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        lda err_return
                        plb
                        cmp #1
                        rtl


setmacstr               str 'MAC                    address initialized '
linkstrs                str 'Starting               UthernetII driver'

reg                     dw  0                    ; register
len                     dw  0                    ; Packet length counter
adv                     dw  0                    ; Data pointer advancement
bas                     dw  0                    ; register base memory

err_return              ds  2
temphandle              ds  4
wiz_slot_offset         dw  $0040

fixup                   da fixup01+1,fixup02+1,fixup03+1,fixup04+1,fixup05+1,fixup06+1
                        da fixup07+1,fixup08+1,fixup09+1,fixup10+1,fixup11+1,fixup12+1
                        da fixup13+1,fixup14+1,fixup16+1,fixup17+1,fixup18+1,fixup19+1
                        da fixup20+1,fixup22+1,fixup23+1,fixup24+1,fixup25+1,fixup26+1
                        da fixup27+1,fixup28+1,fixup29+1,fixup30+1,fixup31+1
fixups                  equ *-fixup



*-------------------------------------------------
* common sub routines
*-------------------------------------------------

; retrieve a packet
eth_rx                  sep $30
; Check for completion of previous command
                        jsr set_addrcmdreg0         ; set command reg = 0 ?
fixup12                 lda >data
                        beq wiz_6

; No data available
wiz_5                   rep $30
                        sec
                        rts
                        
                        mx %11
; Socket 0 RX Received Size Register: != 0 ?
wiz_6                   ldy #$26                    ; Socket RX Received Size Register
                        jsr set_addrsocket0
fixup13                 lda >data                   ; Hibyte
fixup14                 ora >data                   ; Lobyte
                        beq wiz_5

; Process the incoming data
; -------------------------

; Set parameters for receiving data
                        lda #>$6000                 ; Socket 0 RX Base Address
                        jsr set_parameters

; commented out in w1500s.txt
;	ldy #$28		; Socket RX Read Pointer Register
;	jsr set_addrsocket0

; Calculate and set physical address
                        jsr set_addrphysical

; Move physical address shadow to $E000-$FFFF
                        ora #>$8000
                        tax

; Read MAC raw 2byte packet size header
                        jsr get_datacheckaddr       ; Hibyte
                        sta adv+1
                        jsr get_datacheckaddr       ; Lobyte
                        sta adv

                        rep $30
; Subtract 2byte header and set length
                        sec
                        lda adv
                        sbc #$0002
                        sta len

; Is bufsize < length ?
                        cmp bufsize
                        bcc wiz_7

; Set data length = 0 and skip read
                        stz len
                        bra wiz_8                   ; Always

; Read data
wiz_7                   
                        rep $10 ;shortm
                        ldx #0
wiz_13                  
fixup17                 lda >data
                        sta eth_inp,x
                        inx
                        cpx len
                        bcc wiz_13

; Set parameters for common code
wiz_8                   
                        sep $30
                        lda #$40                    ; RECV
                        ldy #$28                    ; Socket 0 RX Read Pointer Register
                        jsr common
                        mx %00

                        clc
                        rts

*-------------------------------------------------
; send a packet

eth_tx                  
                        jsr timer_read              ; read current timer value
                        clc
                        adc #0300                   ; set timeout to now+5000 ms
                        sta packettimeout

                        lda eth_outp_len
                        sta adv

                        sep $30

; Set parameters for transmitting data
                        lda #>$4000                 ; Socket 0 TX Base Address
                        jsr set_parameters

; Wait for completion of previous command
; Socket 0 Command Register: = 0 ?
wiz_9                   anop
                        sep $30
                        jsr set_addrcmdreg0
fixup18                 lda >data
                        beq wiz_10
                        rep $30 
                        jsr timer_read              ; read current timer value
                        cmp packettimeout
                        bcc wiz_9
                        sec
                        rts

                        mx %11

; Socket 0 TX Free Size Register: < length ?
wiz_10                  
                        ldy #$20                    ; Socket TX Free Size Register
                        jsr set_addrsocket0
fixup19                 lda >data                   ; Hibyte
                        pha
fixup20                 lda >data                   ; Lobyte
                        tax
                        pla
                        cpx eth_outp_len
                        sbc eth_outp_len+1
                        bcc wiz_10

; Send the data
; -------------

                        ldy #$24                    ; Socket TX Write Pointer Register
                        jsr set_addrsocket0

; Calculate and set physical address
                        jsr set_addrphysical

; Write data
                        rep $10 ; longx
                        ldx #0
wiz_14                  
                        lda eth_outp,x
fixup23                 sta >data
                        inx
                        cpx eth_outp_len
                        bcc wiz_14
                        sep $10

; Set parameters for common code
                        lda #$20                    ; SEND
                        ldy #$24                    ; Socket TX Write Pointer Register
; Advance pointer register
common                  jsr set_addrsocket0
                        tay                         ; Save command
                        clc
                        lda reg
                        adc adv
                        tax
                        lda reg+1
                        adc adv+1
fixup24                 sta >data                   ; Hibyte
                        txa
fixup25                 sta >data                   ; Lobyte

; Set command register
                        tya                         ; Restore command
                        jsr set_addrcmdreg0
fixup26                 sta >data
                        rep $30
                        clc
                        rts


;---------------------------------------------------------------------
                        mx %11
set_addrphysical
fixup27                 lda >data                   ; Hibyte
                        pha
fixup28                 lda >data                   ; Lobyte
                        tay
                        pla
                        sty reg
                        sta reg+1
                        and #>$1FFF                 ; Socket Mask Address (hibyte)
                        ora bas+1                   ; Socket Base Address (hibyte)
                        tax
set_addr
                        pha
                        txa
fixup29                 sta >addr                   ; Hibyte
                        tya
fixup22                 sta >addr+1                 ; Lobyte
                        pla
                        rts

set_addrcmdreg0
                        ldy #$01                    ; Socket Command Register
set_addrsocket0
                        ldx #>$0400                 ; Socket 0 register base address
                        bra set_addr                ; Always

set_addrbase
                        ldx bas+1                   ; Socket Base Address (hibyte)
                        ldy #<$0000                 ; Socket Base Address (lobyte)
                        bra set_addr                ; Always

get_datacheckaddr
fixup16                 lda >data
                        iny                         ; Physical address shadow (lobyte)
                        bne wiz_11
                        inx                         ; Physical address shadow (hibyte)
                        beq set_addrbase
wiz_11                  rts



; Setup variables in zero page
set_parameters         
	stz	bas
	sta bas+1		; Socket Base Address
	clc
	adc #>$2000		; Socket memory size
	rts
	


showpstring
                        phy
                        tax
                        lda >displayptr+1
                        ora >displayptr+1+1
                        beq :nullstring
* pea	*|-16
                        phx
displayptr
                        jsl displayptr              ; SMC
:nullstring             ply
                        rts




; timer routines (original comments)
;
; the  should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate,
; if you're working with e.g. a 60 hz vblank irq, adding 17 to the
; counter every frame would be just fine.
; code mofied to work with 1/60 of a second


; return the current value
timer_read	
	pha
	pha
	_TickCount
	PullLong tick_count_cur
; how many ticks have tocked since the last tick did tock
	SUB4 	tick_count_cur;tick_count_start;tick_temp
	lda	tick_temp
; more than 60 (1 second)
	cmp	#60
	bcc	ret
	ADD4 	tick_count_start;60
	SUB4    tick_temp;60
	lda 	tick_temp
ret	
	rts
	
; we can't use tickcount during dhcp negotiation, as the event manager has not yet been started
; but we can use the clock, with some more elaborate code...
; return current elapsed time in seconds, accounting for midnight rollover
; we are not going to be more than 60 seconds in here, so we will not span two days!
timer_read2	

	pha
	pha
	pha
	pha
	_ReadTimeHex
	pla	; read mins and secs
	sta	tick_temp
	pla	; read hour and year
	sta	tick_temp+2
	plx	; throw dates
	plx	; throw dates
	and	#$ff	; hours
	asl	a
	asl	a
	sta	tick_temp+4
	asl	a
	asl	a
	asl	a
	asl	a
	sec
	sbc	tick_temp+4
	sta	timer	; we have minutes
	lda	tick_temp+1	; mins
	and	#$ff
	asl	a
	asl	a
	sta	tick_temp+4
	asl	a
	asl	a
	asl	a
	asl	a
	sec
	sbc	tick_temp+4
	clc
	adc timer
	sta	timer	; we have seconds
	lda	timer+2
	adc	#$00
	sta	timer+2
	lda	tick_temp
	and	#$ff
	clc
	adc	timer
	sta	timer	; total current seconds since midnight
	lda	timer+2
	adc	#$00
	sta	timer+2
	
tr_loop 
	sec
	lda	timer
	sbc	start_time
	tax
	lda	timer+2
	sbc	start_time+2
	bpl tr_exit
	clc
	lda	timer
	adc	#<86400	; seconds in a day
	sta	timer
	lda	timer+2
	adc	#>86400
	sta	timer+2
	bra	tr_loop	
tr_exit 
	txa
	rts	

tick_count_cur	ds 4		; .res 2
tick_count_start ds 4
tick_temp	ds 6
time		ds 2		; .res 2
timer		ds 4
start_time  adrl 0




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

:okaaaa                 lda #terrok
                        clc
                        rtl

work_buffer             ds  17
response_buffer         ds  4

configAlertIPStr        asc '63~Invalid             value entered for IP Address.',0D0D
                        asc '~^#4',00
configAlertGwStr        asc '63~Invalid             value entered for Gateway.',0D0D
                        asc '~^#4',00
configAlertNmStr        asc '63~Invalid             value entered for Netmask.',0D0D
                        asc '~^#4',00
configAlertMtuStr       asc '63~Invalid             value entered for MTU.',0D0D
                        asc 'Valid                  values are 576 - 1600.'
                        asc '~^#4',00


* Not used... yet ;)
testalert               ASC '63~UltimateDrive       Link Layer',0D0D
                        ASC 'Copyright              (c) 2024 by UltimateDrive Team',0D,
                        asc '                       Dagen Brock & Phil Timmes',0D
                        ASC '~^#0'
                        DFB 0



UserID                  dw  0                       ; Program's ID from MemoryManager

; my direct space on marinetti's direct page $E0-$FF available
* tmppkthandle gequ $e0
* cnt			gequ $e4
cfghandle               equ $E8
cfgptr                  equ $EC
ap                      equ $F0
* eth_packet	gequ $f2
ipmask                  equ $F4
ipgw                    equ $F8
bufsize dw  #1518	; Size

eth_inp_len	ds 2         	; input packet length
eth_inp		ds 1518	; space for input packet
	asc	"eth_outp"
eth_outp_len ds 2		; output packet length
eth_outp	ds 1518	; space for output packet

; gateway handling
gw_mask                 ds  4                       ; inverted netmask
gw_test                 ds  4                       ; gateway ip or:d with inverted netmask
gw_last                 ds  1                       ; netmask length - 1

; timeout
arptimeout	ds 2		; time when we will have timed out
packettimeout ds 2		; for sending packets

* set version to v2.0.5d1
wizversh                equ $0205                   ;mmmm_mmmm_mmmm_bbbb
wizversl                equ $2001                   ;sss0_0000_rrrr_rrrr ss-20=d,40=a,60=b,80=f,a0=r

; wiz card registers
mode                    equ $e0c084                 ; Mid byte patched at runtime
addr                    equ $e0c085                 ; Mid byte patched at runtime
data                    equ $e0c087                 ; Mid byte patched at runtime

; holding values for packet retrieval
tmp_data
tmp_ip                  ds  4
* tmp_netmask ds 4
* tmp_gateway ds 4
* tmp_server ds 4
* tmp_lease ds 4
tmp_dns                 ds  4
* tmp_dns2 ds 4
* tmp_src_mac ds 6
* tmp_src_ip ds 4
tmp_mtu                 ds  2
tmp_length              equ *-tmp_data


; arp state machine
arp_idle                equ 1                       ; idling
arp_wait                equ 2                       ; waiting for reply
arp_state               ds  2                       ; current activity

; arguments for lookup and add
arp                                                 ; ptr to mac/ip pair
arp_mac                 ds  6                       ; result is delivered here
arp_ip                  ds  4                       ; set ip before calling lookup

; arp cache
ac_size                 equ 8                       ; lookup cache
ac_ip                   equ 6                       ; offset for ip
ac_mac                  equ 0                       ; offset for mac
arp_cache               ds  6+4*ac_size             ; .res (6+4)*ac_size

MarinettiVariables      ds  lvlen
;link layer variables as defined by marinetti
lvversion               equ $0000
lvconnected             equ $0002
lvipaddress             equ $0004
lvrefcon                equ $0008
lverrors                equ $000c
lvmtu                   equ $0010
lvlen                   equ $0012

true                    equ $8000
false                   equ $0000


                        put marinetti_equates
                        put udnetrz

                        use Mem.Macs                ;standard merlin32 (and merlin16) macros
                        use Util.Macs               ;standard merlin32 (and merlin16) macros
                        use Window.Macs             ;standard merlin32 (and merlin16) macros
                        use Qd.Macs                 ;standard merlin32 (and merlin16) macros
                        use Ctl.Macs                ;standard merlin32 (and merlin16) macros
                        use Int.Macs                ;standard merlin32 (and merlin16) macros
                        use Misc.Macs                ;standard merlin32 (and merlin16) macros
                        use Event.Macs                ;standard merlin32 (and merlin16) macros
                        use Macros                ;standard merlin32 (and merlin16) macros
                        
]tcpiptoolnum           equ $36
                        use TCPIP.MACS.S            ;from Marinetti sources