*****************************************************************
*  UltimateDrive GS/OS Device Driver
*  Author: Dagen Brock
*****************************************************************


** Format - per Apple IIgs GS/OS Device Driver Reference (p) 176
** https://apple2.gs/downloads/library/Apple%20IIgs%20GS_OS%20Device%20Driver%20Reference%20-%20APDA%20A0008LL_C.pdf
*
*    Header section
*    Configuration parameter list(s)    \_ Each supported device (or partition) requires a own Config AND DIB!
*    Device Information Block(s) (DIBs) /
*    Driver code segment(s)             - May be repeated per device or shared among multiple devices


                        mx  %00
                        rel
                        typ $bb                     ; All Apple IIcs driver load fìles must have a fìle type of $BB.
                                                    ; They may also be in Express Load format.
                     ;   aux $010C                   ; AUXTYPE is $010C, but we can't set that here (Merlin32 bug?) so we set in Makefile
** GS/OS Device Driver Ref P. 175 - re: auxtype
*              High byte                                           Low byte
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
* | 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
*    |    |_____________________________|    |____|    |________________________|
*    |                |                         |                            |
*    |                |                         +--> 0 = device driver       |
*    |                |                              1 = supervisor driver   |
*    |                +--> S01 = GS/OS driver                                +--> Maximum number of devices (if device driver)
*    |                                                                            Undefined (if supervisor driver)
*    +--> 1 = inactive  0 = active


                        dsk UltimateDrive
                        use 4/Util.Macs
DEBUG_BORDER            =   0                       ; on/off flag for debug borders
DEBUG_TEXT              =   0                       ; on/off flag for debug borders


UDriveHeader            da  DIBs-UDriveHeader       ; offset to 1st DIB, one per device p.176-180
                        dw  MAXDEVICES              ; number of devices
                        dw  $0000                   ; no configuration list


** DIB Format - per Apple IIgs GS/OS Device Driver Reference (p) 179
*
* $00 - LongWord - linkPtr         - Pointer to next DIB
* $04 - LongWord - entryPtr        - Pointer to driver entry point
* $08 - Word     - characteristics - Characteristics of device
* $0A - LongWord - blockCount      - Number of blocks on device
* $0E - PString  - devName         - Name of device (32 byte Pascal string; len byte then ASCII, high bit clear)
* $2E - Word     - slotNum         - Slot number of device installed
* $30 - Word     - unitNum         - Unit number of device installed
* $32 - Word     - version         - Version number of the device driver
* $34 - Word     - deviceID        - General type of device
* $36 - Word     - headLink        - Device number of first linked device
* $38 - Word     - forwardLink     - Device number of next linked device
* $3A - LongWord - extendedDibPtr  - Pointer to additional device information
* $3E - Word     - DIBDevNum       - Initial device number (assigned at startup)
                        ds  \
DIBs
_dib0                   adrl #0                     ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
                                                    ; adrl #65535 ; block count of harddisk image for testing only!
:devname                str 'UDRIVE01'              ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot0                dw  $0000                   ; +2E slot number
                        dw  $0001                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number

** I'm not using this right now... there should be 12 (possibly more if multiple UD cards?)
_dib1                   adrl _dib2                  ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
:devname                str 'UDRIVE02'              ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot1                dw  $0000                   ; +2E slot number
                        dw  $0002                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number


_dib2                   adrl _dib3                  ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
:devname                str 'UDriveDevice-H03'      ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot2                dw  $0000                   ; +2E slot number
                        dw  $0003                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number

_dib3                   ds  4                       ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
:devname                str 'UDriveDevice-H04'      ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot3                dw  $0000                   ; +2E slot number
                        dw  $0004                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number



** Dispatch Routine - per Apple IIgs GS/OS Device Driver Reference (p) 193
* A = Call number
MainEntry               phk                         ; I traced back to GS/OS and they handle preserving B
                        plb
                        asl
                        tax
                        stz errCode
                        jsr (dispatchTable,x)
                        lda errCode
:done_prep_result       cmp #$0001
                        rtl

