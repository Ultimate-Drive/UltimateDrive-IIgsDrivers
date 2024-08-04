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
                        dec entbrk
                        lda entbrk
                        bne :notyet
                        brk $EA
:notyet                 jmp (routines,x)
entbrk                  dw  3

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
                        dw  udconfigure
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

                        PHB ; let's return the whole thing on the stack, trololol... 
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









udgetpacket
udsendpacket
udconnect
udreconstatus
udreconnect
uddisconnect
udgetvariables
udconfigure
udconfigfname
:okaaaa                 lda #terrok
                        clc
                        rtl



                        put marinetti_equates