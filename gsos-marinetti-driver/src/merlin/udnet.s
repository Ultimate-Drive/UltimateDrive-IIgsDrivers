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
*****************************************************************

** "#IFDEFS" to control how we're building this:
DEBUG_OUT               = 0 ; 1=on 0=off
DEBUG_BORDER            = 0 ;


                        mx  %00
                        REL                         ; relocatable code segment
                        TYP $BC                     ; marinetti link layer type
                        LNK udnet.l                 ;


entry                                               ; entry point as defined in link file
                        ;brl dispatch                ; removed for now
                        ;dw  $7771
                        ;str 'UltimateDrive'         ; label for gsbug

** MAIN DISPATCH FOR ALL CALLS
dispatch
                        jmp (routines,x)
routines                dw  UDLinkInterfaceV
                        dw  UDLinkStartup
                        dw  UDLinkShutdown
                        dw  UDLinkModuleInfo
                        dw  UDLinkGetPacket
                        dw  UDLinkSendPacket
                        dw  UDLinkConnect
                        dw  UDLinkReconStatus
                        dw  UDLinkReconnect
                        dw  UDDisconnect
                        dw  UDLinkGetVariables
                        dw  UDLinkConfigure
                        dw  UDLinkConfigFileName


* Returns the maximum link layer module interface which this link layer module supports.
UDLinkInterfaceV
                        lda #myllintvers
                        sta parmstack,s

                        lda #terrok
                        clc
                        rtl
     

* Starts the link layer module once it is loaded. The module should
* perform any initialisation tasks short of actually starting a connection.
UDLinkStartup
                        jsr UDDetectSlot
UDLinkShutdown
                        lda #terrok
                        clc
                        rtl


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
UDLinkModuleInfo        phb                         ; let's return the whole thing on the stack, trololol...
                        phk
                        plb
                        tsc
                        phd
                        tcd
                        sep $30
                        ldy #ll_modinfolen-1
]L1                     lda ll_modinfo,Y
                        sta [1+parmstack],Y
                        dey
                        bpl ]L1
                        rep $30
                        pld
                        pla
                        sta 3,S
                        pla
                        sta 3,S
                        plb
                        lda #terrok
                        clc
                        rtl

* Attempts to disconnect Marinetti from the network.
UDLinkDisconnect        phb
                        phk
                        plb

                        lda parmstackb+16,s
                        bne :showok
                        stz displayptr+1
                        stz displayptr+2
                        bra :join
:showok                 lda parmstackb+4,s
                        sta displayptr+1
                        lda parmstackb+5,s
                        sta displayptr+2
:join                   
                        lda #linkstre
                        jsr showpstring
                        jsr UDDisconnect
                        lda #false
                        sta MarinettiVariables+lvconnected
                        lda #terrok
                        tax
                        pla
                        sta 17,s
                        pla
                        sta 17,s
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        pla
                        txa
                        plb
                        cmp #1
                        rtl

linkstre                str 'Stopping UltimateDrive Ethernet Adapter'


* Returns a flag indicating whether the module is in a state to reconnect.
UDLinkReconStatus       mx  %00
                        lda #false
                        sta parmstack,s
                        clc
                        rtl

* This is not needed.  It's for protocols like SLIP.  See Marinetti 3.0 Programmers’ Guide p.143
UDLinkReconnect         mx  %00
                        phb
                        pla
                        sta 3,s
                        pla
                        sta 3,s
                        plb
                        lda #terrnoreconsupprt
                        and terrmask
                        sec
                        rtl

* Returns a pointer to the link layer module’s variables.
UDLinkGetVariables
                        lda   #MarinettiVariables
                        sta   4,s
                        lda   #^MarinettiVariables
                        sta   4+2,s
                        lda   #terrok
                        clc
                        rtl

* Returns a raw data datagram from the network.
UDLinkGetPacket 
                        phb			; push data bank register
                        phk			; push program bank register
                        plb			; pull databank register
                        sty	UserID	; save marinetti userid


                        jsr UDNetPeek

                        bne :get_pak
                        brl :none
:get_pak                cmp #1518
                        bcc :no2long
                        lda #1518
                        sta UDPacketLen
                        BorderColor #5
                        bra :no2long
                        *  lda #2
                        * ldx #UDPacketLen     ; 
                        * ldy #^UDPacketLen     ; 
                        * jsr HexDumpBuffer   ; -------------------------
                            sep $30
                        lda #UDCmd_NetRcvd
                        jsr UDIoExec
                        rep $30
                        brl :none
:no2long
                        ldx #eth_inp
                        ldy #^eth_inp
                        jsr UDNetRecv       ; todo: check error

                        DO  DEBUG_OUT
                        jsr Button0Dn       ; debug out  --------------
                        bcc :noprint
                        jsr PrintReceived
                        lda UDPacketLen     ; 
                        ldx #eth_inp
                        ldy #^eth_inp
                        jsr HexDumpBuffer   ; -------------------------
