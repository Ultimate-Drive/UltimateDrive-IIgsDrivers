 	gen	on
	mcopy uthernet.macros
*=================================================
*
* Uthernet.ASM - Uthernet link layer module
*
* Copyright (C) 1998-2002 Richard Bennett
* Copyright (c) 2005 Glenn Jones
* Copyright (c) 2004-2005 MagerValp
* Code from ip65 MagerValp is licensed ala BSD
* Copyright (c) 2006-20020 Ewen Wannop
* Copyright (c) 2024 Stephen Heumann
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
*=================================================
*
* 2003.04.21 RJBF - Initial release as open source
* 2005.10.14 RGJ  - Inital link layer for Uthernet
*                   Derived from the Direct Connect LL Driver
*                   and MagerValps ip65
* 2020.06.08 EW	  - Added choice of MTU option 
* 2024.05.10 STH  - Added support for sending broadcasts and multicasts
*
*=================================================

*-------------------------------------------------
* Main entry point
*-------------------------------------------------

uthernet start
	brl	csok		; dbgmsg dc
	dc	i'$7771'
	str	'Uthernet'		; ambed dc
csok nop
	nop

	jmp	(routines,x)

routines	dc	i'csinterfacev'
	dc	i'csstartup'
	dc	i'csshutdown'
	dc	i'csmoduleinfo'
	dc	i'csgetpacket'
	dc	i'cssendpacket'
	dc	i'csconnect'
	dc	i'csreconstatus'
	dc	i'csreconnect'
	dc	i'csdisconnect'
	dc	i'csgetvariables'
	dc	i'csconfigure'
	dc	i'csconfigfname'

	dc	c"uthernet_data"
; input and output buffers
         dc	c"eth_inp"
eth_inp_len	ds 2         	; input packet length
eth_inp		ds 1518	; space for input packet
	dc	c"eth_outp"
eth_outp_len ds 2		; output packet length
eth_outp	ds 1518	; space for output packet

; ethernet packet offsets
eth_dest	gequ 0	; destination address
eth_src		gequ 6	; source address
eth_type	gequ 12	; packet type
eth_data	gequ 14	; packet data

; protocols
eth_proto_ip gequ 0
eth_proto_arp gequ 6

; cfgdata  data 
defaultcfg	anop
cfgvers		equ 2
; connect data
cfgversion	dc i'cfgvers'	; version
cfg_ip		dc i1'192, 168, 0, 200'	; offset 2
cfg_netmask	dc i1'255, 255, 255, 0'	; offset 6
cfg_gateway	dc i1'192, 168, 0,   1'	; offset 10
cfg_mac		dc h'00 0e 3a a2 a2 a2'	; offset 14
cfg_slot    dc i'4'					; offset 20
use_dhcp    dc i'0'					; offset 22
cfg_vers	dc i'csversl'			; offset 24
            dc i'csversh'			; offset 26
cfg_mtu     dc i'1460'				; offset 28
cfglen		gequ *-defaultcfg

configuration mds cfglen			; 30 total

; holding values for packet retrieval
tmp_data anop
tmp_ip ds 4
tmp_netmask ds 4
tmp_gateway ds 4
tmp_server ds 4
tmp_lease ds 4
tmp_dns ds 4
tmp_dns2 ds 4
tmp_src_mac ds 6
tmp_src_ip ds 4
tmp_mtu ds 2
tmp_length gequ *-tmp_data

; ports - need to make it slot independant
cs_rxtx_data	gequ $e0c080             ; default slot 4 = $c0 offset
cs_tx_cmd	gequ $e0c084
cs_tx_len	gequ $e0c086
cs_packet_page gequ $e0c08a
cs_packet_data gequ $e0c08c
cs_def_slot	gequ $04	; slot 4 for default
cs_slot_offset dc i2'$0000'


pp_rx_ctl	gequ $0104
pp_line_ctl	gequ $0112
pp_self_ctl	gequ $0114
pp_bus_status gequ $0138
pp_ia		gequ $0158


;bss_arp data

; arp state machine
arp_idle	gequ 1	; idling
arp_wait	gequ 2	; waiting for reply
arp_state	ds 2		; current activity

; arguments for lookup and add 
arp		anop      	; ptr to mac/ip pair
arp_mac	ds 6      	; result is delivered here
arp_ip	ds 4	; set ip before calling lookup

; arp cache
ac_size	gequ 8	; lookup cache
ac_ip	gequ 6 	; offset for ip
ac_mac	gequ 0	; offset for mac
arp_cache ds +(6+4)*ac_size	; .res (6+4)*ac_size

; offsets for arp packet generation
ap_hw	gequ 14	; hw type (eth = 0001)
ap_proto gequ 16	; protocol (ip = 0800)
ap_hwlen gequ 18	; hw addr len (eth = 06)
ap_protolen	gequ 19	; proto addr len (ip = 04)
ap_op	gequ 20	; request = 0001, reply = 0002
ap_shw	gequ 22	; sender hw addr
ap_sp	gequ 28	; sender proto addr
ap_thw	gequ 32	; target hw addr
ap_tp	gequ 38	; target protoaddr
ap_packlen	gequ 42	; total length of packet

; offsets for udp packet generation
udp_source gequ 0 ; source port
udp_dest gequ 2 ; destination port
udp_len gequ 4 ; length
udp_cksum gequ 6 ; checksum
udp_data gequ 8 ; total length udp header

; offsets for bootp packet generation
bootp_op gequ 0 ; operation
bootp_hw gequ 1 ; hardware type
bootp_hlen gequ 2 ; hardware len
bootp_hp gequ 3 ; hops
bootp_transid gequ 4 ; transaction id
bootp_secs gequ 8 ; seconds since start
bootp_flags gequ 10 ; flags
bootp_ipaddr gequ 12 ; ip address knwon by client
bootp_ipclient gequ 16 ; client ip from server
bootp_ipserver gequ 20 ; server ip
bootp_ipgateway gequ 24 ; gateway ip
bootp_client_hrd gequ 28 ; client mac address
bootp_spare gequ 34
bootp_host gequ 44
bootp_fname gequ 108
bootp_data gequ 236 ; total length bootp packet
magiccookielo gequ $8263	; lo bytes of magic cookie
magiccookiehi gequ $6353	; hi bytes of magic cookie

; offsets for dhcp packet generation
dhcp_cookie gequ 0 ; dhcp magic cookie
dhcp_opcode gequ 4 ; option code
dhcp_oplen gequ 5 ; option length
dhcp_type gequ 6 ; message type
dhcp_pcode gequ 7 ; option code
dhcp_plen gequ 8 ; option length
dhcp_options gequ 9 ; various options
dhcp_mcode gequ 19 ; option code
dhcp_mlen gequ 20 ; option length
dhcp_mvalue gequ 21 ; value
dhcp_clicode gequ 23 ; option code
dhcp_clilen gequ 24 ; option length
dhcp_clihw gequ 25 ; hardware type
dhcp_clihdw gequ 26 ; client hardware address
dhcp_rcode gequ 32 ; option code
dhcp_rlen gequ 33 ; option length
dhcp_radd gequ 34 ; ip address
dhcp_ipcode gequ 38 ; option code
dhcp_iplen gequ 39 ; option length
dhcp_ipval gequ 40 ; value
dhcp_oend gequ 44 ; option code
dhcp_data gequ 45

dhcpdiscover gequ 1
dhcpoffer gequ 2
dhcprequest gequ 3
dhcpdecline gequ 4
dhcppack gequ 5
dhcpnack gequ 6
dhcprelease gequ 7
dhcpinform gequ 8

; gateway handling
gw_mask		ds 4     	; inverted netmask
gw_test		ds 4     	; gateway ip or:d with inverted netmask
gw_last		ds 1		; netmask length - 1

; timeout
arptimeout	ds 2		; time when we will have timed out
packettimeout ds 2		; for sending packets

;csgequ 	data
	lcla	&lup

* global stuff

	mx	0


myllintvers	gequ 2
lvver		gequ $0001

* set version to v1.0.5d1
csversh		gequ $0105	;mmmm_mmmm_mmmm_bbbb
csversl		gequ $2001	;sss0_0000_rrrr_rrrr ss-20=d,40=a,60=b,80=f,a0=r

;link layer variables as defined by marinetti
lvversion	gequ $0000
lvconnected	gequ $0002
lvipaddress	gequ $0004
lvrefcon	gequ $0008
lverrors	gequ $000c
lvmtu		gequ $0010
lvlen		gequ $0012

terrok		gequ $0000
terrlinkerror	gequ $0004+$3600
terrnoreconsupprt gequ $0014+$3600	;this module doesn't support reconnect
terruseraborted gequ $0015+$3600
terrmask		gequ $00ff

tcpiptoolnum	gequ $36
conEthernet	gequ $0001
conMacIP	gequ $0002
conPPPCustom gequ $0003
conSLIP		gequ $0004
conTest		gequ $0005
conPPP		gequ $0006
conDirectConnect gequ $0007
conAppleEthernet gequ $0008
conLanceGS	gequ $0009
conUthernet gequ $000A
conSweet16	gequ $000B
conKEGS		gequ $000C
conEmulator gequ $000D
true		gequ $8000
false		gequ $0000

; ip packets start at ethernet packet+14
ip_inp		gequ eth_inp+eth_data
ip_outp		gequ eth_outp+eth_data

; ip packet offsets
ip_ver_ihl	gequ 0
ip_tos		gequ 1
ip_len		gequ 2
ip_id		gequ 4
ip_frag		gequ 6
ip_ttl		gequ 8
ip_proto		gequ 9
ip_header_cksum gequ 10
ip_src		gequ 12
ip_dest		gequ 16
ip_data		gequ 20

; my direct space on marinetti's direct page
tmppkthandle	gequ $e0
tmppktptr	gequ $e4
cfghandle	gequ $e8
cfgptr		gequ $ec
ap		gequ $f0
eth_packet	gequ $f2
ipmask		gequ $f4
ipgw		gequ $f8

