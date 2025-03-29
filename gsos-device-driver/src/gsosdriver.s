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
                                                    ; aux $010C           ; AUXTYPE is $010C, but we can't set that here (Merlin32 bug?) so we set in Makefile
* GS/OS Device Driver Ref P. 175 - re: auxtype
*              High byte                                           Low byte
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
* | 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
* +----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
*    |    |_____________________________|    |____|    |________________________|
*    |                |                         |                            |
*    |                |                         +--> 0 = device driver       |
*    |                |                              1 = supervisor driver   |
*    |                |                                                      +--> Maximum number of devices (if device driver)
*    |                |                                                           Undefined (if supervisor driver)
*    |                +--> S01 = GS/OS driver
*    |
*    +--> 1 = inactive
*         0 = active


                        dsk UltimateDrive
                        use 4/Util.Macs
DEBUG_BORDER            =   1                       ; on/off flag for debug borders
DEBUG_TEXT              =   1                       ; on/off flag for debug borders


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
DIBs
_dib0                   adrl _dib1                  ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
:devname                str 'UDriveDevice-H01'      ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot0                dw  $0000                   ; +2E slot number
                        dw  $0001                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number

_dib1                   adrl _dib2                       ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
:devname                str 'UDriveDevice-H02'      ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
_udSlot1                dw  $0000                   ; +2E slot number
                        dw  $0002                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number


_dib2                   adrl _dib3                       ; +00 pointer to the next DIB
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
*
* A = Call number
MainEntry               phk
                        plb
*                         cmp #0
*                         beq :go
*                         cmp #5
*                         beq :go
*                         brk $00
* :go
                        asl
                        tax
                        stz errCode
                        jsr (dispatchTable,x)
                        lda errCode
:done_prep_result       cmp #$0001
                        rtl

** For a more detailed explanation of driver calls, see Chapter 10, "GS/OS Driver Call Reference."
dispatchTable           da  Driver_Startup          ; Prepares a device for all other device-related calls - first call
                        da  Driver_Open             ; Pepares a character device for conducting I/O transactions
                        da  Driver_Read             ; Reads data from a character device or a block device
                        da  Driver_Write            ; Writes data to a character device or a block device
                        da  Driver_Close            ; Resets the driver to its nonopen state
                        da  Driver_Status           ; Gets information about the status of a specific device
                        da  Driver_Control          ; Sends control information or requests to a specific device
                        da  Driver_Flush            ; Writes out any characters in a character driver's buffer
                        da  Driver_Shutdown         ; Prepares a device driver to be purged


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
:card_found             ora #$0008                  ; bit 3 = 1 for card slot
                        sta _udSlot0
                        sta _udSlot1
                        lda #1                      ; set active
                        sta udActive
                        BorderColor #15
                        rts

** Not Implemented
Driver_Open             BorderColor #1
                        rts

** Need to copy 'requestCount' bytes starting at 'blockNum' from 'unitNum' of current dib @ 'dibPtr'
** Only change is we write transferCount, should reflect *actual* bytes, which it doesn't right now
Driver_Read             BorderColor #14
                        jsr DRDebug    

                        ldy #$30 ; unitNum 
                        lda [dibPtr],y
                        and #$000F
                        jsr UDReadBlock
                        lda	requestCount	; assume transfer=request @todo?
                    	sta	transferCount
                        lda	requestCount+2
                        sta	transferCount+2

                        BorderColor #12
                        jsr DRDebug

                        clc
                        rts
** @todo
Driver_Write            BorderColor #3
                        rts

** Not Implemented
Driver_Close            BorderColor #4
                        rts

BufferDebug             ldy #0
:prloop                 ldal [bufferPtr],y
                        jsr PrHexByte
                        lda #" "
                        jsr Cout80
                        tya     ; check newline?
                        and #$0F
                        cmp #$0F
                        bne :cont
                        CR
:cont                   iny
                        cpy #$100
                        bne :prloop
                        rts