:noprint
                        FIN
                        lda UDPacketLen
                        sta eth_inp_len


* Back to Uther code
                        lda	eth_inp+12	; type should be 08xx
	                    and	#$ff
	                    cmp	#8
	                    bne	:nogo		; not an ip packet so discard it

                        lda	eth_inp+13
                        and	#$ff
                        bne	:seearp
                        brl	:ip

:seearp                 
	                    cmp	#eth_proto_arp	; arp = 06
	                    beq	:arppkt

:nogo                   brl :none

:arppkt             
                        lda eth_inp+ap_op           ; should be 0
                        and #$ff
                        bne :badpacket
                        lda eth_inp+ap_op+1         ; check opcode
                        and #$ff
                        cmp #1                      ; request?
                        beq :request
                        cmp #2                      ; reply?
                        bne :badpacket
                        brl :reply

:badpacket               
                        brl :none

:request
                    	ldx	#2
:chkadr                 lda	eth_inp+ap_tp,x	; check if they're asking for
	                    cmp	UDConfiguration+2,x	; my address
                        bne	:done
                        dex
                        dex
                        bpl	:chkadr	
	                    jsr	ac_add_source	; add them to arp cache

	                    ldx	#4		; send reply
:bldreply               lda eth_inp+ap_shw,x
                        sta	eth_outp,x	; set sender packet dest
                        sta	eth_outp+ap_thw,x	; and as target
                        lda	UDConfiguration+14,x	; me as source
                        sta	eth_outp+ap_shw,x
                        dex
                        dex
                        bpl	:bldreply
                        
	                    ldx	#4
:setmac	                lda	UDConfiguration+14,x
                        sta	eth_outp+6,x
                        dex
                        dex
                        bpl	:setmac

                        jsr	makearppacket	; add arp, eth, ip, hwlen, protolen

                        lda	#$0200		; set opcode (reply = 0002)
                        sta	eth_outp+ap_op

	                    ldx	#2
:setadr                 lda eth_inp+ap_sp,x	; sender as target addr
                        sta	eth_outp+ap_tp,x
                        lda	UDConfiguration+2,x	; my ip as source addr
                        sta	eth_outp+ap_sp,x
                        dex
                        dex
                        bpl	:setadr

                        lda	#ap_packlen	; set packet length
                        sta	eth_outp_len

                        ldx #eth_outp
                        ldy #^eth_outp
                        lda eth_outp_len
	                    * jsr	eth_tx	; send packet
                        jsr UDNetSend
:done 
	                    brl	:none

:reply                  DO DEBUG_OUT
                        jsr PrintArpReply
                        jsr DumpCurrentRecvBuf
                        FIN

                        lda arp_state
                        cmp #arp_wait               ; are we waiting for a reply?
                        beq :skipper
                        brl :badpacket
                        ;bne :badpacket
:skipper
                        jsr ac_add_source           ; add to cache

                        lda #arp_idle
                        sta arp_state

                        brl :none

:ip                                                 ; we have an ip datagram!

                        pha
                        pha
                        pea 0
                        sec
                        lda eth_inp_len             ; how much space
                        sbc #eth_data               ; don't need the ethernet header
                        sta len
                        pha
                        lda UserID
                        pha
                        pea $0018                   ; mem atributes
                        pea 0
                        pea 0
                        _NewHandle
                        ply
                        plx

                        sty tmppkthandle
                        stx tmppkthandle+2

                        * PushLong ip_inp            ;< This doesn't work and you can't put a # in front of it!! merlin32 bug?
                        pea #^ip_inp
                        pea #ip_inp

                        phx
                        phy
                        pea 0
                        lda len
                        pha
                        _PtrToHand

                        lda	tmppkthandle
                        sta	parmstackb,s
                        lda	tmppkthandle+2
                        sta	parmstackb+2,s
                        lda	#terrok
                        plb
                        clc
                        rtl

:none                  	lda	#0
                        sta	parmstackb,s
                        sta	parmstackb+2,s
                        plb
                        clc
                        rtl                               


DBBACK dw 0
* Sends an IP datagram to the network via the module’s datagram encapsulation.
UDLinkSendPacket        
                        phb			; push data bank register
                        phb
                        pla                         
                        sta DBBACK

                        phk			; push program bank register
                        plb			; pull databank register
                        ; sty	UserID	; save marinetti userid    ; -------------- maybe not needed
                        

                        lda tick_count_start        ; only do it once
                        ora tick_count_start+2
                        bne nocount

                        pha                         ; initialise timer count
                        pha
                        _TickCount
                        pla
                        sta tick_count_start
                        plx
                        stx tick_count_start+2
         
