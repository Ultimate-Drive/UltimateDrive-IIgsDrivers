* DAGBUGIT!@



HexTable asc '0123456789ABCDEF'

* xy=adr =len
HexDumpBuffer           mx %00
                        ; hexify whatever
                        jsr HexifyToBuffer
                        lda HexifyOutLen
                        cmp #200
                        bcc :under
                        lda #200
                        sta HexifyOutLen
:under                  jsr PrintDebugBuffer
                        PushLong #PostText
                        _WriteCString

                        rts

PrintDebugBuffer        PushLong #DebugText
                        PushWord #0 ; offset
                        PushWord HexifyOutLen
                        _TextWriteBlock
                        rts
SendText                asc $0a,$0d,'Sending:',$0A,$0D,$00
SendArpText             asc $0a,$0d,'Sending ARP request:',$0A,$0D,$00
PostText                asc ' ... ',$0A,$0D,$0A,$0D,$00
PrintSend               PushWord #$FF
                        PushWord #$00
                        _SetOutGlobals
                        PushLong #SendText
                        _WriteCString
                        rts

HexifyToBuffer          mx  %00
                        pei 0
                        pei 2
                        stx 0
                        sty 2
                        sta HexifySrcLen
                        stz HexifyOutLen
                        lda #0  ; to force top byte to 0
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

HexifySrcLen dw 0
HexifyOutLen dw 0


DebugText ds #4000