DRDebug                 pha
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
                        jsr TextClear
                        jsr TextLibInit
                        jsr BufferDebug
                        jsr WaitKey
                        and #$00ff
                        cmp #"a"
                        bne :cont
                        brk $DB
:cont                   RESTOREVID
                        ply
                        plx
                        pla
                        rts


DSDebug                 pha
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

Driver_Status           BorderColor #5              ; CALLED 2nd!
                        lda statusCode
                        cmp #5                      ; Only calls 0-4 are valid
                        bcc :do_status
                        lda drvBadCode              ; #$0021, Invalid control or status code
                        sta errCode
                        rts
:do_status              asl
                        tax
                        stz transferCount
                        stz transferCount+2
                        jsr (statusTable,x)
                        rts


statusTable             da  DSGetStatus             ; $0000 = GetDeviceStatus
                        da  DSGet                   ; $0001 = GetConfigParameters
                        da  DSGet                   ; $0002 = GetWaitStatus
                        da  DSGetFormatOptions      ; $0003 = GetFormatOptions
                        da  DSNoOp                  ; $0004 = GetPartitionMap
DSGet
DSGetFormatOptions
DSNoOp                  rts

* Block Device Status:
*
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

** PARAMETERS
*  $00 - Word - Status word (above)
*  $02 - Long - Numblocks
DSGetStatus             BorderColor #13             ; Yellow
                        jsr DSDebug

                        lda #2                      ; default
                        sta transferCount

                        lda requestCount            ; check number of bytes to be transferred
                        cmp #6
                        bcc :not6
                        lda #6                      ; asked for 6 so we'll give 'em 6
                        sta transferCount


                        ldy #2                      ; write longword number of blocks
                        lda #maxBLOCKS
                        sta [statusListPtr],y
                        iny
                        iny
                        lda #^maxBLOCKS
                        sta [statusListPtr],y

:not6                   ldx #diskInDriveBit         ; #$0010  (bit 4)
                        lda udActive                ; is there a card?
                        bne :started                ; yes
                        inx                         ; no, add 1 to status (bit 0), now = #$0011 (disk has been switched)
:started                txa
                        ora #uncertainBlockCountBit ; finally set uncertainblockcount (bit 15) so = #$801x
                        sta [statusListPtr]         ; is our status
                        BorderColor #11
                        jsr DSDebug
                        rts




Driver_Control          BorderColor #6
                        rts

** Not Implemented
Driver_Flush            BorderColor #7
                        rts

Driver_Shutdown         BorderColor #8              ;brown
                        stz udActive
                        rts




*** config
MAXDEVICES              =   #12                     ; @todo verify
DEVVERSION              =   $001D                   ; v0.01d (developmental)  1000 for release
DEVID_HDD               =   $0013                   ; Hard disk drive (generic) (page 185)
DEVCHARACTERISTICS      =   $8BEC                   ; default characteristics 8FE8
                                                    ;  8 1000 => RAM or ROM disk
                                                    ;  B 1011 => restartable + not speed dependent
                                                    ;  E 1110 => block device | write allowed | read allowed
                                                    ;  C 1100 => 1000 format allowed | removable media




** COMMON VARIABLES
errCode                 ds  2
udActive                ds  2                       ; 0: inactive, 1: installed and active

** UD DRIVER EQUATES
maxBLOCKS               =   $ffffffff               ; super-duper

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
FSTNum           =     $16           ; *
statusCode              =   $16                     ; Word INPUT; Type of status request, only $0000-$0004 are defined
* controlCode      =     $16           ; *
volumeID                =   $18
cachePriority           =   $1A
cachePointer            =   $1C
dibPtr                  =   $20



*********************************************** DEBUG CODE START

BorderColor             MAC
                        DO  DEBUG_BORDER
                        sep $30
                        lda #]1
                        stal $00c034
                        rep $30
                        FIN
                        EOM
*********************************************** DEBUG CODE END


                        put ../../lib/ultimate-drive/udlib.s
                        put ../../lib/textlib.s     ; this is really just for debugging