windowlen	gequ 50	;length of match window (must by multiple of 2)

parmstack	gequ 4
parmstackb	gequ 1+parmstack

* csinterfacev():interfacev:integer;
* csstartup():interfacev:integer;
* csshutdown();
* csmoduleinfo(infoblockptr:longword);
* csgetpacket():packethandle:handle;
* cssendpacket(datagramptr:longword,datagramlength:integer);
* csconnect(conmsgflag:integer,usernameptr:longword,passwordptr:longword,displayptr:longword,conhandle:handle);
* csreconstatus():reconstatus:boolean;
* csreconnect(displayptr:longword);
* csdisconnect(conmsgflag:integer,usernameptr:longword,passwordptr:longword,displayptr:longword,disconhandle:handle);
* csgetvariables():variablesptr:longword
* csconfigure(connecthandle,disconnecthandle);
* csconfigfname(configfilenameptr:longword);

*-------------------------------------------------
* csinterfacev():interfacev:integer;
*-------------------------------------------------
csinterfacev	anop
	brl	intvok		; dbgmsg csinterfacev():interfacev:integer;
	dc	i'$7771'	; ambed  csinterfacev():interfacev:integer
	str	'csinterfacev():interfacev:integer'
intvok	nop
	nop

	lda	#myllintvers
	sta	parmstack,s

*-------------------------------------------------
* csstartup():interfacev:integer;
* csshutdown()
*-------------------------------------------------
csstartup anop
	brl	suok		; dbgmsg csstartup
	dc	i'$7771'	; ambed csstartup
	str	'csstartup'
suok	nop
	nop
	
csshutdown anop
	brl	sdok		; dbgmsg csshutdown
	dc	i'$7771'	; ambed csshutdown
	str	'csshutdown'
sdok	nop
	nop

	lda	#lvver
	sta	>variables+lvversion
	lda	#terrok
	clc
	rtl
	

*-------------------------------------------------
* csmoduleinfo(infoblockptr:longword);
*-------------------------------------------------
csmoduleinfo anop
	brl	modok		; dbgmsg csmoduleinfo(infoblockptr:longword);
	dc	i'$7771'	; ambed csmoduleinfo(infoblockptr:longword)
	str	'csmoduleinfo(infoblockptr:longword)'
modok	nop
	nop

	phb			; push data bank register
	phk			; push program bank register
	plb			; pull databank register
; databank is unknown when marinetti calls the ll
; the last 3 instructions effectively make the data bank the same as the program bank
	tsc			; copy stack pointer to a
	phd			; save current direct page register on stack
	tcd			; make the dp the same as the original sp
; work directly off the stack
	shortm		; a and i set to 8 bits
	ldy   #infol-1	; length of our data -1
loop1	lda   info,y	; get a byte of our data
	sta   [1+parmstack],y	; store it using the ptr provided on the stack
	dey
	bpl   loop1
	longm
; clean up
	pld			; put back the original dp
	pla			; get the databank reg back
	sta   3,s		; over write the parm
	pla
	sta   3,s		; over write the parm
	plb			; fixup the databank reg
	lda   #terrok	; lifes wonderful
	clc			; everybodys happy
	rtl			; time to go home

;infodata	data
info	dc	i'conUthernet'
is1	str	'Uthernet'
	mds	+(21-*)+is1

csversion anop
	dc    i'csversl'
	dc    i'csversh'
	dc    b'0000000000000000'
infol	gequ	*-info

*-------------------------------------------------
* csgetpacket():packethandle:handle;
*-------------------------------------------------

; put code here to determine if arp handling is required for this packet
; is arp packet?
;    call arp processing code - store request in arp cache and send out arp reply
; is ip packet?
;    return handle to marinetti

csgetpacket anop
	brl	gpok		; dbgmsg csgetpacket():packethandle:handle;
	dc	i'$7771'	; ambed csgetpacket():packethandle:handle
	str	'csgetpacket():packethandle:handle'
gpok	nop
	nop

	phb			; push data bank register
	phk			; push program bank register
	plb			; pull databank register
	sty	userid	; save marinetti userid

	ldx	cs_slot_offset

	lda	#$0124		; check rx status
	sta	>cs_packet_page,x

	lda	>cs_packet_data,x
	and	#$0d00
	bne	cont_rx
	brl	none

cont_rx	anop

	shortm
	
 	lda	>cs_rxtx_data+1,x	; ignore status
 	lda	>cs_rxtx_data,x

 	lda	>cs_rxtx_data+1,x	; read packet length
	sta	eth_inp_len+1
 	lda	>cs_rxtx_data,x	; read packet length
	sta	eth_inp_len

	longm
	
	lda	eth_inp_len	; if too big, flush and ignore packet
	cmp	#1519	; the size of our buffer+1
	bcc	get_packet

	ldy	#0
flush	anop
	lda	>cs_rxtx_data,x	; flush only
	iny
	iny
	cpy	eth_inp_len
	bcc	flush
	bra	nogo

get_packet anop	

	lda	#eth_inp	; set packet pointer
	sta	eth_packet

	ldy	#0
get	anop
	lda	>cs_rxtx_data,x
	sta	(eth_packet),y
	iny
	iny
	cpy	eth_inp_len
	bcc	get

	lda	eth_inp+12	; type should be 08xx
	and	#$ff
	cmp	#8
	bne	nogo		; not an ip packet so discard it
	lda	eth_inp+13
	and	#$ff
	bne	seearp
	brl	ip

seearp anop
	cmp	#eth_proto_arp	; arp = 06
	beq	arppkt
nogo	brl	none

arppkt	anop

	lda	eth_inp+ap_op	; should be 0
	and	#$ff
	bne	badpacket
	lda	eth_inp+ap_op+1	; check opcode
	and	#$ff
	cmp	#1	; request?
	beq	request
	cmp	#2	; reply?
	beq	reply

badpacket anop
	brl	none

request	anop
	ldx	#2
chkadr	lda	eth_inp+ap_tp,x	; check if they're asking for
	cmp	configuration+2,x	; my address
	bne	done
	dex
	dex
	bpl	chkadr	

	jsr	ac_add_source	; add them to arp cache

	ldx	#4		; send reply
bldreply lda	eth_inp+ap_shw,x
	sta	eth_outp,x	; set sender packet dest
	sta	eth_outp+ap_thw,x	; and as target
	lda	configuration+14,x	; me as source
	sta	eth_outp+ap_shw,x
	dex
	dex
	bpl	bldreply
	
	ldx	#4
setmac	lda	configuration+14,x
	sta	eth_outp+6,x
	dex
	dex
	bpl	setmac

	jsr	makearppacket	; add arp, eth, ip, hwlen, protolen

	lda	#$0200		; set opcode (reply = 0002)
	sta	eth_outp+ap_op

	ldx	#2
setadr	lda	eth_inp+ap_sp,x	; sender as target addr
	sta	eth_outp+ap_tp,x
	lda	configuration+2,x	; my ip as source addr
	sta	eth_outp+ap_sp,x
	dex
	dex
	bpl	setadr

	lda	#ap_packlen	; set packet length
	sta	eth_outp_len

	jsr	eth_tx	; send packet

done	anop
	brl	none

reply	anop
	lda	arp_state
	cmp	#arp_wait	; are we waiting for a reply?
	bne	badpacket

	jsr	ac_add_source	; add to cache

	lda	#arp_idle
	sta	arp_state

	brl	none

; add source to cache

ac_add_source anop

	lda	#eth_inp+ap_shw
	sta	ap

	ldx	#68		; make space in the arp cache
movearp anop
	lda	arp_cache,x
	sta	arp_cache+10,x
	dex
	dex
	bpl	movearp

	ldy	#8
copyarp  anop
	lda	(ap),y	; copy source
	sta	arp_cache,y
	dey
	dey
	bpl	copyarp
	rts

ip	anop
        	
	pha
	pha
	pea	0
	sec
	lda	eth_inp_len	; how much space (should this be lda long?)
	sbc	#eth_data                ; don't need the ethernet header
	sta	len
	pha
	lda	userid
	pha
	pea	$0018                    ; mem atributes
	pea	0
	pea	0
	_newhandle
	ply
	plx
	sty	tmppkthandle
	stx	tmppkthandle+2

	pushlong #ip_inp
	phx
	phy
	pea	0
	lda	len
	pha
	_ptrtohand

	lda	tmppkthandle
	sta	parmstackb,s
	lda	tmppkthandle+2
	sta	parmstackb+2,s
	lda	#terrok
	plb
	clc
	rtl


none	anop
	lda	#0
	sta	parmstackb,s
	sta	parmstackb+2,s
	plb
	clc
	rtl

userid		dc i'0'
len		ds 2		; temp storage for size calculation

*-------------------------------------------------
* cssendpacket(datagramptr:longword,datagramlength:integer);
*-------------------------------------------------

cssendpacket anop

	brl 	spok		; dbgmsg cssendpacket(datagramptr:longword,datagramlength:integer);
	dc    i'$7771'	; ambed cssendpacket(datagramptr:longword,datagramlength:integer)
	str   'cssendpacket(datagramptr:longword,datagramlength:integer)'
spok	nop
	nop

	lda	tick_count_start	; only do it once
	ora tick_count_start+2
	bne	nocount

	pha	; initialise timer count
	pha
	_tickcount
	pla
	sta tick_count_start
	plx
	stx tick_count_start+2

nocount anop

	lda	parmstack+2,s
	sta	>loopin+1
	lda	parmstack+3,s
	sta	>loopin+2
	lda	parmstack,s	; length
	sta	>pklen+1
	clc
	adc	#eth_data
	sta	>eth_outp_len
	
	lda	#ip_outp
	sta	>loopout+1
	lda	#ip_outp|-8
	sta	>loopout+2
	ldx	#0
loopin	lda	>0,x	; address set above
loopout	sta	>0,x	; address set above
	inx
	inx
