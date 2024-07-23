* uthernet2 start
* 	brl	wizok				; dbgmsg dc
* 	dc	i'$7771'
* 	str	'UthernetII'		; ambed dc
* wizok nop
* 	nop

* 	jmp	(routines,x)

* routines dc	i'wizinterfacev'
* 	dc	i'wizstartup'
* 	dc	i'wizshutdown'
* 	dc	i'wizmoduleinfo'
* 	dc	i'wizgetpacket'
* 	dc	i'wizsendpacket'
* 	dc	i'wizconnect'
* 	dc	i'wizreconstatus'
* 	dc	i'wizreconnect'
* 	dc	i'wizdisconnect'
* 	dc	i'wizgetvariables'
* 	dc	i'wizconfigure'
* 	dc	i'wizconfigfname'

* wizinterfacev	anop
* 	brl	intvok		; dbgmsg wizinterfacev():interfacev:integer;
* 	dc	i'$7771'	; ambed  wizinterfacev():interfacev:integer
* 	str	'wizinterfacev():interfacev:integer'
* intvok	nop
* 	nop

* 	lda	#myllintvers
* 	sta	parmstack,s
                        REL
                        LNK    udnet.l   ;
terrok                  equ $0000
parmstack               equ 4
myllintvers               equ 2

entry                   brl udriveok


udriveok                nop
                        nop
                        jmp (routines,x)


routines                dw  udinterfacev
                        dw  udstartup
                        dw  udshutdown
                        dw  udmoduleinfo
                        dw  udgetpacket
                        dw  udsendpacket
                        dw  udconnect
                        dw  udreconstatus
                        dw  udreconnect
                        dw  uddisconnect
                        dw  udgetvariables
                        dw  udconfigure
                        dw  udconfigfname

udinterfacev
                        brl intvok

intvok                  nop
                        nop
                        lda #myllintvers
                        sta parmstack,s
                        lda #terrok
                        clc
                        rtl

udstartup
udshutdown
udmoduleinfo
udgetpacket
udsendpacket
udconnect
udreconstatus
udreconnect
uddisconnect
udgetvariables
udconfigure
udconfigfname
                        lda #terrok
                        clc
                        rtl