*****************************************************************
*  UltimateDrive GS/OS Device Driver
*  Author: Dagen Brock
*****************************************************************


** Format - per Apple IIgs GS/OS Device Driver Reference (p) 176
*
*    Header section
*    Configuration parameter list(s)    \_ Each supported device (or partition) requires a own Config AND DIB!
*    Device Information Block(s) (DIBs) /
*    Driver code segment(s)             - May be repeated per device or shared among multiple devices


                        mx  %00
                        rel
                        typ $bb                     ; All Apple IIcs driver load fìles must have a fìle type of $BB.
                                                    ; They may also be in Express Load format.
*                        aux $0101           ; AUXTYPE is $0101, but we can't set that here (Merlin32 bug?)
                        dsk UltimateDrive

                        use 4/Util.Macs

*********************************************** DEBUG CODE START
DEBUG_BORDER            =   1                       ; on/off flag
BorderColor             MAC
                        DO  DEBUG_BORDER
                        sep $30
                        lda #]1
                        stal $00c034
                        rep $30
                        FIN
                        EOM
*********************************************** DEBUG CODE END

UDriveHeader            da  MainDIB-UDriveHeader    ; offset to 1st DIB, which is our only one
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
* $38 - Word     - forwardLing     - Device number of next linked device
* $3A - LongWord - extendedDibPtr  - Pointer to additional device information
* $3E - Word     - DIBDevNum       - Initial device number (assigned at startup)
MainDIB                 ds  4                       ; +00 pointer to the next DIB
                        adrl MainEntry              ; +04 driver entry point
                        dw  DEVCHARACTERISTICS      ; +08 characteristics
                        ds  4                       ; +0A block count
                        ds  \
:devname                str 'UDriveDevice'          ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
]udSlot                 dw  $7000                   ; +2E slot number
                        dw  $0001                   ; +30 unit number
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
                        cmp #0
                        beq :go
                        brk $00
:go
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
:card_found             lda #1                      ; set activemake
                        sta udActive
                        rts

** Not Implemented
Driver_Open             BorderColor #1
                        rts

** @todo
Driver_Read             BorderColor #2
                        rts
** @todo
Driver_Write            BorderColor #3
                        rts

** Not Implemented
Driver_Close            BorderColor #4
                        rts

Driver_Status           BorderColor #5              ; CALLED 2nd!
                        lda statusCode
                        cmp #5                      ; Only calls 0-4 are valid
                        bcc :do_status
                        lda drvBadCode              ; drvrBadCode
                        sta errCode
                        rts
:do_status              asl
                        tax
                        stz transferCount
                        stz transferCount+2
                        jsr (statusTable,x)
                        rts

statusTable             da  DSGetStatus             ; GetDeviceStatus
                        da  DSGet                   ; GetConfigParameters
                        da  DSGet                   ; GetWaitStatus
                        da  DSGetFormatOptions      ; GetFormatOptions
                        da  DSNoOp                  ; GetPartitionMap
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

DSGetStatus             BorderColor #5
                        rts



Driver_Control          BorderColor #6
                        rts

** Not Implemented
Driver_Flush            BorderColor #7
                        rts

Driver_Shutdown         BorderColor #8
                        stz udActive
                        rts




*** config
MAXDEVICES              =   1                       ; @todo verify
DEVVERSION              =   $001D                   ; v0.01d (developmental)  1000 for release
DEVID_HDD               =   $0013                   ; Hard disk drive (generic) (page 185)
DEVCHARACTERISTICS      =   $8BE8                   ; default characteristics 8FE8
                                                    ;  8 1000 => 8 1000 RAM or ROM disk
                                                    ;  B 1011 => B 1011 restartable + not speed dependent
                                                    ;  E 1110 => E 1110 block device | write allowed | read allowed
                                                    ;  8 1000 => 8 1000 format allowed




** COMMON VARIABLES
errCode                 ds  2
udActive                ds  2                       ; 0: inactive, 1: installed and active

** GS/OS ERROR CODES
invDevNum               =   #$11                    ; Invalid device number
drvBadCode              =   #$21                    ; Invalid control or status code
parmOutRng              =   #$53                    ; Parameter out of range

** GS/OS DIRECT PAGE
transferCount           =   $0C                     ; Longword RESULT; indicates the number of bytes actually transferred
statusCode              =   $16                     ; Word INPUT; Type of status request, only $0000-$0004 are defined
                                                    ; $0000 GetDeviceStatus
                                                    ; $0001 GetConfigParameters
                                                    ; $0002 GetWaitStatus
                                                    ; $0003 GetFormatOptions
                                                    ; $0004 GetPartitionMap


                        put ../../lib/ultimate-drive/udlib.s