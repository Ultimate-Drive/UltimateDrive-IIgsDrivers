**************************************************
** UltimateDrive Calling Library for 65816 CPUs **
****                                          ****
**      Intended for Apple IIgs Computers       **
**          by Dagen Brock (c) 2024             **
**************************************************

UDRomSig                asc 'UltimateDrive'         ; switch to '' if high/low bit
UDRomSigLen             =   *-UDRomSig
UDRomSigOffset          =   $EC
UDSlotNum               dw  0                       ; slot num * 16   e.g. slot 6 = #$0060  is word for 16-bit compat 
UDMacAddr               ds  6                       ; 00:00:00:00:00:00
Ptr1                    =   $E0                     ; 3-byte long address pointer <- USES DP ADDRESS!
                                                    ; $E0 is also part of marinetti scratch dp available 


** Trying to keep this similar to the Menu.asm version
UDDetectSlot            mx  %00
                        phb
                        phk
                        plb
                        sep $30                     ; 8-bit
                        lda #$00                    ; bank
                        sta Ptr1+2
                        lda #$C7                    ; page
                        sta Ptr1+1
                        lda #$00
                        sta Ptr1                    ; now Ptr1 == $00C700

:l1                     ldx #UDRomSigLen-1
                        ldy #UDRomSigOffset+UDRomSigLen-1

:l2                     ldal [Ptr1],y
                        cmp UDRomSig,x
                        bne :l3

                        dey
                        dex
                        bpl :l2
                        lda Ptr1+1
                        asl
                        asl
                        asl
                        asl
                        sta UDSlotNum
                        clc                         ; found
                        rep $30
                        plb
                        rts

:l3                     mx  %11
                        dec Ptr1+1
                        lda Ptr1+1
                        cmp #$C0
                        bne :l1

                        sec                         ; not found
                        rep $30
                        plb
                        rts

UDIoExec                mx  %11
                        ldx UDSlotNum
                        stal UD_IO_Cmd,x
MENU_IO_Exec            mx  %11
                        ldal UD_IO_Exec,x
:wait                   ldal UD_IO_Status,x
                        bmi :wait
                        lsr                         ; CS if error, A = ERROR CODE ?
                        rts


* helper function - returns actual slot number 0-7
* must call UDDetectSlot first! 
UDGetSlot               mx  %00
                        lda UDSlotNum
                        lsr
                        lsr
                        lsr
                        lsr
                        and #$000F
                        rts

* Connect network adapter and read the MAC address supplied by the firmware
UDConnect               mx %00
                        sep $30
                        lda #UDCmd_NetOpen
                        jsr UDIoExec
                        bcc :ok                   ; error
                        brk $C0 ; C0nnect error
:ok                        rep $30

                        ldy #UDMacAddr
                        lda #6
                        jsr UdIoRDataToBuff
:exit                   rep $30
                        rts


* Disconnect network adapter and ... ??
UDDisconnect            mx %00
                        sep $30
                        lda #UDCmd_NetClose
                        jsr UDIoExec
                        bcs :exit                   ; error 
                        ; blah
:exit                   rep $30
                        rts

* return net status bytes (config&version)
UDNetStatus             mx  %00
                        stz UDNetStatusBytes
                        sep $30
                        ldx UDSlotNum
                        lda #UDCmd_NetStatus
                        jsr UDIoExec
                        ldal UD_IO_RData,x
                        sta UDNetStatusBytes
                        ldal UD_IO_RData,x
                        sta UDNetStatusBytes+1
                        rep $30
                        lda UDNetStatusBytes
                        rts

UDNetStatusBytes        dw #$0000   ;WIZCHIP_READ(PHYCFGR), WIZCHIP_READ(VERSIONR)

* return pending packet length or 0
UDNetPeek               mx %00 
                        stz UDPacketLen
                        sep $30
                        ldx UDSlotNum
            			lda #UDCmd_NetPeek
    		            jsr UDIoExec
    		            ldal UD_IO_RData,x 
			            sta	UDPacketLen
			            ldal UD_IO_RData,x 
                        sta UDPacketLen+1
                        rep $30
                        lda UDPacketLen
                        rts

UDPacketLen             dw #$0000

    
* x/y = addr; a is len
UDPadEth                mx  %00
                        cmp #64
                        bcc :needs_pad
                        rts