nocount                 lda parmstack+2,s             ; weird shift because i moved the bank code before this so stack is off by 1
                        sta loopin+1
                        lda parmstack+3,s
                        sta loopin+2
                        lda parmstack,s             ; length
                        sta pklen+1
                        clc
                        adc #eth_data
                        sta eth_outp_len

                        lda #ip_outp
                        sta loopout+1
                        lda #>ip_outp
                        sta loopout+2
                        ldx #0
loopin                  ldal $0000,x                ; address set above
loopout                 stal $0000,x                ; address set above
                        inx
                        inx
pklen                   cpx #0                      ; address set above
                        bcc loopin


                        lda ip_outp+ip_dest         ; get mac addr from ip
                        sta arp_ip
                        ldx ip_outp+ip_dest+2
                        stx arp_ip+2

                        cmp #$ffff                  ; check for broadcast addresses
                        bne chk_bc2
                        cpx #$ffff
                        beq bcast
chk_bc2                 cmp gw_test
                        bne chk_mc
                        cpx gw_test+2
                        bne chk_mc

bcast                   lda #$ffff                  ; set destination MAC for broadcast
                        sta arp_mac
                        sta arp_mac+2
                        sta arp_mac+4
                        brl arp_ok

chk_mc                  and #$F0                    ; check for multicast addresses
                        cmp #$E0
                        bne use_arp

                        lda #$0001                  ; set destination MAC for multicast
                        sta arp_mac
                        lda ip_outp+ip_dest
                        and #$7F00
                        ora #$005E
                        sta arp_mac+2
                        stx arp_mac+4
                        brl arp_ok

use_arp                 sep $30
    	
* arp_lookup routine

                        ldx gw_last                 ; check if address is on our subnet
nextadr                 lda arp_ip,x
                        ora gw_mask,x
                        cmp gw_test,x
                        bne notlocal
                        dex
                        bpl nextadr
                        bmi local

notlocal                
                        ldx #3                      ; copy gateway's ip address
nextgw                  lda ipgw,x
                        sta arp_ip,x
                        dex
                        bpl nextgw

local                                           ; findip routine

                        lda #<arp_cache
                        ldx #>arp_cache
                        sta ap
                        stx ap+1

                        ldx #ac_size
compare                                         ; compare cache entry
                        ldy #ac_ip
                        lda (ap),y
                        beq cachemiss
cmpnext                 
                        lda (ap),y
                        cmp arp,y
                        bne nextent
                        iny
                        cpy #ac_ip+4
                        bne cmpnext
                        bra copy_mac

nextent                                         ; next entry
                        lda ap
                        clc
                        adc #10
                        sta ap
                        bcc noinc
                        inc ap+1
noinc                   dex
                        bne compare
                        bra cachemiss

copy_mac                

                        ldy #ac_ip-1                ; copy mac
nextmac                 
                        lda (ap),y
                        sta arp,y
                        dey
                        bpl nextmac
                        rep $30
                        brl arp_ok

; add source to cache

ac_add_source           

                        lda #eth_inp+ap_shw
                        sta ap

                        ldx #68                     ; make space in the arp cache
:movearp                 
                        lda arp_cache,x
                        sta arp_cache+10,x
                        dex
                        dex
                        bpl :movearp

                        ldy #8
:copyarp                 
                        lda (ap),y                  ; copy source
                        sta arp_cache,y
                        dey
                        dey
                        bpl :copyarp
                        rts


cachemiss               

                        rep $30

                        lda arp_state               ; are we already waiting for a reply?
                        cmp #arp_idle
                        beq sendrequest             ; yes, send request

                        lda arptimeout              ; check if we've timed out
                        pha
                        jsr timer_read              ; read current timer value
                        sta time
                        pla
                        sec                         ; subtract current value
                        sbc time
                        bcs notimeout               ; no, don't send

sendrequest                                     ; send out arp request

                        jsr maketheheader

                        ldx #4
setmac1                 lda UDConfiguration+14,x
                        sta eth_outp+6,x
                        dex
                        dex
                        bpl setmac1

                        jsr makearppacket           ; add arp, eth, ip, hwlen, protolen

                        lda #$0100                  ; set opcode (request = 0001)
                        sta eth_outp+ap_op

                        ldx #4
setmac2                 lda UDConfiguration+14,x      ; set source mac addr
                        sta eth_outp+ap_shw,x
                        lda #0                      ; set target mac addr
                        sta eth_outp+ap_thw,x
                        dex
                        dex
                        bpl setmac2

                        ldx #2