pklen	cpx   #0	; address set above
	bcc   loopin

	phb			; save databank
	phk			; save program bank
	plb			; make data bank same as program bank

	lda	ip_outp+ip_dest	; get mac addr from ip
	sta	arp_ip
	ldx	ip_outp+ip_dest+2
	stx	arp_ip+2
	
	cmp	#$ffff	; check for broadcast addresses
	bne	chk_bc2
	cpx	#$ffff
	beq	bcast
chk_bc2	cmp	gw_test
	bne	chk_mc
	cpx	gw_test+2
	bne	chk_mc
	
bcast	lda	#$ffff	; set destination MAC for broadcast
	sta	arp_mac
	sta	arp_mac+2
	sta	arp_mac+4
	brl	arp_ok

chk_mc	and	#$F0	; check for multicast addresses
	cmp	#$E0
	bne	use_arp
	
	lda	#$0001	; set destination MAC for multicast
	sta	arp_mac
	lda	ip_outp+ip_dest
	and	#$7F00
	ora	#$005E
	sta	arp_mac+2
	stx	arp_mac+4
	brl	arp_ok
	
use_arp	shortmx
	
* arp_lookup routine

	ldx	gw_last	; check if address is on our subnet
nextadr	lda	arp_ip,x
	ora	gw_mask,x
	cmp	gw_test,x
	bne	notlocal
	dex
	bpl	nextadr
	bmi	local

notlocal	anop
	ldx	#3		; copy gateway's ip address
nextgw 	lda	ipgw,x
	sta	arp_ip,x
	dex	
	bpl	nextgw

local	anop	; findip routine

	lda	#<arp_cache
	ldx	#>arp_cache
	stax	ap

	ldx	#ac_size
compare	anop			; compare cache entry
	ldy	#ac_ip
	lda	(ap),y
	beq	cachemiss
cmpnext  anop
	lda	(ap),y
	cmp	arp,y
	bne	nextent
	iny
	cpy	#ac_ip+4
	bne	cmpnext
	bra	copy_mac
	
nextent  anop			; next entry
	lda	ap
	clc
	adc	#10
	sta	ap
	bcc	noinc
	inc	ap+1
noinc    dex
	bne	compare
	bra	cachemiss

copy_mac	anop

	ldy	#ac_ip-1	; copy mac
nextmac  anop
	lda	(ap),y
	sta	arp,y
	dey
	bpl	nextmac
	longmx
	brl arp_ok

cachemiss anop

	longmx

	lda	arp_state	; are we already waiting for a reply?
	cmp	#arp_idle
	beq	sendrequest	; yes, send request

	lda	arptimeout	; check if we've timed out
	pha
	jsr	timer_read	; read current timer value
	sta	time
	pla
	sec			; subtract current value
	sbc	time
	bcs	notimeout	; no, don't send

sendrequest anop	; send out arp request

	jsr	maketheheader

	ldx	#4
setmac1  lda	configuration+14,x
	sta	eth_outp+6,x
	dex
	dex
	bpl	setmac1

	jsr	makearppacket	; add arp, eth, ip, hwlen, protolen

	lda	#$0100		; set opcode (request = 0001)
	sta	eth_outp+ap_op

	ldx	#4
setmac2  lda	configuration+14,x	; set source mac addr
	sta	eth_outp+ap_shw,x
	lda	#0		; set target mac addr
	sta	eth_outp+ap_thw,x
	dex
	dex
	bpl	setmac2

	ldx	#2
setip	lda	configuration+2,x	; set source ip addr
	sta	eth_outp+ap_sp,x
	lda	arp_ip,x	; set target ip addr
	sta	eth_outp+ap_tp,x
	dex
	dex
	bpl	setip

	lda	#ap_packlen	; set packet length
	sta	eth_outp_len

	jsr	eth_tx	; send packet

	lda	#arp_wait	; waiting for reply
	sta	arp_state

	jsr	timer_read	; read current timer value
	clc
	adc	#0060	; set timeout to now+1000 ms
	sta	arptimeout

notimeout anop
	lda	#terrlinkerror
	and	terrmask
	tay
	sec
	bra	cleanup	; packet buffer nuked, fail

arp_ok	anop
	ldx	#4
setmac_s	lda	arp_mac,x	; copy destination mac address
	sta	eth_outp+eth_dest,x
	lda	configuration+14,x	; copy my mac address
	sta	eth_outp+eth_src,x
	dex
	dex
	bpl	setmac_s

	lda	#$0008	; set type to ip
	sta	eth_outp+eth_type

	jsr	eth_tx	; send packet and return status
	bcc	send_ok
	ldy	#terrlinkerror
	and	terrmask
	bra	cleanup
send_ok	anop	
	ldy	#terrok
cleanup  anop
	plb
	pla
	sta	5,s
	pla
	sta	5,s
	pla
	tya
	rtl

*-------------------------------------------------
* csconnect(conmsgflag:integer,usernameptr:longword,passwordptr:longword,displayptr:longword,conhandle:handle);
*-------------------------------------------------
csconnect anop
	brl   cnok		; dbgmsg dcconnect
	dc    i'$7771'	; ambed dcconnect
	str   'csconnect'
cnok	nop
	nop

	phb                             ;push data bank register
	phk                             ;push program bank register
	plb                             ;pull databank register
	sty   userid                    ;marinetti memory request id

	lda   #terruseraborted
	sta   err_return

	stz   variables+lverrors        ; start with a clean slate
	stz   variables+lvipaddress     ;
	stz   +(variables+lvipaddress)+2
	lda   cfg_mtu		            ; 1460 byte mtu default
	sta   variables+lvmtu

	lda   parmstackb+16,s           ; check the msg flag
	bne   showokk                   ; there is msg display routine
	stz   displayptr+1              ; no display routine so skip printing a mesasge
	stz   +(displayptr+1)+1
	bra   joinn
showokk  lda   parmstackb+4,s       ; get the display pointer and update the code
	sta   displayptr+1
	lda   +((parmstackb+4)+1),s
	sta   +(displayptr+1)+1
	lda   #linkstrs                 ; connection started
	jsr   showpstring
joinn	anop

	lda   parmstackb,s              ; get handle to config space low
	sta   cfghandle
	lda   parmstackb+2,s            ; get handle to config space high
	sta   cfghandle+2
	lda   [cfghandle]               ; use the handle to get the address of the config area
; setting up zero page access to the config area
; check handle size if not same as data, resize and copy new
	sta   cfgptr
	ldy   #2
	lda   [cfghandle],y
	sta   cfgptr+2
; check if we already have a config saved
	ldy   #8
	lda   [cfghandle],y
	iny
	iny
	ora   [cfghandle],y
	beq   newconfig
; we need to copy in the previous saved config or set one up for the first time
; use the config area to see what marinetti has for us to use
;
; configuration is our working copy of the config
;
	lda   [cfgptr]                  ; test first word should match the config version
	cmp   #cfgvers
	beq   docfg                     ; on to the target address

; we havn't set one yet so use the defaults and report we can't start
newconfig anop

	pea   defaultcfg|-16            ; source address for the copy - low
	pea   defaultcfg                ;                             - high
	pea   configuration|-16         ; target address for the copy - low
	pea   configuration             ; target address for the copy - high
	pea   cfglen|-16	            ; cfglen how many bytes to copy
	pea   cfglen
	_tcpipptrtoptr					; copy data routine

	brl   err

docfg	anop

	pei   cfgptr+2                  ; source address for the copy - low
	pei   cfgptr                    ;                             - high
	pea   configuration|-16         ; target address for the copy - low
	pea   configuration             ; target address for the copy - high
	pea   cfglen|-16	; cfglen how many bytes to copy
	pea   cfglen
	_tcpipptrtoptr					; copy data routine

	lda   configuration+28		    ; 1460 byte mtu default
	sta   variables+lvmtu

;
; so now that we have a copy of our configuration data lets start to get the card going
;

	pha	; seed the random number generator
	pha
	pha
	pha
	_readtimehex	; we don't have EM started, so use the clock
	plx
	ply
	pla
	pla
	phy
	phx
	_setrandseed

	lda	configuration+20
	asl	a
	asl	a
	asl	a
	asl	a
	sta	cs_slot_offset

	shortmx

	lda   #0		; check magic signature
	jsr   cs_read_page
	cpx   #$0e
	bne	  jmperr
	cpy   #$63
	bne   jmperr
	
	lda   #1
	jsr   cs_read_page
	cpx   #0
	beq   nojmperr

jmperr	anop

	brl   err

nojmperr anop
; y contains chip rev

	write_page pp_self_ctl,$0055	; $0114, reset chip
	write_page pp_rx_ctl,$0d05	; $0104, accept individual and broadcast packets

	lda   #pp_ia/2	; $0158, write mac address
	ldx   configuration+14
	ldy   configuration+14+1
	jsr   cs_write_page

	lda   #pp_ia/2+1
	ldx   configuration+14+2
	ldy   configuration+14+3
	jsr   cs_write_page

	lda   #pp_ia/2+2
	ldx   configuration+14+4
	ldy   configuration+14+5
	jsr   cs_write_page

	write_page pp_line_ctl,$00d3	; $0112, enable rx and tx

	longmx

	lda   configuration+22	; do we try dhcp to request an ip address
	beq   no_dhcp
	jsr   request_dhcp	; go and try to get one
	bcs   no_dhcp	; do not save it if we did not get one

	ldy   #2	; copy our ip address, mask, gateway to parms
copy_tmp anop
	lda   tmp_ip-2,y
	sta	  configuration,y	; keep it locally
	iny
	iny
	cpy   #14
	bcc   copy_tmp
	
	lda   tmp_dns	; check if primary empty
	ora   tmp_dns+2
	beq   mtu_offered
	
	pushlong #tmp_dns	; copy the new dns back to marinetti
	_tcpipsetdns
	
mtu_offered anop

	lda   tmp_mtu	; did the server tell us its mtu size
	beq   no_dhcp
	cmp   #1500
	bcs   no_dhcp
	sta   variables+lvmtu