:needs_pad              pei Ptr1
                        pei Ptr1+2
                        stx Ptr1
                        sty Ptr1+2

                        tay
                        sep $20
                        lda #0
:pad                    stal [Ptr1],y
                        iny
                        cpy #64
                        bne :pad
                        rep $30
                        pla
                        sta Ptr1+2
                        pla
                        sta Ptr1
                        lda #64
                        sta UDPacketLen
                        sta eth_outp_len
                        rts

* x/y = addr, a = len
UDNetSend               mx %00
                        stx Ptr1
                        sty Ptr1+2
                        sta :_udsendlen+1


                        sep $20
                        ldx UDSlotNum
                        lda #UDCmd_NetSend
                        stal UD_IO_Cmd,x
                        lda :_udsendlen+1
                        stal UD_IO_WData,x
                        lda :_udsendlen+2
:go_on                  stal UD_IO_WData,x
                        
                        ldy #0
:copy_to_ud             ldal [Ptr1],y
                        stal UD_IO_WData,x
                        iny
:_udsendlen             cpy #0000                   ; SMC
                        bne :copy_to_ud
                        sep $30
                        * lda #UDCmd_NetSend
                        jsr MENU_IO_Exec        ; exec only
                        bcc :okay
                        brk $A5   ; A5= ASSERT 
:okay                   rep $30
                        rts

* x/y = addr , UDPacketLen should be set from previous call to UDNetPeek
UDNetRecv               mx %00
                        stx Ptr1
                        sty Ptr1+2

                        * ldal [Ptr1]     ; deref handle
                        * pha
                        * ldy #2
                        * ldal [Ptr1],y
                        * sta Ptr1+2
                        * pla
                        * sta Ptr1
  
                        sep $30
                        lda #UDCmd_NetRcvd
                        jsr UDIoExec

                        ldy #0
                        sep $20
                        ldx UDSlotNum
:copy_from_ud           ldal UD_IO_RData,x
                        stal   [Ptr1],y
                        iny
:_udsendlen             cpy UDPacketLen
                        bne :copy_from_ud
                        
                        rep $30
                        rts



                        mx %00
**  a=len   y=buff addr (local bank only)
UdIoRDataToBuff         sty :wbuf+1
noerr                   sep $30
                        sta :limit+1
                        ldx UDSlotNum
                        ldy #0
:read                   ldal UD_IO_RData,x
:wbuf                   sta $FFFF,y
                        iny
:limit                  cpy #1
                        bcc :read
                        rep $30
                        rts


UDCmd_GetCfg            =   $20
UDCmd_SetCfg            =   $21
UDCmd_MoAll             =   $2B
UDCmd_EasterEgg         =   $2E
UDCmd_ApplyCfg          =   $2F
UDCmd_Menu              =   $60                     ; Download BIN at $2000
UDCmd_SvBnk20           =   $61                     ; Saves Bank $00/20 to temp file on SDCard
UDCmd_RsBnk20           =   $62                     ; Restore Bank $00/20 from temp file on SDCard
UDCmd_SaveBuff          =   $63                     ; Saves Buffer for $00/20 bank if DMA is impossible
UDCmd_NetOpen           =   $70                     ; mainlooper.c
UDCmd_NetClose          =   $71                     ;
UDCmd_NetSend           =   $72                     ;
UDCmd_NetRcvd           =   $73                     ;
UDCmd_NetPeek           =   $74                     ;
UDCmd_NetStatus         =   $75                     ;
UDCmd_NetSDMA           =   $76                     ; send Frame Via DMA
UDCmd_NetRDMA           =   $77                     ; read Frame via DMA


UD_IO_Exec              =   $C080
UD_IO_Status            =   $C081
UD_IO_Cmd               =   $C082
UD_IO_UnitNum           =   $C083                   ; Write
UD_IO_MemPtrL           =   $C084                   ;
UD_IO_MemPtrH           =   $C085                   ;
UD_IO_BlockNum          =   $C086                   ; Write 4 bytes, BE
UD_IO_RData             =   $C087                   ; Read
UD_IO_WData             =   $C088                   ; Write
UD_IO_DoDMA             =   $C089                   ; Write
UD_IO_Mode              =   $C08D                   ; Read NZ = DMA, Write b7