setip                   lda UDConfiguration+2,x       ; set source ip addr
                        sta eth_outp+ap_sp,x
                        lda arp_ip,x                ; set target ip addr
                        sta eth_outp+ap_tp,x
                        dex
                        dex
                        bpl setip

                        lda #ap_packlen             ; set packet length
                        sta eth_outp_len


                        lda eth_outp_len
                        ldx #eth_outp
                        ldy #^eth_outp
                        jsr UDPadEth

                        DO DEBUG_OUT
                        jsr PrintSendArp
                        lda eth_outp_len
                        ldx #eth_outp               ; a is already set to len
                        ldy #^eth_outp
                        jsr HexDumpBuffer
                        FIN

                        lda eth_outp_len
                        ldx #eth_outp               ; a is already set to len
                        ldy #^eth_outp
                        jsr UDNetSend
                        ; jsr eth_tx                  ; send packet


                        lda #arp_wait               ; waiting for reply
                        sta arp_state

                        jsr timer_read              ; read current timer value
                        clc
                        adc #0060                   ; set timeout to now+1000 ms
                        sta arptimeout

notimeout
                        lda #terrlinkerror
                        and terrmask
                        tay
                        sec
                        bra cleanup                 ; packet buffer nuked, fail

arp_ok
                                                    ; ACTUALLY SEND!
                        ldx #4
setmac_s                lda arp_mac,x               ; copy destination mac address
                        sta eth_outp+eth_dest,x
                        lda UDConfiguration+14,x    ; copy my mac address
                        sta eth_outp+eth_src,x
                        dex
                        dex
                        bpl setmac_s

                        lda #$0008                  ; set type to ip
                        sta eth_outp+eth_type

                        lda eth_outp_len
                        ldx #eth_outp
                        ldy #^eth_outp
                        jsr UDPadEth

                        DO DEBUG_OUT
                        jsr PrintSend
                        lda eth_outp_len
                        ldx #eth_outp
                        ldy #^eth_outp
                        jsr HexDumpBuffer
                        FIN

                        lda eth_outp_len
                        ldx #eth_outp
                        ldy #^eth_outp
                        jsr UDNetSend
                        ;jsr eth_tx                  ; send packet and return status
                        bcc send_ok
                        ldy #terrlinkerror
                        brk $A6
                        bra cleanup
send_ok                 
                        ldy #terrok
cleanup                 
                        lda DBBACK
                        pha
                        plb
                        plb ; more munging of that bank reg
                        pla
                        sta 5,s
                        pla
                        sta 5,s
                        pla
                        tya
                        rtl

     


** UDLinkConfigure
**  Presents a window allowing the user to edit configuration parameters required by 
**  the link layer module. This call is currently only made by the Control Panel, but 
**  may be made by other applications which may control Marinetti’s setup.
*
* Marinetti 3.0 Programmers’ Guide Page 150-151
* When called, the desktop will be displayed, and the following tool sets will guarantee 
* to have been started. Other tool sets may have also been started, but the module should 
* check before using them and start them if necessary, and shut them down again on exit.
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
                        beq :copy_default_config
                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2                ; now cfgptr points to actual config area
                        lda [cfgptr]                ; test first word should match the config version
                        cmp #cfgvers                ;check version
                        beq :cfg_ok

:copy_default_config                                ; CREATE new config
                        PushLong #cfglen
                        PushLong cfghandle
                        _SetHandleSize              ; set empty handle to size of our data

                        PushLong #UDDefaultCfg
                        PushLong cfghandle
                        PushLong #cfglen
                        _PtrToHand                  ; copy our default data over

:cfg_ok

                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2


                        ldy #22                     ; dhcp flag
                        lda [cfgptr],y
                        sta dhcp_val

                        pha
                        pha
                        _GetPort

                        ldx #15
:clear_loop                                          ; flush the buffer
                        stz work_buffer,x
                        dex
                        dex
                        bpl :clear_loop


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
                        PullLong UDCfgWindow

                        PushLong UDCfgWindow          ; make current grafPort
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
                        PushLong UDCfgWindow
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
                        PushLong UDCfgWindow
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
                        PushLong UDCfgWindow
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
                        PushLong UDCfgWindow
                        PushLong mtu_id
                        PushLong #PSTR_00000007
                        _SetLETextByID

                        PushLong cfghandle
                        _HUnlock


modalloop                                           ;**********************************************************************
                                                    ; interface with taskmaster

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
:modal_chk_cancel       cmp cancel_id               ; cancel button
                        bne :modal_chk_save
                        brl config_exit
:modal_chk_save         cmp save_id
                        beq :save_pressed
                        bra modalloop