no_dhcp	anop

	lda   #csversl	; copy our version marker as it may have changed
	sta   configuration+24
	lda   #csversh
	sta   configuration+26

	pha		; now we must create a handle to pass back the updated data
	pha
	pushlong #cfglen
	pushword userid
	pea   $18
	pea	  0
	pea   0
	_newhandle
	pulllong temphandle
	
	pushlong #configuration	; copy the data to the handle
	pushlong temphandle
	pushlong #cfglen
	_ptrtohand
	
	pushword #conUthernet	; now tell marinetti the new data
	pushlong temphandle
	_tcpipsetconnectdata
	
	lda   configuration+2	; cfgip offset = 2
	sta   variables+lvipaddress
	lda   +(configuration+2)+2	; cfgip offset = 2
	sta   +(variables+lvipaddress)+2

	lda   configuration+6	; cfgipmask offset = 6
	sta   ipmask	; zero page var
	lda   +(configuration+6)+2	; cfgipmask offset = 6
	sta   ipmask+2

	lda   configuration+10	; cfgipgw offset = 10
	sta   ipgw		; zero page var
	lda   +(configuration+10)+2	; cfgipgw offset = 10
	sta   ipgw+2

	lda   #setmacstr	; display our connect data
	jsr   showpstring

; initialize arp
	shortmx

	lda	#0
	ldx	#(6+4)*ac_size-1	; clear cache
clr	sta	arp_cache,x
	dex
	bpl	clr

	lda	#$ff		; counter for netmask length - 1
	sta	gw_last

	ldx	#3
gw	anop
	lda	ipmask,x
	eor	#$ff
	cmp	#$ff
	beq	next		; was bne
	inc	gw_last
next sta gw_mask,x
	ora	ipgw,x
	sta	gw_test,x
	dex
	bpl	gw

	longmx

	lda	#arp_idle	; start out idle
	sta	arp_state

	lda   #true
	sta   variables+lvconnected
	lda	  #terrok
	sta   err_return

err	longmx

	pla
	sta   21,s
	pla
	sta   21,s
	pla
	pla
	pla
	pla
	pla
	pla
	pla
	pla
	pla
	lda   err_return
	plb
	cmp   #1
	rtl

	longa	off
	longi	off

; read x/y from page a * 2
cs_read_page anop

	ldx	cs_slot_offset
	asl	a
	sta	>cs_packet_page,x
	lda	#0
	rol	a
	sta	>cs_packet_page+1,x
	pha
	lda	>cs_packet_data,x
	pha
	lda	>cs_packet_data+1,x
	tay
	plx
	pla      
	rts

; write x/y to page a * 2
cs_write_page anop

	phx
	ldx	cs_slot_offset
	asl	a
	sta	>cs_packet_page,x
	lda	#0
	rol	a
	sta	>cs_packet_page+1,x
	plx
	pha
	txa
	ldx	cs_slot_offset
	sta	>cs_packet_data,x
	tya
	sta	>cs_packet_data+1,x
	pla     
	rts

	longa	on
	longi	on

setmacstr	str 'MAC address initialized '

linkstrs		str 'Starting Uthernet driver'

err_return ds 2
temphandle ds 4

*-------------------------------------------------
* csreconstatus():reconstatus:boolean;
*-------------------------------------------------

csreconstatus anop
	brl	resok		; dbgmsg csreconstatus
	dc    i'$7771'	; ambed csreconstatus
	str   'csreconstatus'
resok 	nop
	nop

	lda   #false
	sta   parmstack,s
	clc
	rtl

*-------------------------------------------------
* csreconnect(displayptr:longword);
*-------------------------------------------------

csreconnect anop
         brl	reok		; dbgmsg csreconnect(displayptr:longword);
	dc i'$7771'		; ambed  csreconnect(displayptr:longword)
	str 'csreconnect(displayptr:longword)'
reok	nop
	nop

	phb
	pla
	sta	3,s
	pla
	sta	3,s
	plb
	lda	#terrnoreconsupprt
	and	terrmask
	sec
	rtl

*-------------------------------------------------
* csdisconnect(conmsgflag:integer,usernameptr:longword,passwordptr:longword,displayptr:longword,disconhandle:handle);
*-------------------------------------------------

csdisconnect anop
	brl	diok                      	; dbgmsg csdisconnect
	dc   i'$7771'	; ambed  csdisconnect
	str  'csdisconnect'
diok	nop
	nop

	phb
	phk
	plb
	
	lda   parmstackb+16,s
	bne   showok
	stz   displayptr+1
	stz   +(displayptr+1)+1
	bra   join
showok   lda   parmstackb+4,s
	sta   displayptr+1
	lda   +((parmstackb+4)+1),s
	sta   +(displayptr+1)+1
join     anop
	lda   #linkstre
	jsr   showpstring
	lda   #false
	sta   variables+lvconnected
	lda   #terrok
	tax
	pla
	sta   17,s
	pla
	sta   17,s
	pla
	pla
	pla
	pla
	pla
	pla
	pla
	txa
	plb
	cmp   #1
	rtl

linkstre str	'Shutdown Uthernet port'


*-------------------------------------------------
* csgetvariables():variablesptr:longword
*-------------------------------------------------

csgetvariables anop
	brl	gvok		; dbgmsg csgetvariables
	dc    i'$7771'                 ; ambed  csgetvariables
	str   'csgetvariables'
gvok	nop
	nop

	lda   #variables
	sta   4,s
	lda   #variables|-16
	sta   4+2,s
	lda   #terrok
	clc
	rtl

*-------------------------------------------------
* csconfigfname(configfilenameptr:longword);
*-------------------------------------------------

csconfigfname anop
	brl 	cfnok		; dbgmsg csconfigfname(configfilenameptr:longword);
	dc    i'$7771'	; ambed  csconfigfname(configfilenameptr:longword)
	str   'csconfigfname(configfilenameptr:longword)'
cfnok	nop
	nop

	tsc
	phd
	tcd
	shortmx
	lda	>configfname
	tax
l1	lda	>configfname,x
	txy
	sta	[4],y
	dex
	bpl l1
	longmx
	pld
	phb
	pla
	sta   3,s
	pla
	sta   3,s
	plb
	lda   #terrok
	clc
	rtl

configfname anop
	dc	i1"l:csf"
csf	dc	c"Uthernet.data"


*-------------------------------------------------
* dhcp request sequence
*-------------------------------------------------

request_dhcp anop

	jsr	timer_read2	; prime the timer
	lda	timer
	sta	start_time
	lda	timer+2
	sta	start_time+2

	stz	dhcp_offer	; we mark if we are done in this variable
	lda	#4*2	; four retries of the pair
	sta	packettries	; allow up to four attempts for 60 seconds

	jsr	timer_read2	; get start time in seconds
	sta dhcpwait
	clc
	adc	#60	; set timeout to 1 minute
	sta	dhcptimeout

	pha
	_random
	pullword randomnum	; get lo byte for the transaction id
	pha
	_random
	pullword randomnum+2	; get hi byte for the transaction id
	
start_again anop

	ldx	#0
dhcp_clean	anop	; clean the values
	stz	tmp_data,x
	inx
	inx
	cpx #tmp_length
	bcc	dhcp_clean
	
; first build the ethernet header

	jsr	maketheheader ; add first six bytes of ethernet header
	
	ldx	#4	; now add rest of the header
setmac3  lda configuration+14,x	; set source mac addr
	sta	eth_outp+eth_src,x
	dex
	dex
	bpl	setmac3

	lda	#0008	; ip protocol = 0800
	sta eth_outp+eth_type
	
; now build an ip header datagram
	
	lda	#$0045	; ip header version = 4 header length = 5 type of service = %00000000
	sta	eth_outp+eth_data
	lda	#$4801	; length = 328
	sta	eth_outp+eth_data+ip_len
	
	lda	#$0100 ; identifier = 0001	; discover
	sta	eth_outp+eth_data+ip_id
	
	stz	eth_outp+eth_data+ip_frag	; fragmentation flags
	stz	eth_outp+eth_data+ip_frag+2
	
	lda	#$11ff	; time to live = 256 udp protocol = 17
	sta	eth_outp+eth_data+ip_ttl
	
	stz	eth_outp+eth_data+ip_header_cksum	; zero checksum for now

	stz	eth_outp+eth_data+ip_src	; we don't know the source ip yet
	stz	eth_outp+eth_data+ip_src+2
	
	lda	#$ffff
	sta	eth_outp+eth_data+ip_dest	; send it to all destinations
	sta	eth_outp+eth_data+ip_dest+2

	ldx	#0	; calculate ip header checksum
	stz	chktemp
	clc
chck lda eth_outp+eth_data,x
	xba
	adc	chktemp
	adc	#0	; make sure we catch any overflow
	sta chktemp
	inx
	inx
	cpx	#20
	bcc chck
	lda chktemp
	eor #$ffff	; invert
	xba
	sta eth_outp+eth_data+ip_header_cksum	; add checksum to packet
	
; now build the udp datagram

	lda	#$4400	; source port = 68 bootpc
	sta eth_outp+eth_data+ip_data
	lda	#$4300	; dest port = 67 bootps
	sta eth_outp+eth_data+ip_data+2

	lda	#$3401	; length = 308
	sta eth_outp+eth_data+ip_data+udp_len
	
	stz eth_outp+eth_data+ip_data+udp_cksum	; write a zero value for checksum
	stz eth_outp+eth_data+ip_data+udp_cksum+2 ; we don't care
	
; build the bootp data now

	lda	#$0101	; op = 1 boot request hardware = 1 ethenet (10mb)
	sta eth_outp+eth_data+ip_data+udp_data
	lda	#$0006	; hardaware length = 6 hops = 0
	sta eth_outp+eth_data+ip_data+udp_data+bootp_hlen
	lda randomnum	; unique transaction id
	sta eth_outp+eth_data+ip_data+udp_data+bootp_transid	
	lda randomnum+2
	sta eth_outp+eth_data+ip_data+udp_data+bootp_transid+2

	ldx	#18	; fill out some zeros for the unknowns
