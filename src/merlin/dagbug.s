* DAGBUGIT!@

Button0Dn               mx  %00
                        ldal $00c061
                        xba
                        asl
                        rts

Button1Dn               mx  %00
                        ldal $00c061
                        asl
                        rts

B0Brk                   MAC
                        jsr Button0Dn
                        bcc __b+2
__b                     brk $b1
                        EOM

B1Brk                   MAC
                        jsr Button1Dn
                        bcc __b+2
__b                     brk $b1
                        EOM


BorderColor             MAC
                        DO DEBUG_BORDER
                        sep $30 
                        lda #]1
                        stal $00c034
                        rep $30 
                        FIN
                        EOM

* xy=adr =len
HexDumpBuffer           mx  %00
                                                    ; hexify whatever
                        jsr HexifyToBufferFancy
                        lda HexifyOutLen
                        cmp #240
                        bcc :under
                        lda #240
                        sta HexifyOutLen
                        jsr PrintDebugBuffer
                        PushLong #EllipsisStr
                        _WriteCString
                        rts
:under                  jsr PrintDebugBuffer
                        jsr PrintCR
                        rts

PrintNetStatus          ~WriteCString #NetStatusStr
                        jsr UDNetStatus
                        ldx #UDNetStatusBytes
                        ldy #^UDNetStatusBytes
                        lda #2
                        jsr HexDumpBuffer
                        jsr PrintCR
                        rts

PrintDebugBuffer        PushLong #DebugText
                        PushWord #0                 ; offset
                        PushWord HexifyOutLen
                        _TextWriteBlock
                        rts

HexTable                asc '0123456789ABCDEF'
NetStatusStr            asc "Net Status Bytes: ",00
ReceivedStr             asc 'Received:',$0A,$0D,$00
SendingStr              asc 'Sending:',$0A,$0D,$00
SendingArpStr           asc 'Sending ARP request:',$0A,$0D,$00
ArpReplyStr             asc 'Received:',$0A,$0D,$00
EllipsisStr             asc '  ... ',$0A,$0D,$00
CRStr                   asc $0a,$0d,$00

PrintCR                 ~WriteCString #CRStr
                        rts
PrintReceived           ~WriteCString #ReceivedStr
                        rts
PrintSend               ~WriteCString #SendingStr
                        rts
PrintSendArp            ~WriteCString #SendingArpStr
                        rts
PrintArpReply           ~WriteCString #ArpReplyStr
                        rts



HexifyToBufferFancy     mx  %00
                        pei 0
                        pei 2
                        stx 0
                        sty 2
                        sta HexifySrcLen
                        stz HexifyOutLen
                        stz HBF_col
                        lda #0                      ; to force top byte to 0
                        sep $20
                        ldy #0
                        ldx #0
:hexify                 ldal [0],y
                        pha                         ;+a
                        phx                         ;+x

                        lsr
                        lsr
                        lsr
                        lsr
                        tax                         ; mask?
                        lda HexTable,x
                        plx                         ;-x
                        sta DebugText,x
                        pla                         ;-a
                        inx
                        phx                         ;+x
                        and #$0F
                        tax
                        lda HexTable,x
                        plx                         ;-x
                        sta DebugText,x
                        inx
                        lda #' '
                        sta DebugText,x
                        inx

                        inc HBF_col
                        lda HBF_col
                        cmp #8
                        bne :chk16

                        lda #' '
                        sta DebugText,x
                        inx
                        bra :next
:chk16                  cmp #16
                        bne :next
                        lda #$0D
                        sta DebugText,x
                        inx
                        lda #$0A
                        sta DebugText,x
                        inx
                        stz HBF_col


:next                   iny
                        cpy HexifySrcLen
                        bne :hexify
                        stx HexifyOutLen
                        rep $30
                        pla
                        sta 2
                        pla
                        sta 0
                        rts
HBF_col                 dw  0



HexifyToBuffer          mx  %00
                        pei 0
                        pei 2
                        stx 0
                        sty 2
                        sta HexifySrcLen
                        stz HexifyOutLen
                        lda #0                      ; to force top byte to 0
                        sep $20
                        ldy #0
                        ldx #0
:hexify                 ldal [0],y
                        pha                         ;+a
                        phx                         ;+x

                        lsr
                        lsr
                        lsr
                        lsr
                        tax                         ; mask?
                        lda HexTable,x
                        plx                         ;-x
                        sta DebugText,x
                        pla                         ;-a
                        inx
                        phx                         ;+x
                        and #$0F
                        tax
                        lda HexTable,x
                        plx                         ;-x
                        sta DebugText,x
                        inx
                        lda #' '
                        sta DebugText,x
                        inx
                        iny
                        cpy HexifySrcLen
                        bne :hexify
                        stx HexifyOutLen
                        rep $30
                        pla
                        sta 2
                        pla
                        sta 0
                        rts

HexifySrcLen            dw  0
HexifyOutLen            dw  0

DebugText               ds  #4000