:save_pressed
                        PushLong cfghandle
                        _HLock
                        lda [cfghandle]             ; use the handle to get the address of the config area
                        sta cfgptr
                        ldy #2
                        lda [cfghandle],y
                        sta cfgptr+2

                                                    ; now get back and store the returned values
                        PushLong UDCfgWindow
                        PushLong mtu_id
                        PushLong #work_buffer
                        _GetLETextByID

                        pha
                        PushLong #work_buffer+1
                        pea 4
                        pea 0
                        _Dec2Int
                        pla
                        cmp #576
                        bcc :mtu_bad
                        cmp #1601
                        bcc :mtu_ok
:mtu_bad
                        ldx #configAlertMtuStr
                        ldy #^configAlertMtuStr
                        brl show_alert
:mtu_ok
                        ldy #28
                        sta UDConfiguration+28
                        sta MarinettiVariables+lvmtu
                        sta [cfgptr],y

                                                    ; slot code was here

                        pha
                        pha
                        pha
                        PushLong UDCfgWindow
                        PushLong #$b                ; dhcp checkbox
                        _GetCtlHandleFromID
                        _GetCtlValue
                        pla
                        ldy #22                     ; dhcp flag
                        sta [cfgptr],y
                        cmp #0
                        beq :non_dhcp
                        brl :dhcp_ok


:non_dhcp
                        PushLong UDCfgWindow
                        PushLong #$4                ; ip address control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne :ip_ok
                        ldx #configAlertIPStr
                        ldy #^configAlertIPStr
                        brl show_alert
:ip_ok
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

                        PushLong UDCfgWindow
                        PushLong #$6                ; netmask control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne :netmask_ok
                        ldx #configAlertNmStr
                        ldy #^configAlertNmStr
                        brl show_alert
:netmask_ok
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

                        PushLong UDCfgWindow
                        PushLong #$8                ; gateway control id
                        PushLong #work_buffer
                        _GetLETextByID
                        pha
                        PushLong #work_buffer
                        _TCPIPValidateIPString
                        pla
                        bne :gateway_ok
                        ldx #configAlertGwStr
                        ldy #^configAlertGwStr
                        brl show_alert
:gateway_ok
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

:dhcp_ok

config_exit
                        PushLong UDCfgWindow
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
                        pea $0051
                        pea 0
                        pea 0
                        *   PushLong                #configAlertIPStr
alert_strp              pea 0
alert_strp2             pea 0
                        _AlertWindow                ; warn that an invalid string was entered
                        pla
                        brl modalloop




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
:CONFIGFNAME            STR 'UDRIVE.config'



UDLinkConnect           mx %00
                        phb                         ; push data bank register
                        phk                         ; push program bank register
                        plb                         ; pull databank register
                        sty UserID                  ; marinetti memory request id

                        lda #terruseraborted        ; default response
                        sta err_return

                        stz MarinettiVariables+lverrors ; start with a clean slate
                        stz MarinettiVariables+lvipaddress ;
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
                        jsr showpstring
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
                        beq :newconfig
; we need to copy in the previous saved config or set one up for the first time
; use the config area to see what marinetti has for us to use
;
; cfgptr configuration is our working copy of the config
;
                        lda [cfgptr]                ; test first word should match the config version
                        cmp #cfgvers
                        beq :docfg                   ; on to the target address

; we havn't set one yet so use the defaults and report we can't start
:newconfig

                        PushLong #UDDefaultCfg
                        PushLong #UDConfiguration
                        PushLong #cfglen
                        _TCPIPPtrToPtr              ; copy data routine

                        brl :err

:docfg
                        pei cfgptr+2                ; source address for the copy - low
                        pei cfgptr                  ;                             - high
                        PushLong #UDConfiguration
                        PushLong #cfglen
                        _TCPIPPtrToPtr              ; copy data routine

                        lda UDConfiguration+28      ; 1460 byte mtu default
                        sta MarinettiVariables+lvmtu

                        jsr UDDetectSlot            ; SLOT FIXUP!  This detects on each connect
                        jsr UDGetSlot               ; Not sure if this is the best design, but should always work
                        sta UDConfiguration+20


; so now that we have a copy of our configuration data lets start to get the card going
* I believe this is prep for dhcp negotiation (DB)
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


                        DO DEBUG_OUT
                        jsr PrintNetStatus
                        FIN
                        jsr UDConnect             ; THIS starts the w5500 & ethernet link & gets MAC


                        ldx #0
:copy_mac               lda UDMacAddr,x
                        sta UDConfiguration+14,x
                        inx
                        inx
                        cpx #6
                        bne :copy_mac

                        lda UDConfiguration+22      ; do we try dhcp to request an ip address
                        bra :no_dhcp                 ; @todo
                        beq :no_dhcp
                        
                        ; jsr request_dhcp            ; go and try to get one 
                        bcs :no_dhcp                 ; do not save it if we did not get one

                        ldy #2                      ; copy our ip address, mask, gateway to parms