bloop stz eth_outp+eth_data+ip_data+udp_data+bootp_secs,x
	dex
	dex
	bpl bloop
	
	ldx	#4	; now add rest of the header
setmac4	lda configuration+14,x	; set source mac addr
	sta eth_outp+eth_data+ip_data+udp_data+bootp_client_hrd,x
	dex
	dex
	bpl	setmac4
	
	ldx #200	; now add some more zero fill
bloop1 stz eth_outp+eth_data+ip_data+udp_data+bootp_spare,x
	dex
	dex
	bpl bloop1

; finally the dhcp protocl config

	lda	#$8263	; lo bytes dhcp magic cookie
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data
	lda	#$6353	; hi bytes dhcp magic cookie
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+2
	lda	#$0135	; option code = 53 option length = 1
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_opcode
	lda	#$3701	; message type discover = 1 option code = 55
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type
	lda	#$0104	; option length = 4 subnet mask = 1
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_plen
	lda #$0603	; routers = 3 dns = 6
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_plen+2
	lda	#$ff1a	; mtu = 26 end marker = $ff
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_plen+4
	
	ldx #48	; now add some more zero fill
bloop2 stz eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_plen+6,x
	dex
	dex
	bpl bloop2

	ldx	#16	; clear out some of the return values before we start
clear anop
	stz	tmp_dns,x
	dex
	dex
	bpl	clear
	
dhcp_discover anop

	dec	packettries	; have we tried too many
	bmi	dhcp_exit

	lda	#342	; packet length
	sta	eth_outp_len
	
	jsr	eth_tx	; send the packet out
	
; now look for a suitable return packet, ignoring all others

look_for_more anop

	ldx	cs_slot_offset

	lda	#$0124		; check rx status
	sta	>cs_packet_page,x

	lda	>cs_packet_data,x
	and	#$0d00
	bne	cont_dhcp

see_timeout anop

	jsr	timer_read2	; read current timer value
	cmp	dhcptimeout	; are we timed out
	bcs	dhcp_exit
	sec
	sbc dhcpwait
	cmp	#3	;	3 seconds seems about right for retry
	bcc	look_for_more
	jsr	timer_read2	; read current timer value
	sta dhcpwait
	bra	dhcp_discover	; send it again

dhcp_exit anop	; failed to negotiate
	sec
	rts

cont_dhcp	anop

	shortm
	
 	lda	>cs_rxtx_data+1,x	; ignore status
 	lda	>cs_rxtx_data,x

 	lda	>cs_rxtx_data+1,x	; read packet length
	sta	eth_inp_len+1
 	lda	>cs_rxtx_data,x	; read packet length
	sta	eth_inp_len

	longm
	
	lda	eth_inp_len	; if too big, flush and ignore packet
	cmp	#1519	; the size of our buffer+1
	bcc	get_packet2

	ldy	#0
flush2	anop
	lda	>cs_rxtx_data,x	; flush only
	iny
	iny
	cpy	eth_inp_len
	bcc	flush2
	bra	look_for_more

get_packet2 anop	

	lda	#eth_inp	; set packet pointer
	sta	eth_packet

	ldy	#0
get1 anop
	lda	>cs_rxtx_data,x
	sta	(eth_packet),y
	iny
	iny
	cpy	eth_inp_len
	bcc	get1
	
	ldx	#4
chkadr1	lda	eth_inp,x	; check if it is for my mac address
	cmp	configuration+14,x
	bne	look_for_general
	dex
	dex
	bpl	chkadr1
	bra	rest_pack

look_for_general anop

	ldx	#4
chkadr2	lda	eth_inp,x	; check if it is for a generic address
	cmp	#$ffff
	bne	comp_more
	dex
	dex
	bpl	chkadr2

rest_pack anop

	lda	eth_inp+12	; type should be 08xx
	cmp	#8
	bne	comp_more		; not an ip packet so discard it

	lda	eth_inp+eth_data+ip_proto	; should be 0
	and	#$ff
	cmp	#17	; udp protocol
	beq	comp_id
comp_more anop
	brl	look_for_more
	
comp_id anop
	lda	eth_inp+eth_data+ip_data+udp_data+4
	cmp	randomnum
	bne	comp_more		; not our ip packet so discard it
	lda	eth_inp+eth_data+ip_data+udp_data+6
	cmp	randomnum+2
	bne	comp_more		; not our ip packet so discard it

	lda	eth_inp+eth_data+ip_data+udp_data+bootp_ipclient	; the allocated ip address
	sta	tmp_ip
	lda	eth_inp+eth_data+ip_data+udp_data+bootp_ipclient+2	
	sta	tmp_ip+2
	
	ldx	#4
chkadr3	lda eth_inp+eth_data+ip_data+udp_data+bootp_client_hrd,x	; check if it is for my mac address
	cmp	configuration+14,x
	bne	comp_more
	dex
	dex
	bpl	chkadr3
	
	ldx	#eth_data+ip_data
magicsearch anop	; look for magic cookie $8263 lo $6353 hi
	lda	eth_inp,x
	cmp	#magiccookielo
	beq magicmore
nextbyte anop
	inx
	cpx	eth_inp_len
	bcc magicsearch
	brl	look_for_more
magicmore anop
	lda	eth_inp+2,x
	cmp	#magiccookiehi
	bne	nextbyte
	inx
	inx
	inx
	inx		; we now have the offset into the responses
	
	ldy	#4
getsrvadr lda eth_inp+6,y	; get the mac address of the server
	sta	tmp_src_mac,y
	dey
	dey
	bpl	getsrvadr

	lda	eth_inp+eth_data+ip_src	; get the ip address of the server
	sta	tmp_src_ip
	lda	eth_inp+eth_data+ip_src+2
	sta	tmp_src_ip+2

magicloop anop

	lda	eth_inp+1,x	; save the option length
	and	#$ff
	tay
	lda	eth_inp,x	; now check out the returned options
	inx
	inx
	and	#$ff
	cmp	#53	; is it message type
	bne	ml_1
	lda	eth_inp,x
	and #$ff
	cmp #dhcpoffer	; is it offer = 2
	beq	go_ml_next
	cmp	#dhcppack	; is it ack = 5
	beq	go_ml_next
	cmp	#dhcpnack	; is it nack = 6
	beq	start_over
	brl	look_for_more
start_over anop
	brl	start_again
go_ml_next anop
	sta	dhcp_offer
	brl	ml_next
	
ml_1 anop	
	cmp	#54	; is it server identifier
	bne	ml_2
	lda	eth_inp,x
	sta tmp_server
	lda	eth_inp+2,x
	sta	tmp_server+2
	bra	ml_next

ml_2 anop	
	cmp	#51	; is it ip lease time
	bne	ml_3
	lda	eth_inp,x
	sta tmp_lease
	lda	eth_inp+2,x
	sta	tmp_lease+2
	bra	ml_next
	
ml_3 anop	
	cmp	#1	; is it subnet mask
	bne	ml_4
	lda	eth_inp,x
	sta tmp_netmask
	lda	eth_inp+2,x
	sta	tmp_netmask+2
	bra	ml_next

ml_4 anop	
	cmp	#3	; is it router address
	bne	ml_5
	lda	eth_inp,x
	sta tmp_gateway
	lda	eth_inp+2,x
	sta	tmp_gateway+2
	bra	ml_next

ml_5 anop	
	cmp	#6	; is it dns server
	bne	ml_6
	lda	eth_inp,x
	sta tmp_dns
	lda	eth_inp+2,x
	sta	tmp_dns+2
	cpy	#8
	bne	ml_next
	lda	eth_inp+4,x
	sta tmp_dns2
	lda	eth_inp+6,x
	sta	tmp_dns2+2
	bra	ml_next

ml_6 anop
	cmp	#26	; is it mtu size
	bne	ml_7
	lda	eth_inp,x
         xba
	sta tmp_mtu
	bra	ml_next

ml_7 anop
	cmp	#$ff	; is it option end marker
	beq	next_request
	
ml_next anop	; strip this option code so we can look for the next one
	inx
	dey
	bne	ml_next
	cpx	eth_inp_len
	bcc	go_magicloop
	brl	look_for_more
go_magicloop anop
	brl	magicloop

next_request anop

	lda	dhcp_offer
	cmp	#dhcppack	; is it acknowledged
	bne	build_next
	clc
	rts	; we have dhcp negotiated
	
build_next anop	; build the request packet

	lda	#$0200 ; identifier = 0002	; request
	sta	eth_outp+eth_data+ip_id
	
	stz	eth_outp+eth_data+ip_header_cksum	; zero checksum for now
	stz	eth_outp+eth_data+ip_src	; this should be our ip address
	stz	eth_outp+eth_data+ip_src+2
	
	ldx	#0	; calculate ip header checksum
	stz	chktemp
	clc
chck1 lda eth_outp+eth_data,x
	xba
	adc	chktemp
	adc	#0	; make sure we catch any overflow
	sta chktemp
	inx
	inx
	cpx	#20
	bcc chck1
	lda chktemp
	eor #$ffff	; invert
	xba
	sta eth_outp+eth_data+ip_header_cksum	; add checksum to packet

	lda	#$3703	; message type request = 3 option code = 55
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type
	lda	#$0239	; option code = 57 option length 2
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+7
	lda	#$b405	; mtu lo = <1500 mtu hi = >1500
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+9
	lda	#$0436	; option code = 54 option length = 4
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+11
	lda tmp_server	; the server address
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+13
	lda tmp_server+2	; the server address
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+15
	lda	#$0432	; option code = 50 length = 4
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+17
	lda	tmp_ip	; our allocated address
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+19
	lda	tmp_ip+2	; our allocated address
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+21
	lda	#$00ff	; end code
	sta eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+23
	
	ldx #43	; now add some more zero fill