** For a more detailed explanation of driver calls, see Chapter 10, "GS/OS Driver Call Reference."
dispatchTable           da  Driver_Startup          ; Prepares a device for all other device-related calls - first call
                        da  Driver_Open             ; (NA) Pepares a character device for conducting I/O transactions
                        da  Driver_Read             ; Reads data from a character device or a block device
                        da  Driver_Write            ; Writes data to a character device or a block device
                        da  Driver_Close            ; (NA) Resets the driver to its nonopen state
                        da  Driver_Status           ; Gets information about the status of a specific device
                        da  Driver_Control          ; (NA) Sends control information or requests to a specific device
                        da  Driver_Flush            ; (NA) Writes out any characters in a character driver's buffer
                        da  Driver_Shutdown         ; Prepares a device driver to be purged

** @todo - I think we do need to support some control calls, both AS and Slinky driver do and they are block devices
Driver_Control
** Not implemented for block devices
Driver_Open
Driver_Close
Driver_Flush
                        rts


** NOTE: A driver's DIB is not considered to contain valid information until the
**       successful completion of this call. If a driver returns an error as the result
**       of the startup call, it is not installed in the device list. If the driver returns
**       no error during startup, it then becomes available for an applicaton to
**       access without further initialization.
Driver_Startup          BorderColor #0              ; CALLED 1st!

                        jsr UDDetectSlot
                        jsr UDGetSlot
                        bne :card_found
                        brl Driver_Shutdown         ; no card (detect anyways...)
:card_found
                        ora #$0008                  ; bit 3 = 1 for card slot
                        sta _udSlot0
                                                    ;  sta _udSlot1
                        lda #1                      ; set active
                        sta udActive
                        BorderColor #12             ;green
                        rts

Driver_Shutdown         BorderColor #8              ;brown
                        stz udActive
                        rts


** Copy 'requestCount' bytes starting at 'blockNum' from 'unitNum' of current dib @ 'dibPtr'
Driver_Read             BorderColor #14

                        lda requestCount
                        ora requestCount+2
                        bne :read1
                                                    ; slinky driver says it's okay
:read0                  clc                         ; return with no error (accumulator already 0)
                        rts
                                                    ; av's driver considers it invalid
:not_used               lda #$002C                  ; invalidByteCount
                        sta errCode
                        sec
                        rts

:read1                  PushLong bufferPtr          ; save this because technically we should change any DP other than transferCount
                        jsr SetUDBlock
:read2                  ldy #$30                    ; unitNum
                        lda [dibPtr],y
                        and #$000F
                        jsr UDReadBlock
                        lda transferCount           ; safe multi-block read
                        clc
                        adc #$200                   ; PRODOS BLOCK SIZE
                        sta transferCount
                        lda transferCount+2
                        adc #0
                        sta transferCount+2

                        lda transferCount+2
                        cmp requestCount+2          ; MSB
                        bcc NextUDBlock
                        lda transferCount
                        cmp requestCount
                        bcc NextUDBlock             ; get another block
                                                    ; otherwise we're done here
                        BorderColor #2
                        PullLong bufferPtr
                        rts
NextUDBlock             clc
                        lda UD_CurrentBlock
                        adc #1
                        sta UD_CurrentBlock
                        lda UD_CurrentBlock+2
                        adc #0
                        sta UD_CurrentBlock+2
                        lda bufferPtr
                        clc
                        adc #$200
                        sta bufferPtr
                        lda bufferPtr+2
                        adc #0
                        sta bufferPtr+2
                        jmp :read2

SetUDBlock
                        lda blockNum
                        sta UD_CurrentBlock
                        lda blockNum+2
                        sta UD_CurrentBlock+2
                        rts

Driver_Write            BorderColor #3

                        PushLong bufferPtr

                        lda requestCount
                        ora requestCount+2
                        bne :write1
                                                    ; slinky driver says it's okay *shrug*, AS treats as invalid
:write0                 clc                         ; return with no error (accumulator already 0)
                        rts