:copy_tmp
                        lda tmp_ip-2,y
                        sta UDConfiguration,y       ; keep it locally
                        iny
                        iny
                        cpy #14
                        bcc :copy_tmp

                        lda tmp_dns                 ; check if primary empty
                        ora tmp_dns+2
                        beq :mtu_offered

                        PushLong #tmp_dns           ; copy the new dns back to marinetti
                        _TCPIPSetDNS

:mtu_offered

                        lda tmp_mtu                 ; did the server tell us its mtu size
                        beq :no_dhcp
                        cmp #1500
                        bcs :no_dhcp
                        sta MarinettiVariables+lvmtu

:no_dhcp
                        lda #udnetversl               ; copy our version marker as it may have changed
                        sta UDConfiguration+24
                        lda #udnetversh
                        sta UDConfiguration+26

                        PushLong #0                   ; now we must create a handle to pass back the updated data
                        PushLong #cfglen
                        PushWord UserID
                        pea $18 ; attributes
                        PushLong #0
                        _NewHandle
                        PullLong temphandle

                        PushLong #UDConfiguration   ; copy the data to the handle
                        PushLong temphandle
                        PushLong #cfglen
                        _PtrToHand

                        PushWord #conUltimateDrive  ; now tell marinetti the new data if we change
                        PushLong temphandle
                        _TCPIPSetConnectData

                        lda UDConfiguration+2       ; cfgip offset = 2
                        sta MarinettiVariables+lvipaddress
                        lda UDConfiguration+2+2     ; cfgip offset = 2
                        sta MarinettiVariables+lvipaddress+2

                        lda UDConfiguration+6       ; cfgipmask offset = 6
                        sta ipmask                  ; zero page var
                        lda UDConfiguration+6+2     ; cfgipmask offset = 6
                        sta ipmask+2

                        lda UDConfiguration+10      ; cfgipgw offset = 10
                        sta ipgw                    ; zero page var
                        lda UDConfiguration+10+2    ; cfgipgw offset = 10
                        sta ipgw+2

                        lda #setmacstr              ; display our connect data
                        jsr showpstring



                        lda	#arp_idle	            ; start out idle
                        sta	arp_state

                        lda #true
                        sta MarinettiVariables+lvconnected
                        DO DEBUG_OUT
                        jsr PrintNetStatus
                        FIN

                        lda #terrok
                        sta err_return

:err                     rep $30

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


setmacstr               str 'MAC address initialized '
linkstrs                str 'Starting UltimateDrive Network Driver'

err_return              ds  2
temphandle              ds  4


** Various helper functions

* adds first six bytes of ethernet header
maketheheader

                        ldx #4
                        lda #$ffff
setbrd                  sta eth_outp,x
                        dex
                        dex
                        bpl setbrd

                        rts

* adds proto = arp, hw = eth, and proto = ip to outgoing packet
makearppacket

                        lda #$0608                  ; eth_proto_arp = hi 08 - lo
                        sta eth_outp+eth_type

                        lda #$0100                  ; set hw type (eth = 0001)
                        sta eth_outp+ap_hw

                        lda #$0008                  ; set protcol (ip = 0800)
                        sta eth_outp+ap_proto

                        lda #$0406                  ;  set proto addr len (eth = 04) = hi set hw addr len (eth = 06) = lo
                        sta eth_outp+ap_hwlen

                        rts

* ??
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



* timer routines (original comments)
*
* the  should be a 16-bit counter that's incremented by about
* 1000 units per second. it doesn't have to be particularly accurate,
* if you're working with e.g. a 60 hz vblank irq, adding 17 to the
* counter every frame would be just fine.
* code modified to work with 1/60 of a second

* return the current value
timer_read	            
                        pha
                        pha
                        _TickCount
                        PullLong tick_count_cur     ; how many ticks have tocked since the last tick did tock
                        sub4d tick_count_cur;tick_count_start;tick_temp
                        lda tick_temp

                        cmp #60 
                        bcc :ret
                        add4 tick_count_start;60    ; more than 60 (1 second)
                        sub4 tick_temp;60
                        lda tick_temp
:ret                    rts


* 16 bit - src/dest,add value
add4                    mac
                        clc
                        lda ]1
                        adc ]2
                        sta ]1
                        lda ]1+2
                        adc ]2+2
                        sta ]1+2
                        eom

* 16 bit - src/dest,sub value
sub4                    mac
                        sec
                        lda ]1
                        sbc ]2
                        sta ]1
                        lda ]1+2
                        sbc ]2+2
                        sta ]1+2
                        eom

