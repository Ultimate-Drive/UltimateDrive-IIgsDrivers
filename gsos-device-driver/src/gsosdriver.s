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
                        typ $bb
                        dsk uddevice

                        use 4/Util.Macs


UDriveHeader            da  MainDIB-UDriveHeader    ; offset to 1st DIB, which is our only one
                        dw  MAXDEVICES              ; number of devices
                        dw  $0000                   ; no configuration list


** Dispatch Routine - per Apple IIgs GS/OS Device Driver Reference (p) 193
*
* A = Call number
MainEntry               asl
                        tax
                        stz	errCode
                        jsr	(dispatchTable,x)
                        lda	errCode
:done_prep_result      	cmp	#$0001
	                    rtl

** For a more detailed explanation of driver calls, see Chapter 10, "GS/OS Driver Call Reference."
dispatchTable           da	Driver_Startup      ; Prepares a device for all other device-related calls
                        da	Driver_Open         ; Pepares a character device for conducting I/O transactions
                        da	Driver_Read         ; Reads data from a character device or a block device
                        da	Driver_Write        ; Writes data to a character device or a block device
                        da	Driver_Close        ; Resets the driver to its nonopen state
                        da	Driver_Status       ; Gets information about the sutus of a specific device
                        da	Driver_Control      ; Sends control information or requests to a specific device
                        da	Driver_Flush        ; Writes out any characters in a.cha¡acter driver's buffer
                        da	Driver_Shutdown     ; Prepares a device driver to be purged

Driver_Startup
Driver_Open
Driver_Read
Driver_Write
Driver_Close
Driver_Status
Driver_Control
Driver_Flush
Driver_Shutdown
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
                        ds \
:devname                str 'UDriveDevice'          ; +0E device name
                        ds  #32-{*-:devname}        ;  .. Padding to 32 bytes
                        dw  $8000                   ; +2E slot number
                        dw  $0001                   ; +30 unit number
                        dw  DEVVERSION              ; +32 version
                        dw  DEVID_HDD               ; +34 device ID
                        dw  $0000                   ; +36 first linked device
                        dw  $0000                   ; +38 next linked device
                        adrl $00000000              ; +3A extended DIB ptr
                        dw  $0000                   ; +3E device number




** COMMON VARIABLES
errCode                 ds 2