:write1                 jsr SetUDBlock
:write2                 ldy #$30                    ; unitNum
                        lda [dibPtr],y
                        and #$000F
                        jsr UDWriteBlock
                        lda transferCount
                        clc
                        adc #$200                   ; PRODOS BLOCK SIZE
                        sta transferCount
                        lda transferCount+2
                        adc #0
                        sta transferCount+2

                        lda transferCount+2
                        cmp requestCount+2          ; MSB
                        bcc NextUDWBlock
                        lda transferCount
                        cmp requestCount
                        bcc NextUDWBlock            ; write another block
                                                    ; otherwise we're done here
                        BorderColor #2
                        PullLong bufferPtr
                        rts

NextUDWBlock            clc
                        lda UD_CurrentBlock
                        adc #1
                        sta UD_CurrentBlock
                        lda UD_CurrentBlock+2
                        adc #0
                        sta UD_CurrentBlock+2
                        lda bufferPtr
                        clc
                        adc #$200
                        sta bufferPtr
                        lda bufferPtr+2
                        adc #0
                        sta bufferPtr+2
                        jmp :write2
                        rts


Driver_Status           BorderColor #5              ;
                        lda statusCode
                        cmp #5                      ; Only calls 0-4 are valid
                        bcc :do_status
                        lda drvBadCode              ; #$0021, Invalid control or status code
                        sta errCode
                        rts
:do_status
                        stz transferCount
                        stz transferCount+2
                        asl
                        tax
                        jmp (statusTable,x)


statusTable             da  GetDeviceStatus         ; subcall $0000
                        da  GetConfigParameters     ; subcall $0001
                        da  GetWaitStatus           ; subcall $0002
                        da  GetFormatOptions        ; subcall $0003
                        da  GetPartitionMap         ; subcall $0004

GetConfigParameters
GetWaitStatus
                        lda #0
                        sta [statusListPtr]
                        lda #2
                        sta transferCount
                        rts

GetPartitionMap         brk $55
GetFormatOptions        brk $66


** Block Device Status Word **
* High Byte                                    Low Byte
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
* | 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
*    |    |    |                                            |         |    |    |
*    |    |    |                                            |         |    |    +-- 1 = Disk has been switched
*    |    |    |                                            |         |    +------- 1 = Device is interrupting
*    |    |    |                                            |         +----------- 1 = Device is write protected
*    |    |    |                                            +-------------- 1 = Disk in drive
*    |    |    |
*    |    |    +----------------------------------------- 1 = Background busy
*    |    +----------------------------------------------- 1 = Linked device
*    +--------------------------------------------------- 1 = Uncertain block count

** Response parameters (written to buffer @ statusListPtr)
*  $00 - Word - Status word (above)
*  $02 - Long - Numblocks
GetDeviceStatus         BorderColor #13             ; Yellow

                        lda #2                      ; default
                        sta transferCount

                        lda requestCount            ; check number of bytes to be transferred
                        cmp #6
                        bcc :not6
                        lda #6                      ; asked for 6 so we'll give 'em 6
                        sta transferCount

                        ldy #2                      ; write longword number of blocks
                        lda #MAXBLOCKS
                        sta [statusListPtr],y
                        iny
                        iny
                        lda #^MAXBLOCKS
                        sta [statusListPtr],y

:not6                   ldx #diskInDriveBit         ; #$0010  (bit 4)
                        lda udActive                ; is there a card?
                        bne :started                ; yes
                        inx                         ; no, add 1 to status (bit 0), now = #$0011 (disk has been switched)
:started                txa
                        ora #uncertainBlockCountBit ; finally set uncertainblockcount (bit 15) so = #$801x
                        sta [statusListPtr]         ; is our status
                        BorderColor #11
                        rts