* 16 bit - srca,srcb,dest
sub4d                   mac
                        sec
                        lda ]1
                        sbc ]2
                        sta ]3
                        lda ]1+2
                        sbc ]2+2
                        sta ]3+2
                        eom

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
                        pla                         ; read mins and secs
                        sta tick_temp
                        pla                         ; read hour and year
                        sta tick_temp+2
                        plx                         ; throw dates
                        plx                         ; throw dates
                        and #$ff                    ; hours
                        asl a
                        asl a
                        sta tick_temp+4
                        asl a
                        asl a
                        asl a
                        asl a
                        sec
                        sbc tick_temp+4
                        sta timer                   ; we have minutes
                        lda tick_temp+1             ; mins
                        and #$ff
                        asl a
                        asl a
                        sta tick_temp+4
                        asl a
                        asl a
                        asl a
                        asl a
                        sec
                        sbc tick_temp+4
                        clc
                        adc timer
                        sta timer                   ; we have seconds
                        lda timer+2
                        adc #$00
                        sta timer+2
                        lda tick_temp
                        and #$ff
                        clc
                        adc timer
                        sta timer                   ; total current seconds since midnight
                        lda timer+2
                        adc #$00
                        sta timer+2

tr_loop                 
                        sec
                        lda timer
                        sbc start_time
                        tax
                        lda timer+2
                        sbc start_time+2
                        bpl tr_exit
                        clc
                        lda timer
                        adc #<86400                 ; seconds in a day
                        sta timer
                        lda timer+2
                        adc #>86400
                        sta timer+2
                        bra tr_loop
tr_exit                 
                        txa
                        rts

tick_count_cur          ds  4                       ; .res 2
tick_count_start        ds  4
tick_temp               ds  6
time                    ds  2                       ; .res 2
timer                   ds  4
start_time              ds  4



* we return this module information from LinkLayerModuleInfo call on startup
ll_modinfo
                        dw  conUltimateDrive
ll_name                 str 'UltimateDrive'
                        ds  21-{*-ll_name}          ; pad using subexpression for merlin32
ll_vers                 dw  #udnetversl,#udnetversh
ll_flags                dw  0
ll_modinfolen           =   *-ll_modinfo

* set version to v2.0.5d1
* set version to v0.1.0a1
udnetversh              equ $0010                   ;mmmm_mmmm_mmmm_bbbb
udnetversl              equ $4001                   ;sss0_0000_rrrr_rrrr ss-20=d,40=a,60=b,80=f,a0=r

* current actual config area
UDConfiguration         ds  cfglen                  ; 30 total - this is our actual buffer

* config defaults data
UDDefaultCfg
cfgvers                 =   1
                                                    ; connect data
cfg_version             dw  cfgvers                 ; +0 version
cfg_ip                  db  192,168,1,123           ; +2 ip
cfg_netmask             db  255,255,255,0           ; +6 netmask
cfg_gateway             db  192,168,1,254           ; +10 gateway
cfg_mac                 hex BA,DB,AD,BA,DB,AD       ; +14 mac goes here
cfg_slot                dw  4                       ; +20 slot
cfg_dhcp                dw  0                       ; offset 22
cfg_vers                dw  ^ll_vers                ; offset 24
                        dw  ll_vers                 ; offset 26
cfg_mtu                 dw  1460                    ; offset 28
                        ds  64-{*-UDDefaultCfg}     ; pad to 64 to be less brittle on version changes
cfglen                  =   64


work_buffer             ds  17
response_buffer         ds  4

configAlertIPStr        asc '63~Invalid value entered for IP Address.',0D0D
                        asc '~^#4',00
configAlertGwStr        asc '63~Invalid value entered for Gateway.',0D0D
                        asc '~^#4',00
configAlertNmStr        asc '63~Invalid value entered for Netmask.',0D0D
                        asc '~^#4',00
configAlertMtuStr       asc '63~Invalid value entered for MTU.',0D0D
                        asc 'Valid values are 576 - 1600.'
                        asc '~^#4',00


* Not used... yet ;)
testalert               asc '63~UltimateDrive Link Layer',0D0D
                        asc 'Copyright (c) 2024 by UltimateDrive Team',0D,
                        asc '  Dagen Brock & Phil Allison',0D
                        asc '~^#0'
                        dfb 0



UserID                  dw  0                       ; ID from MemoryManager for NewHandle allocations (Marinetti passes us its ID to use)

UDCfgWindow             ds  4

eventrecord             =   *                       ; used by the modal configuration gui code
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

* my direct space on marinetti's direct page $E0-$FF available
tmppkthandle            equ $e0
* cnt			equ $e4
cfghandle               equ $E8
cfgptr                  equ $EC
ap                      equ $F0
* eth_packet	equ $f2
ipmask                  equ $F4
ipgw                    equ $F8
bufsize                 dw  #1518                   ; Size
len                     dw  0                       ; Packet length counter

* input and output buffers
eth_inp_len             ds  2                       ; input packet length
eth_inp                 ds  1518                    ; space for input packet