bloop3 stz eth_outp+eth_data+ip_data+udp_data+bootp_data+dhcp_type+25,x
	dex
	dex
	bpl bloop3

	brl	dhcp_discover

randomnum ds 4
chktemp ds 2
packettries ds 2
dhcptimeout ds 2
dhcpwait ds 2
dhcp_offer ds 2

*-------------------------------------------------
* script display routines
*-------------------------------------------------

showpstring anop
	phy
	tax
	lda	>displayptr+1
	ora	>displayptr+1+1
	beq	plyrtl
	pea	*|-16
	phx
displayptr anop
	jsl	displayptr
plyrtl	ply
	rts


*-------------------------------------------------
* variables
*-------------------------------------------------

variables anop
	mds	lvlen

*-------------------------------------------------
* common sub routines
*-------------------------------------------------

; ethernet driver for cs8900a
; based on doc bacardi's tftp source

; send a packet

eth_tx 	anop

	jsr	timer_read	; read current timer value
	clc
	adc	#0300	; set timeout to now+5000 ms
	sta	packettimeout

	ldx	cs_slot_offset
	lda	#$00c9			; ask for buffer space
	sta	>cs_tx_cmd,x

	lda	eth_outp_len		; set length
	sta	>cs_tx_len,x
	and	#$f800
	beq	cont_tx
	sec				; oversized packet
	rts
	
cont_tx	anop

	lda	#pp_bus_status		; select bus status register
	sta	>cs_packet_page,x
	
check anop

	shortm
	lda	>cs_packet_data+1,x		; wait for space
	pha
	lda	>cs_packet_data,x
	pla
	lsr	a
	bcs	checked
	longm
	jsr	timer_read	; read current timer value
	cmp	packettimeout
	bcc	check
	rts
	
checked anop

	longm
	lda	#eth_outp
	sta	eth_packet
	
	ldy	#0

send	anop
	lda	(eth_packet),y
	sta	>cs_rxtx_data,x
	iny
	iny
	cpy	eth_outp_len
	bcc	send

	clc    
	rts


; adds first six bytes of ethernet header
maketheheader anop

	ldx	#4
	lda	#$ffff
setbrd	sta	eth_outp,x
	dex
	dex
	bpl	setbrd
	
	rts

; adds proto = arp, hw = eth, and proto = ip to outgoing packet
makearppacket anop

	lda	#$0608	; eth_proto_arp = hi 08 - lo
	sta	eth_outp+eth_type

	lda	#$0100		; set hw type (eth = 0001)
	sta	eth_outp+ap_hw

	lda	#$0008		; set protcol (ip = 0800)
	sta	eth_outp+ap_proto

	lda	#$0406		;  set proto addr len (eth = 04) = hi set hw addr len (eth = 06) = lo
	sta	eth_outp+ap_hwlen
	
	rts


; timer routines (original comments)
;
; the  should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate,
; if you're working with e.g. a 60 hz vblank irq, adding 17 to the
; counter every frame would be just fine.
; code mofied to work with 1/60 of a second


; return the current value
timer_read	anop

	pha
	pha
	_tickcount
	pulllong tick_count_cur
; how many ticks have tocked since the last tick did tock
	sub4 	tick_count_cur,tick_count_start,tick_temp
	lda	tick_temp
; more than 60 (1 second)
	cmp	#60
	bcc	ret
	add4 	#tick_count_start,60
	sub4    #tick_temp,60
	lda 	tick_temp
ret	anop
	rts
	
; we can't use tickcount during dhcp negotiation, as the event manager has not yet been started
; but we can use the clock, with some more elaborate code...
; return current elapsed time in seconds, accounting for midnight rollover
; we are not going to be more than 60 seconds in here, so we will not span two days!
timer_read2	anop

	pha
	pha
	pha
	pha
	_readtimehex
	pla	; read mins and secs
	sta	tick_temp
	pla	; read hour and year
	sta	tick_temp+2
	plx	; throw dates
	plx	; throw dates
	and	#$ff	; hours
	asl	a
	asl	a
	sta	tick_temp+4
	asl	a
	asl	a
	asl	a
	asl	a
	sec
	sbc	tick_temp+4
	sta	timer	; we have minutes
	lda	tick_temp+1	; mins
	and	#$ff
	asl	a
	asl	a
	sta	tick_temp+4
	asl	a
	asl	a
	asl	a
	asl	a
	sec
	sbc	tick_temp+4
	clc
	adc timer
	sta	timer	; we have seconds
	lda	timer+2
	adc	#$00
	sta	timer+2
	lda	tick_temp
	and	#$ff
	clc
	adc	timer
	sta	timer	; total current seconds since midnight
	lda	timer+2
	adc	#$00
	sta	timer+2
	
tr_loop anop
	sec
	lda	timer
	sbc	start_time
	tax
	lda	timer+2
	sbc	start_time+2
	bpl tr_exit
	clc
	lda	timer
	adc	#<86400	; seconds in a day
	sta	timer
	lda	timer+2
	adc	#>86400
	sta	timer+2
	bra	tr_loop	
tr_exit anop
	txa
	rts	

tick_count_cur	ds 4		; .res 2
tick_count_start ds 4
tick_temp	ds 6
time		ds 2		; .res 2
timer		ds 4
start_time  dc i4'0'

*-------------------------------------------------
* csconfigure
*-------------------------------------------------

; open a user interface dialog box

csconfigure anop

	phb
	phk
	plb

	lda 9+2,s
	sta cfghandle+2
	lda 9,s
	sta cfghandle
	ldy #8
	lda [cfghandle],y
	iny
	iny
	ora [cfghandle],y
	beq	zerolen
	lda	[cfghandle]	; use the handle to get the address of the config area
	sta	cfgptr
	ldy	#2
	lda	[cfghandle],y
	sta	cfgptr+2
	lda	[cfgptr]	; test first word should match the config version
	cmp #cfgvers	;check version
	beq versok

zerolen anop

	pushlong #cfglen
	pushlong cfghandle
	_sethandlesize	; set empty handle to size of our data
	
	pushlong #defaultcfg
	pushlong cfghandle
	pushlong #cfglen
	_ptrtohand	; copy our default data over

versok anop

	lda	[cfghandle]	; use the handle to get the address of the config area
	sta	cfgptr
	ldy	#2
	lda	[cfghandle],y
	sta	cfgptr+2

; get the slot number and dhcp setting

	ldy #20			; slot number
	lda [cfgptr],y
	ora	#$0100	; menu id offset
	sta	popupid

	ldy #22			; dhcp flag
	lda [cfgptr],y
	sta	dhcp_val

	pha
	pha
	_getport

	stz	egg_mark

	ldx	#15
clear_loop anop	; flush the buffer
	stz	work_buffer,x
	dex
	dex
	bpl	clear_loop

	pea	0
	pushlong csversion
	pushlong #work_buffer
	_versionstring
	
	shortmx
	ldx #8
	txy
copyvers anop
	lda	work_buffer+1,x
	beq	skipchar
	sta	version_str+1,y
	dey
skipchar anop
	dex
	bpl	copyvers
	lda	#118	; 'v'
	sta	version_str+1,y
	longmx
	
; open up the dialog window

	pha
	pha
	pea	0
	pea	0
	pea	0
	pea	1
	pea	0
	pea	0
	pea	0
	pea	0
	pea	0
	pushlong #window
	pea	$800e
	_newwindow2	; open a dialog
	pulllong ourwindow
	
	pushlong ourwindow	
	_setport
	
	pushlong cfghandle
	_hlock

	lda	[cfghandle]	; use the handle to get the address of the config area
	sta	cfgptr
	ldy	#2
	lda	[cfghandle],y
	sta	cfgptr+2
	
; now set the strings for the three ip addresss

	pha
	ldy #4			; ipaddress hi
	lda [cfgptr],y
	pha
	dey
	dey
	lda [cfgptr],y	; ipaddress lo
	pha
	pushlong #work_buffer
	pea 0
	_tcpipconvertiptoascii
	pla
	pushlong ourwindow
	pushlong #$a	; ip address control
	pushlong #work_buffer
	_setletextbyid
	
	pha
	ldy #8	; netmask hi
	lda [cfgptr],y
	pha
	dey
	dey
	lda [cfgptr],y	; netmask lo
	pha
	pushlong #work_buffer
	pea 0
	_tcpipconvertiptoascii
	pla
	pushlong ourwindow
	pushlong #$b	; netmask control
	pushlong #work_buffer
	_setletextbyid
	
	pha
	ldy #12	; gateway hi
	lda [cfgptr],y
	pha
	dey
	dey
	lda [cfgptr],y	; gateway lo
	pha
	pushlong #work_buffer
	pea 0
	_tcpipconvertiptoascii
	pla
	pushlong ourwindow
	pushlong #$c	; gateway control
	pushlong #work_buffer
	_setletextbyid
	
; set the mac lsb string
	
	ldy #19	; mac lsb the value is shown in hex
	lda [cfgptr],y
	and	#$ff
	pha
	ldx	#1
	cmp	#10
	bcc	shortnum
	inx
	cmp	#100
	bcc	shortnum
	inx
shortnum anop
	stx	work_buffer
	pushlong #work_buffer+1
	phx
	pea	0
	_int2dec
	pushlong ourwindow
	pushlong #$d	; mac lsb
	pushlong #work_buffer
	_setletextbyid

; set the mtu value

	ldy #28			; mtu value
	lda [cfgptr],y
	pha
	pushlong #pstr_00000114+1
	pea	4
	pea	0
	_int2dec
	pushlong ourwindow
	pushlong mtu_id
	pushlong #pstr_00000114
	_setletextbyid

	pushlong cfghandle
	_hunlock

modalloop	anop	; interface with taskmaster

	pha
	pha
	pushlong #eventrecord
	pea	0
	pea	0
	pushlong #$80000000	;event hook
	pea	0	;beep procedure
	pea	0
	pea	$0008
	_domodalwindow
	pla
	plx

	cmp	#0
	beq	modalloop
	cmp	cancel_id	; cancel button
	bne	checkegg
	brl	configexit
	