** UD DRIVER CONSTANTS
MAXBLOCKS               =   $ffffffff               ; super-duper
MAXDEVICES              =   #1                      ; @todo verify
DEVVERSION              =   $001D                   ; v0.01d (developmental)  1000 for release
DEVID_HDD               =   $0013                   ; Hard disk drive (generic) (page 185)
DEVCHARACTERISTICS      =   $8BE8                   ; default characteristics 8FE8
                                                    ;  8 1000 => RAM or ROM disk
                                                    ;  B 1011 => restartable + not speed dependent
                                                    ;  E 1110 => block device | write allowed | read allowed
                                                    ;  C 1100 => 1000 format allowed | removable media


** COMMON VARIABLES
errCode                 ds  2
udActive                ds  2                       ; 0: inactive, 1: installed and active

** GS/OS ERROR CODES
invDevNum               =   #$0011                  ; Invalid device number
drvBadCode              =   #$0021                  ; Invalid control or status code
parmOutRng              =   #$0053                  ; Parameter out of range

** GS/OS EQUATES
uncertainBlockCountBit  =   $8000
diskSwitchedBit         =   $0001
diskInDriveBit          =   $0010
diskModifyBit           =   $0100

** GS/OS DIRECT PAGE
deviceNum               =   $00
callNum                 =   $02
bufferPtr               =   $04
statusListPtr           =   $04
* controlListPtr   =     $04
requestCount            =   $08
transferCount           =   $0C                     ;  Longword RESULT; indicates the number of bytes actually transferred
blockNum                =   $10
blockSize               =   $14
FSTNum                  =   $16                     ; *
statusCode              =   $16                     ; Word INPUT; Type of status request, only $0000-$0004 are defined
* controlCode      =     $16           ; *
volumeID                =   $18
cachePriority           =   $1A
cachePointer            =   $1C
dibPtr                  =   $20



*********************************************** DEBUG CODE START
CTRLRESETVECTOR         =   $E10064
OACTRLRESETVECTOR       =   $E11680

BorderColor             MAC
                        DO  DEBUG_BORDER
                        sep $30
                        lda #]1
                        stal $00c034
                        rep $30
                        FIN
                        EOM

BufferDebug             ldy #0
:prloop                 ldal [bufferPtr],y
                        jsr PrHexByte
                        lda #" "
                        jsr Cout80
                        tya                         ; check newline?
                        and #$0F
                        cmp #$0F
                        bne :cont
                        CR
:cont                   iny
                        cpy #$100
                        bne :prloop
                        rts


DRDebug                 DO  DEBUG_TEXT
                        pha
                        phx
                        phy

                        jsr TextLibInit
                        SAVEVID
                        jsr SetGSText
                        jsr Set80Col
                        jsr TextClear
                        PRINTSTR DRSTR
                        CR
                        CR
                        PRINTPARMWORD deviceNumSTR;deviceNum
                        PRINTPARMWORD callNumSTR;callNum
                        PRINTPARMLONG bufferPtrSTR;bufferPtr
                        PRINTPARMLONG requestCountSTR;requestCount
                        PRINTPARMLONG transferCountSTR;transferCount
                        PRINTPARMLONG blockNumSTR;blockNum
                        PRINTPARMWORD blockSizeSTR;blockSize
                        PRINTPARMWORD FSTNumSTR;FSTNum
                        PRINTPARMWORD volumeIDSTR;volumeID
                        PRINTPARMLONG dibPtrSTR;dibPtr
                        CR
                        CR
                        jsr DIBDebug                ; <-----------------------------

                        jsr WaitKey
                        *   jsr                     TextClear
                        *   jsr                     TextLibInit
                        *   jsr                     BufferDebug
                        *   jsr                     WaitKey
                        and #$00ff
                        cmp #"a"
                        bne :cont
                        brk $DB
:cont
                        jsr TextLibInit
                        jsr TextClear
                        RESTOREVID
                        ply
                        plx
                        pla
                        FIN
                        rts