eth_outp_len            ds  2                       ; output packet length
eth_outp                ds  1518                    ; space for output packet

* ethernet packet offsets
eth_dest                equ 0                       ; destination address
eth_src                 equ 6                       ; source address
eth_type                equ 12                      ; packet type
eth_data                equ 14                      ; packet data

* protocols
eth_proto_ip            equ 0
eth_proto_arp           equ 6


* ip packets start at ethernet packet+14
ip_inp                  equ eth_inp+eth_data
ip_outp                 equ eth_outp+eth_data

* ip packet offsets
ip_ver_ihl              equ 0
ip_tos                  equ 1
ip_len                  equ 2
ip_id                   equ 4
ip_frag                 equ 6
ip_ttl                  equ 8
ip_proto                equ 9
ip_header_cksum         equ 10
ip_src                  equ 12
ip_dest                 equ 16
ip_data                 equ 20

* gateway handling
gw_mask                 ds  4                       ; inverted netmask
gw_test                 ds  4                       ; gateway ip or:d with inverted netmask
gw_last                 ds  1                       ; netmask length - 1

* timeout
arptimeout              ds  2                       ; time when we will have timed out
packettimeout           ds  2                       ; for sending packets

* holding values for packet retrieval
tmp_data
tmp_ip                  ds  4
tmp_netmask             ds  4
tmp_gateway             ds  4
tmp_server              ds  4
tmp_lease               ds  4
tmp_dns                 ds  4
tmp_dns2                ds  4
tmp_src_mac             ds  6
tmp_src_ip              ds  4
tmp_mtu                 ds  2
tmp_length              equ *-tmp_data


* arp state machine
arp_idle                equ 1                       ; idling
arp_wait                equ 2                       ; waiting for reply
arp_state               ds  2                       ; current activity

* arguments for lookup and add
arp                                                 ; ptr to mac/ip pair
arp_mac                 ds  6                       ; result is delivered here
arp_ip                  ds  4                       ; set ip before calling lookup

* arp cache
ac_size                 equ 8                       ; lookup cache
ac_ip                   equ 6                       ; offset for ip
ac_mac                  equ 0                       ; offset for mac
arp_cache               ds  6+4*ac_size             ; .res (6+4)*ac_size

* offsets for arp packet generation
ap_hw                   equ 14                      ; hw type (eth = 0001)
ap_proto                equ 16                      ; protocol (ip = 0800)
ap_hwlen                equ 18                      ; hw addr len (eth = 06)
ap_protolen             equ 19                      ; proto addr len (ip = 04)
ap_op                   equ 20                      ; request = 0001, reply = 0002
ap_shw                  equ 22                      ; sender hw addr
ap_sp                   equ 28                      ; sender proto addr
ap_thw                  equ 32                      ; target hw addr
ap_tp                   equ 38                      ; target protoaddr
ap_packlen              equ 42                      ; total length of packet

* offsets for udp packet generation
udp_source              equ 0                       ; source port
udp_dest                equ 2                       ; destination port
udp_len                 equ 4                       ; length
udp_cksum               equ 6                       ; checksum
udp_data                equ 8                       ; total length udp header



MarinettiVariables      ds  lvlen
* link layer variables as defined by marinetti
lvversion               equ $0000
lvconnected             equ $0002
lvipaddress             equ $0004
lvrefcon                equ $0008
lverrors                equ $000c
lvmtu                   equ $0010
lvlen                   equ $0012

true                    equ $8000
false                   equ $0000

* misc equates
terrok                  equ $0000
terrlinkerror           equ $0004+$3600
terrnoreconsupprt       equ $0014+$3600             ;this module doesn't support reconnect
terruseraborted         equ $0015+$3600
terrmask                equ $00ff

parmstack               equ 4
parmstackb              equ 1+parmstack

myllintvers             equ 2


                        put marinetti_equates
                        put udnetrz
                        put udlib
                        put dagbug
                        use Text.Macs                ;standard merlin32 (and merlin16) macros


                        use Mem.Macs                ;standard merlin32 (and merlin16) macros
                        use Util.Macs               ;standard merlin32 (and merlin16) macros
                        use Window.Macs             ;standard merlin32 (and merlin16) macros
                        use Qd.Macs                 ;standard merlin32 (and merlin16) macros
                        use Ctl.Macs                ;standard merlin32 (and merlin16) macros
                        use Int.Macs                ;standard merlin32 (and merlin16) macros
                        use Misc.Macs               ;standard merlin32 (and merlin16) macros
                        use Event.Macs              ;standard merlin32 (and merlin16) macros
                        use Macros                  ;standard merlin32 (and merlin16) macros

]tcpiptoolnum           equ $36
                        use TCPIP.MACS.S            ;from Marinetti sources