checkegg anop	; lets have some fun

	cmp	egg3_id
	beq	hide_egg
	cmp	egg1_id
	beq	hide_egg
	cmp	egg_id
	beq	letsscramble
	brl	checkegg2

letsscramble anop

	lda	egg_mark
	beq	draw_egg

hide_egg	anop

	pha
	pha
	pushlong ourwindow
	pushlong #19
	_getctlhandlefromid
	_hidecontrol

	pha
	pha
	pushlong ourwindow
	pushlong #20
	_getctlhandlefromid
	_hidecontrol

	pha
	pha
	pushlong ourwindow
	pushlong #1
	_getctlhandlefromid
	_showcontrol
	
	stz	egg_mark
	brl	modalloop
	
draw_egg anop

	pha
	pha
	pushlong ourwindow
	pushlong #1
	_getctlhandlefromid
	_hidecontrol
	
	pha
	pha
	pushlong ourwindow
	pushlong #20
	_getctlhandlefromid
	_hidecontrol

	pha
	pha
	pushlong ourwindow
	pushlong #19
	_getctlhandlefromid
	_showcontrol
	
	inc	egg_mark
	brl	modalloop
	
checkegg2	anop

	cmp	egg2_id
	beq	letsscramble2
	brl	checksave
	
letsscramble2	anop

	lda	egg_mark
	beq	draw_egg2
	brl	hide_egg
	
draw_egg2 anop

	pha
	pha
	pushlong ourwindow
	pushlong #1
	_getctlhandlefromid
	_hidecontrol
	
	pha
	pha
	pushlong ourwindow
	pushlong #19
	_getctlhandlefromid
	_hidecontrol

	pha
	pha
	pushlong ourwindow
	pushlong #20
	_getctlhandlefromid
	_showcontrol
	
	inc	egg_mark
	brl	modalloop

checksave anop	; see if we need to save and exit

	cmp	save_id
	beq	letsgo
	brl	modalloop
	
letsgo	anop
	
	pushlong cfghandle
	_hlock

	lda	[cfghandle]	; use the handle to get the address of the config area
	sta	cfgptr
	ldy	#2
	lda	[cfghandle],y
	sta	cfgptr+2
	
; now get back and store the returned values

	pushlong ourwindow
	pushlong mtu_id
	pushlong #work_buffer
	_getletextbyid

	pha
	pushlong #work_buffer+1
	pea	4
	pea	0
	_dec2int
	pla
	cmp	#300
	bcc	mtu_bad
	cmp	#1601
	bcc mtu_ok
mtu_bad anop
	brl	show_alert
mtu_ok anop
	ldy	#28
	sta	configuration+28
	sta variables+lvmtu
	sta [cfgptr],y
		
	pha
	pha
	pha
	pushlong ourwindow
	pushlong #9	; menu popup id
	_getctlhandlefromid
	_getctlvalue
	pla
	and	#$ff
	ldy #20			; slot number
	sta [cfgptr],y
	
	pha
	pha
	pha
	pushlong ourwindow
	pushlong #$e	; dhcp checkbox
	_getctlhandlefromid
	_getctlvalue
	pla
	ldy #22			; dhcp flag
	sta [cfgptr],y
	cmp	#0
	beq	non_dhcp
	brl	dhcp_ok

non_dhcp anop

	pushlong ourwindow
	pushlong #$a	; ip address control id
	pushlong #work_buffer
	_getletextbyid
	pha
	pushlong #work_buffer
	_tcpipvalidateipstring
	pla
	bne	ip_ok
	brl	show_alert
ip_ok anop
	pushlong #response_buffer
	pushlong #work_buffer
	_tcpipconvertiptohex
	ldy #2	; ip address
	lda response_buffer
	sta [cfgptr],y
	iny
	iny
	lda response_buffer+2
	sta [cfgptr],y
	
	pushlong ourwindow
	pushlong #$b	; netmask control id
	pushlong #work_buffer
	_getletextbyid
	pha
	pushlong #work_buffer
	_tcpipvalidateipstring
	pla
	bne	netm_ok
	brl	show_alert
netm_ok anop
	pushlong #response_buffer
	pushlong #work_buffer
	_tcpipconvertiptohex
	ldy #6	; netmask
	lda response_buffer
	sta [cfgptr],y
	iny
	iny
	lda response_buffer+2
	sta [cfgptr],y
	
	pushlong ourwindow
	pushlong #$c	; gateway control id
	pushlong #work_buffer
	_getletextbyid
	pha
	pushlong #work_buffer
	_tcpipvalidateipstring
	pla
	bne	gate_ok
	brl	show_alert
gate_ok anop
	pushlong #response_buffer
	pushlong #work_buffer
	_tcpipconvertiptohex
	ldy #10	; gateway
	lda response_buffer
	sta [cfgptr],y
	iny
	iny
	lda response_buffer+2
	sta [cfgptr],y

dhcp_ok anop
	
	pushlong ourwindow
	pushlong #$d	; mac lsb control id
	pushlong #work_buffer
	_getletextbyid
	lda	work_buffer
	and	#$ff
	beq	bad_value
	tax
	pha
	pushlong #work_buffer+1
	phx
	pea	0
	_dec2int
	pla
	bcc	mac_ok
bad_value anop
	brl	show_alert
mac_ok	anop
	cmp	#256
	bcs	bad_value
	ldy #19	; mac lsb
	shortm
	sta [cfgptr],y
	longm

configexit anop
	
	stz	egg_mark

	pushlong ourwindow
	_closewindow
	_setport
	
	pushlong cfghandle
	_hunlock

	pla
	sta	7,s
	pla
	sta	7,s
	pla
	pla
	plb
	rtl
	
show_alert anop

	pha
	pea   $0051
	pea	0
	pea	0
	pushlong #alertstr
	_alertwindow	; warn that an invalid string was entered
	pla

	brl	modalloop
	
*****************************************************************
* genesys created asm65816 data structures
* simple software systems international, inc.
* orcam.scg 1.2
*
*
* control list definitions
*

controllist anop
           dc i4'ctltmp_00000001' ; control 1
           dc i4'ctltmp_00000002' ; control 2
           dc i4'ctltmp_00000003' ; control 3
           dc i4'ctltmp_00000004' ; control 4
           dc i4'ctltmp_00000005' ; control 5
           dc i4'ctltmp_00000006' ; control 6
           dc i4'ctltmp_00000007' ; control 7
           dc i4'ctltmp_00000008' ; control 8
           dc i4'ctltmp_00000009' ; control 9
           dc i4'ctltmp_00000016' ; control 10
           dc i4'ctltmp_0000000d' ; control 11
           dc i4'ctltmp_0000000c' ; control 12
           dc i4'ctltmp_0000000b' ; control 13
           dc i4'ctltmp_0000000a' ; control 14
           dc i4'ctltmp_0000000e' ; control 15
           dc i4'ctltmp_0000000f' ; control 16
           dc i4'ctltmp_00000010' ; control 17
           dc i4'ctltmp_00000011' ; control 18
           dc i4'ctltmp_00000012' ; control 19
           dc i4'ctltmp_00000013' ; control 20
           dc i4'ctltmp_00000014' ; control 21
           dc i4'ctltmp_00000015' ; control 22
           dc i4'0' ; end of control list
*
* control templates
*

ctltmp_00000001 anop	; uthernet title
           dc i2'9' ; pcount
egg2_id    dc i4'$1' ; id (1)
           dc i2'5,12,15,291' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000001' ; text reference
           dc i2'letxtbox_00000001_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000002 anop	; version number
           dc i2'9' ; pcount
           dc i4'$2' ; id (2)
           dc i2'5,292,15,369' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000002' ; text reference
           dc i2'letxtbox_00000002_cnt' ; text size
           dc i2'-1' ; justification

ctltmp_00000003 anop	; lan slot
           dc i2'9' ; pcount
           dc i4'$3' ; id (3)
           dc i2'26,12,36,83' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000003' ; text reference
           dc i2'letxtbox_00000003_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000004 anop	; ip address
           dc i2'9' ; pcount
           dc i4'$4' ; id (4)
           dc i2'42,12,52,95' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000004' ; text reference
           dc i2'letxtbox_00000004_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000005 anop	; netmask
           dc i2'9' ; pcount
           dc i4'$5' ; id (5)
           dc i2'58,12,68,81' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000005' ; text reference
           dc i2'letxtbox_00000005_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000006 anop	; gateway
           dc i2'9' ; pcount
           dc i4'$6' ; id (6)
           dc i2'74,12,85,81' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000006' ; text reference
           dc i2'letxtbox_00000006_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000007 anop	; mac address (lsb only)
           dc i2'9' ; pcount
           dc i4'$7' ; id (7)
           dc i2'90,12,101,191' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000007' ; text reference
           dc i2'letxtbox_00000007_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000008 anop	; dhcp
           dc i2'9' ; pcount
           dc i4'$8' ; id (8)
           dc i2'26,176,37,215' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000008' ; text reference
           dc i2'letxtbox_00000008_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000009 anop	; slot popup menu
           dc i2'10' ; pcount
           dc i4'$9' ; id (9)
           dc i2'25,96,0,0' ; rect
           dc i4'$87000000' ; popup
           dc i2'$0050' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i2'0' ; title width
           dc i4'menu_00000001' ; menu ref
popupid	   dc i2'$101' ; initial value
           dc i4'0' ; no ctlcolortable

ctltmp_0000000a anop	; ip address edit box
           dc i2'8' ; pcount
ipaddress_id dc i4'$a' ; id (10)
           dc i2'41,128,54,250' ; rect
           dc i4'$83000000' ; line edit
           dc i2'$0000' ; flag
           dc i2'$7000' ; moreflags
           dc i4'0' ; refcon
           dc i2'15' ; max size
           dc i4'pstr_0000010d' ; default