DSDebug                 DO  DEBUG_TEXT
                        pha
                        phx
                        phy

                        jsr TextLibInit
                        SAVEVID
                        jsr SetGSText
                        jsr Set80Col
                        jsr TextClear
                        PRINTSTR DSSTR
                        CR
                        CR
                        PRINTPARMWORD deviceNumSTR;deviceNum
                        PRINTPARMWORD callNumSTR;callNum
                        PRINTPARMLONG bufferPtrSTR;bufferPtr
                        PRINTPARMLONG requestCountSTR;requestCount
                        PRINTPARMLONG transferCountSTR;transferCount
                        PRINTPARMWORD statusCodeSTR;statusCode
                        PRINTPARMLONG dibPtrSTR;dibPtr
                        CR
                        lda [statusListPtr]
                        sta tmpSpace
                        PRINTPARMWORD statusListSTR;tmpSpace

                        ldy #2
                        lda [statusListPtr],y
                        sta tmpSpace
                        iny
                        iny
                        lda [statusListPtr],y
                        sta tmpSpace+2

                        PRINTPARMLONG statusListSTR;tmpSpace
                        CR
                        jsr DIBDebug                ; <-----------------------------

                        jsr WaitKey
                        and #$00ff
                        cmp #"a"
                        bne :cont
                        brk $DB
:cont                   RESTOREVID
                        ply
                        plx
                        pla
                        FIN
                        rts

DIBDebug                pha
                        phx
                        phy

                        *   jsr                     TextLibInit
                        SAVEVID
                        jsr SetGSText
                        *   jsr                     Set80Col
                        *   jsr                     TextClear
                        PRINTSTR DIBSTR
                        CR
                        CR
                        ldy #$0
                        lda [dibPtr],y
                        sta tmpSpace
                        iny
                        iny
                        lda [dibPtr],y
                        sta tmpSpace+2
                        PRINTPARMLONG _dibstr00;tmpSpace
                        ldy #$8
                        lda [dibPtr],y
                        sta tmpSpace
                        PRINTPARMWORD _dibstr08;tmpSpace
                        ldy #$a
                        lda [dibPtr],y
                        sta tmpSpace
                        iny
                        iny
                        lda [dibPtr],y
                        sta tmpSpace+2
                        PRINTPARMWORD _dibstr0a;tmpSpace
                        ldy #$2e
                        lda [dibPtr],y
                        sta tmpSpace
                        iny
                        iny
                        lda [dibPtr],y
                        sta tmpSpace+2
                        PRINTPARMWORD _dibstr2e;tmpSpace
                        ldy #30
                        lda [dibPtr],y
                        sta tmpSpace
                        iny
                        iny
                        lda [dibPtr],y
                        sta tmpSpace+2
                        PRINTPARMWORD _dibstr30;tmpSpace


:cont                   RESTOREVID
                        ply
                        plx
                        pla
                        rts
DIBSTR                  asc "DIB - ",00
_dibstr00               asc " +00 linkPtr         - ",00
_dibstr04               asc " +04 entryPtr        - ",00
_dibstr08               asc " +08 characteristics - ",00
_dibstr0a               asc " +0a blockCount      - ",00
_dibstr0e               asc " +0e devName         - ",00
_dibstr2e               asc " +2e slotNum         - ",00
_dibstr30               asc " +30 unitNum         - ",00

DRSTR                   asc "Driver Read",00

DSSTR                   asc "Driver Status",00
deviceNumSTR            asc "      deviceNum: ",00
callNumSTR              asc "        callNum: ",00
bufferPtrSTR            asc "      bufferPtr: ",00
requestCountSTR         asc "   requestCount: ",00
transferCountSTR        asc "  transferCount: ",00
statusCodeSTR           asc "     statusCode: ",00
dibPtrSTR               asc "         dibPtr: ",00
blockNumSTR             asc "       blockNum: ",00
blockSizeSTR            asc "      blockSize: ",00
FSTNumSTR               asc "         FSTNum: ",00
volumeIDSTR             asc "       volumeID: ",00


statusListSTR           asc "     statusList: ",00
tmpSpace                ds  4

*********************************************** DEBUG CODE END


                        put ../../lib/ultimate-drive/udlib.s
                        put ../../lib/textlib.s     ; this is really just for debugging