ctltmp_0000000b anop	; netmask edit box
           dc i2'8' ; pcount
netmask_id dc i4'$b' ; id (11)
           dc i2'57,128,70,250' ; rect
           dc i4'$83000000' ; line edit
           dc i2'$0000' ; flag
           dc i2'$7000' ; moreflags
           dc i4'0' ; refcon
           dc i2'15' ; max size
           dc i4'pstr_0000010e' ; default

ctltmp_0000000c anop	; gateway edit box
           dc i2'8' ; pcount
gateway_id dc i4'$c' ; id (12)
           dc i2'73,128,86,250' ; rect
           dc i4'$83000000' ; line edit
           dc i2'$0000' ; flag
           dc i2'$7000' ; moreflags
           dc i4'0' ; refcon
           dc i2'15' ; max size
           dc i4'pstr_0000010f' ; default

ctltmp_0000000d anop	; mac lsb edit box
           dc i2'8' ; pcount
macaddress_id dc i4'$d' ; id (13)
           dc i2'89,212,102,250' ; rect
           dc i4'$83000000' ; line edit
           dc i2'$0000' ; flag
           dc i2'$7000' ; moreflags
           dc i4'0' ; refcon
           dc i2'3' ; max size
           dc i4'pstr_00000110' ; default

ctltmp_0000000e anop	; dhcp checkbox
           dc i2'8' ; pcount
dhcp_id    dc i4'$e' ; id (14)
           dc i2'25,226,36,250' ; rect
           dc i4'$82000000' ; check control
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'pstr_00000111' ; title
dhcp_val   dc i2'0' ; initial value

ctltmp_0000000f anop	; cancel button
           dc i2'9' ; pcount
cancel_id  dc i4'$f' ; id (15)
           dc i2'89,274,102,364' ; rect
           dc i4'$80000000' ; simple button
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'pstr_00000112' ; title
           dc i4'0' ; no ctlcolortable
           dc h'1b1b',i2'$0000,$0000' ; keyequivalent

ctltmp_00000010 anop	; save button
           dc i2'9' ; pcount
save_id    dc i4'$10' ; id (16)
           dc i2'69,274,82,364' ; rect
           dc i4'$80000000' ; simple button
           dc i2'$0001' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'pstr_00000113' ; title
           dc i4'0' ; no ctlcolortable
           dc h'0d0d',i2'$0000,$0000' ; keyequivalent

ctltmp_00000011 anop	; egg box
           dc i2'9' ; pcount
egg_id     dc i4'$11' ; id (17)
           dc i2'106,2,111,11' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000009' ; text reference
           dc i2'letxtbox_00000009_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000012 anop	; divider line
           dc i2'6' ; pcount
           dc i4'$12' ; id (18)
           dc i2'16,14,17,368' ; rect
           dc i4'$87ff0003' ; rectangle
           dc i2'$0002' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           
ctltmp_00000013 anop	; egg static text
           dc i2'9' ; pcount
egg1_id    dc i4'$13' ; id (19)
           dc i2'5,12,15,291' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0080' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000013' ; text reference
           dc i2'letxtbox_00000013_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000014 anop	; egg 2 static text
           dc i2'9' ; pcount
egg3_id    dc i4'$14' ; id (20)
           dc i2'5,12,15,291' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0080' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000014' ; text reference
           dc i2'letxtbox_00000014_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000015 anop	; mtu value
           dc i2'9' ; pcount
           dc i4'$15' ; id (21)
           dc i2'26,272,36,308' ; rect
           dc i4'$81000000' ; static text
           dc i2'$0000' ; flag
           dc i2'$1000' ; moreflags
           dc i4'0' ; refcon
           dc i4'letxtbox_00000015' ; text reference
           dc i2'letxtbox_00000015_cnt' ; text size
           dc i2'0' ; justification

ctltmp_00000016 anop	; mtu edit box
           dc i2'8' ; pcount
mtu_id 	   dc i4'$16' ; id (22)
           dc i2'25,310,36,354' ; rect
           dc i4'$83000000' ; line edit
           dc i2'$0000' ; flag
           dc i2'$7000' ; moreflags
           dc i4'0' ; refcon
           dc i2'4' ; max size
           dc i4'pstr_00000114' ; default

pstr_00000001 anop
           dc i1'0,$00'

pstr_00000106 anop
           dc i1'1',c'1'

pstr_00000107 anop
           dc i1'1',c'2'

pstr_00000108 anop
           dc i1'1',c'3'

pstr_00000109 anop
           dc i1'1',c'4'

pstr_0000010a anop
           dc i1'1',c'5'

pstr_0000010b anop
           dc i1'1',c'6'

pstr_0000010c anop
           dc i1'1',c'7'

pstr_0000010d anop
           dc i1'0,$31'

pstr_0000010e anop
           dc i1'0,$31'

pstr_0000010f anop
           dc i1'0,$31'

pstr_00000110 anop
           dc i1'0,$31'

pstr_00000111 anop
           dc i1'0,$06'

pstr_00000112 anop
           dc i1'6',c'Cancel'

pstr_00000113 anop
           dc i1'4',c'Save'

pstr_00000114 anop
           dc i1'4',c'1460'

alertstr   dc	c'14/Invalid value entered!/^#4',i1'0'	


*
* menu definitions
*

menu_00000001 anop
           dc i2'0' ; menu template version
           dc i2'1' ; menu id
           dc i2'$0000' ; menu flag
           dc i4'pstr_00000001' ; title
           dc i4'menuitem_00000106' ; menu 1
           dc i4'menuitem_00000107' ; menu 2
           dc i4'menuitem_00000108' ; menu 3
           dc i4'menuitem_00000109' ; menu 4
           dc i4'menuitem_0000010a' ; menu 5
           dc i4'menuitem_0000010b' ; menu 6
           dc i4'menuitem_0000010c' ; menu 7
           dc i4'0' ; end of menuitem list
*
* menu item definition
*

menuitem_00000106 anop
           dc i2'0' ; menuitem template version
           dc i2'$101' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_00000106' ; menu

menuitem_00000107 anop
           dc i2'0' ; menuitem template version
           dc i2'$102' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_00000107' ; menu

menuitem_00000108 anop
           dc i2'0' ; menuitem template version
           dc i2'$103' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_00000108' ; menu

menuitem_00000109 anop
           dc i2'0' ; menuitem template version
           dc i2'$104' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_00000109' ; menu

menuitem_0000010a anop
           dc i2'0' ; menuitem template version
           dc i2'$105' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_0000010a' ; menu

menuitem_0000010b anop
           dc i2'0' ; menuitem template version
           dc i2'$106' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_0000010b' ; menu

menuitem_0000010c anop
           dc i2'0' ; menuitem template version
           dc i2'$107' ; menuitem id
           dc h'00' ; alternate characters
           dc h'00'
           dc h'0000' ; check character
           dc i2'$0000' ; menubar flag
           dc i4'pstr_0000010c' ; menu

letxtbox_00000001 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'Uthernet'

letxtbox_00000001_cnt gequ 34

letxtbox_00000002 anop
           dc i1'$01',c'J',i1'$ff,$ff,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
version_str dc c'          '

letxtbox_00000002_cnt gequ 36

letxtbox_00000003 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'LAN Slot:'

letxtbox_00000003_cnt gequ 35

letxtbox_00000004 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'IP Address:'

letxtbox_00000004_cnt gequ 37

letxtbox_00000005 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'Netmask:'

letxtbox_00000005_cnt gequ 34

letxtbox_00000006 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'Gateway:'

letxtbox_00000006_cnt gequ 34

letxtbox_00000007 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'MAC Address (LSB only):'

letxtbox_00000007_cnt gequ 49

letxtbox_00000008 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'DHCP:'

letxtbox_00000008_cnt gequ 31

letxtbox_00000009 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'

letxtbox_00000009_cnt gequ 26

letxtbox_00000013 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'King Uther Pendragon (c.AD 410-495)'

letxtbox_00000013_cnt gequ 61

letxtbox_00000014 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'Happy 30th birthday to Apple!'

letxtbox_00000014_cnt gequ 55

letxtbox_00000015 anop
           dc i1'$01',c'J',i1'$00,$00,$01',c'L'
           dc i1'$00,$00,$01',c'R',i1'$04,$00,$01'
           dc c'F',i1'$fe,$ff,$00,$08,$01',c'C'
           dc i1'$00,$00,$01',c'B',i1'$ff,$ff'
           dc c'MTU:'

letxtbox_00000015_cnt gequ 30

*
* window definition
*

window anop
           dc i2'$50' ; template size
           dc i2'$20a0' ; frame bits
           dc i4'0' ; no title
           dc i4'0' ; window refcon
           dc i2'0,0,0,0' ; zoom rectangle
           dc i4'0' ; standard colors
           dc i2'0,0' ; origin y/x
           dc i2'0,0' ; data height/width
           dc i2'0,0' ; max height/width
           dc i2'0,0' ; scroll vert/horiz
           dc i2'0,0' ; page vert/horiz
           dc i4'0' ; info refcon
           dc i2'0' ; info height
           dc i4'0' ; frame defproc
           dc i4'0' ; info defproc
           dc i4'0' ; content defproc
           dc i2'50,128,162,510' ; position
           dc i4'-1' ; plane
           dc i4'controllist' ; control reference
           dc i2'3' ; indescref

oldport	ds	4
ourwindow	ds 4
egg_mark	dc i2'0'
work_buffer ds 17
response_buffer ds 4

eventrecord    anop
eventwhat      ds 2
eventmessage   ds 4
eventwhen      ds 4
eventwhere     ds 4
eventmodifiers ds 2
taskdata       ds 4
taskmask       dc i4'$001fffef'
lastclicktick  ds 4
clickcount     ds 2
taskdata2      ds 4
taskdata3      ds 4
taskdata4      ds 4
lastclickpoint ds 4

	end			; yes it's really the end now
