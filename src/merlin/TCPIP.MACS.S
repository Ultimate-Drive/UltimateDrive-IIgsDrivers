*=================================================
*
* TCPIP.MACS.S - Developer macros for Marinetti
*
* Copyright (C) 1997-2003 Richard Bennett-Forrest
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
* 2000.08.12 RJB Initial release as open source
* 2003.07.05 AJR Update for Marinetti 3.0
*
*=================================================

]tcpiptoolnum = $36

~TCPIPBootInit MAC
_TCPIPBootInit MAC
 LDX #$0100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPStartUp MAC
_TCPIPStartUp MAC
 LDX #$0200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPShutDown MAC
_TCPIPShutDown MAC
 LDX #$0300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPVersion MAC
 PHA
_TCPIPVersion MAC
 LDX #$0400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPReset MAC
_TCPIPReset MAC
 LDX #$0500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPStatus MAC
 PHA
_TCPIPStatus MAC
 LDX #$0600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPLongVersion MAC
 PHS 2
_TCPIPLongVersion MAC
 LDX #$0800+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetConnectStatus MAC
 PHA
_TCPIPGetConnectStatus MAC
 LDX #$0900+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetErrorTable MAC
 PHS 2
_TCPIPGetErrorTable MAC
 LDX #$0A00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetReconnectStatus MAC
 PHA
_TCPIPGetReconnectStatus MAC
 LDX #$0B00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPReconnect MAC
 PHL ]1
_TCPIPReconnect MAC
 LDX #$0C00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConvertIPToHex MAC
 PxL ]1;]2
_TCPIPConvertIPToHex MAC
 LDX #$0D00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConvertIPCToHex MAC
 PxL ]1;]2
_TCPIPConvertIPCToHex MAC
 LDX #$3F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConvertIPToASCII MAC
 PHA
 PxL ]1;]2
 PHW ]3
_TCPIPConvertIPToASCII MAC
 LDX #$0E00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConvertIPToCASCII MAC
 PHA
 PxL ]1;]2
 PHW ]3
_TCPIPConvertIPToCASCII MAC
 LDX #$5800+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetMyIPAddress MAC
 PHS 2
_TCPIPGetMyIPAddress MAC
 LDX #$0F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetConnectMethod MAC
 PHA
_TCPIPGetConnectMethod MAC
 LDX #$1000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetConnectMethod MAC
 PHW ]1
_TCPIPSetConnectMethod MAC
 LDX #$1100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConnect MAC
 PHL ]1
_TCPIPConnect MAC
 LDX #$1200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPDisconnect MAC
 PHWL ]1;]2
_TCPIPDisconnect MAC
 LDX #$1300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetMTU MAC
 PHA
_TCPIPGetMTU MAC
 LDX #$1400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetConnectData MAC
 PHS 2
 PxW ]1;]2
_TCPIPGetConnectData MAC
 LDX #$1600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetConnectData MAC
 PHWL ]1;]2
_TCPIPSetConnectData MAC
 LDX #$1700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetDisconnectData MAC
 PHS 2
 PxW ]1;]2
_TCPIPGetDisconnectData MAC
 LDX #$1800+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetDisconnectData MAC
 PHWL ]1;]2
_TCPIPSetDisconnectData MAC
 LDX #$1900+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPLoadPreferences MAC
_TCPIPLoadPreferences MAC
 LDX #$1A00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSavePreferences MAC
_TCPIPSavePreferences MAC
 LDX #$1B00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetTuningTable MAC
 PHL ]1
_TCPIPGetTuningTable MAC
 LDX #$1E00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetTuningTable MAC
 PHL ]1
_TCPIPSetTuningTable MAC
 LDX #$1F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetDNS MAC
 PHL ]1
_TCPIPGetDNS MAC
 LDX #$1C00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetDNS MAC
 PHL ]1
_TCPIPSetDNS MAC
 LDX #$1D00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPCancelDNR MAC
 PHL ]1
_TCPIPCancelDNR MAC
 LDX #$2000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPDNRNameToIP MAC
 PxL ]1;]2
_TCPIPDNRNameToIP MAC
 LDX #$2100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPPoll MAC
_TCPIPPoll MAC
 LDX #$2200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPLogin MAC
 PHS
 PHWL ]1;]2
 PxW ]3;]4;]5
_TCPIPLogin MAC
 LDX #$2300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPLogout MAC
 PHW ]1
_TCPIPLogout MAC
 LDX #$2400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSendICMP MAC
 PHW ]1
 PHLW ]2;]3
_TCPIPSendICMP MAC
 LDX #$2500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSendUDP MAC
 PHW ]1
 PHLW ]2;]3
_TCPIPSendUDP MAC
 LDX #$2600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetDatagramCount MAC
 PHA
 PxW ]1;]2
_TCPIPGetDatagramCount MAC
 LDX #$2700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetNextDatagram MAC
 PHS 2
 PxW ]1;]2;]3
_TCPIPGetNextDatagram MAC
 LDX #$2800+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetLoginCount MAC
 PHA
_TCPIPGetLoginCount MAC
 LDX #$2900+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSendICMPEcho MAC
 PxW ]1;]2
_TCPIPSendICMPEcho MAC
 LDX #$2A00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPReceiveICMPEcho MAC
 PHA
 PHW ]1
_TCPIPReceiveICMPEcho MAC
 LDX #$2B00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPOpenTCP MAC
 PHA
 PHW ]1
_TCPIPOpenTCP MAC
 LDX #$2C00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPWriteTCP MAC
 PHA
 PHW ]1
 PxL ]2;]3
 PxW ]4;]5
_TCPIPWriteTCP MAC
 LDX #$2D00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPReadTCP MAC
 PHA
 PxW ]1;]2
 PxL ]3;]4;]5
_TCPIPReadTCP MAC
 LDX #$2E00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPCloseTCP MAC
 PHA
 PHW ]1
_TCPIPCloseTCP MAC
 LDX #$2F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPAbortTCP MAC
 PHA
 PHW ]1
_TCPIPAbortTCP MAC
 LDX #$3000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPStatusTCP MAC
 PHA
 PHWL ]1;]2
_TCPIPStatusTCP MAC
 LDX #$3100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetSourcePort MAC
 PHA
 PHW ]1
_TCPIPGetSourcePort MAC
 LDX #$3200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetTOS MAC
 PHA
 PHW ]1
_TCPIPGetTOS MAC
 LDX #$3300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetTOS MAC
 PxW ]1;]2
_TCPIPSetTOS MAC
 LDX #$3400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetTTL MAC
 PHA
 PHW ]1
_TCPIPGetTTL MAC
 LDX #$3500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetTTL MAC
 PxW ]1;]2
_TCPIPSetTTL MAC
 LDX #$3600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetSourcePort MAC
 PHW ]1;]2
_TCPIPSetSourcePort MAC
 LDX #$3700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSendIPDatagram MAC
 PHL ]1
_TCPIPSendIPDatagram MAC
 LDX #$4000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPConvertIPToClass MAC
 PHS
 PHL ]1
_TCPIPConvertIPToClass MAC
 LDX #$4100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetConnectMsgFlag MAC
 PHS
_TCPIPGetConnectMsgFlag MAC
 LDX #$4200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetConnectMsgFlag MAC
 PHW ]1
_TCPIPSetConnectMsgFlag MAC
 LDX #$4300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetUsername MAC
 PHL ]1
_TCPIPGetUsername MAC
 LDX #$4400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetUsername MAC
 PHL ]1
_TCPIPSetUsername MAC
 LDX #$4500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetPassword MAC
 PHL ]1
_TCPIPGetPassword MAC
 LDX #$4600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetPassword MAC
 PHL ]1
_TCPIPSetPassword MAC
 LDX #$4700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPValidateIPString MAC
 PHS
 PHL ]1
_TCPIPValidateIPString MAC
 LDX #$4800+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPValidateIPCString MAC
 PHS
 PHL ]1
_TCPIPValidateIPCString MAC
 LDX #$1500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetUserStatistic MAC
 PHS 2
 PxW ]1;]2
_TCPIPGetUserStatistic MAC
 LDX #$4900+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetLinkVariables MAC
 PHS 2
_TCPIPGetLinkVariables MAC
 LDX #$4A00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPEditLinkConfig MAC
 PxL ]1;]2
_TCPIPEditLinkConfig MAC
 LDX #$4B00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetModuleNames MAC
 PHS 2
_TCPIPGetModuleNames MAC
 LDX #$4C00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPListenTCP MAC
 PHA
 PHW ]1
_TCPIPListenTCP MAC
 LDX #$4E00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPAcceptTCP MAC
 PHA
 PxW ]1;]2
_TCPIPAcceptTCP MAC
 LDX #$4F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetNewDestination MAC
 PHWL ]1;]2
 PHW ]3
_TCPIPSetNewDestination MAC
 LDX #$5000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetHostName MAC
 PHL ]1
_TCPIPGetHostName MAC
 LDX #$5100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetHostName MAC
 PHL ]1
_TCPIPSetHostName MAC
 LDX #$5200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPStatusUDP MAC
 PHWL ]1;]2
_TCPIPStatusUDP MAC
 LDX #$5300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetLinkLayer MAC
 PHL ]1
_TCPIPGetLinkLayer MAC
 LDX #$5400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPPtrToPtr MAC
 PxL ]1;]2;]3
_TCPIPPtrToPtr MAC
 LDX #$5500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPPtrToPtrNeg MAC
 PxL ]1;]2;]3
_TCPIPPtrToPtrNeg MAC
 LDX #$5600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetAuthMessage MAC
 PHS 2
 PHW ]1
_TCPIPGetAuthMessage MAC
 LDX #$5700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPMangleDomainName MAC
 PHS
 PHWL ]1;]2
_TCPIPMangleDomainName MAC
 LDX #$5900+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetAliveFlag MAC
 PHS
_TCPIPGetAliveFlag MAC
 LDX #$5A00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetAliveFlag MAC
 PHW ]1
_TCPIPSetAliveFlag MAC
 LDX #$5B00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetAliveMinutes MAC
 PHS
_TCPIPGetAliveMinutes MAC
 LDX #$5C00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetAliveMinutes MAC
 PHW ]1
_TCPIPSetAliveMinutes MAC
 LDX #$5D00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPReadLineTCP MAC
 PHA
 PHWL ]1;]2
 PHW ]3
 PxL ]4;]5;]6
_TCPIPReadLineTCP MAC
 LDX #$5E00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetBootConnectFlag MAC
 PHS
_TCPIPGetBootConnectFlag MAC
 LDX #$5F00+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetBootConnectFlag MAC
 PHW ]1
_TCPIPSetBootConnectFlag MAC
 LDX #$6000+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetUDPDispatch MAC
 PxW ]1;]2
_TCPIPSetUDPDispatch MAC
 LDX #$6100+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetDestination MAC
 PHWL ]1;]2
_TCPIPGetDestination MAC
 LDX #$6200+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetUserEventTrigger MAC ;v2.1
 PHS 2
 PxW ]1;]2
_TCPIPGetUserEventTrigger MAC
 LDX #$6300+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetUserEventTrigger MAC ;v2.1
 PxW ]1;]2
 PHL ]3
_TCPIPSetUserEventTrigger MAC
 LDX #$6400+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetSysEventTrigger MAC ;v2.1
 PHS 2
 PHW ]1
_TCPIPGetSysEventTrigger MAC
 LDX #$6500+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetSysEventTrigger MAC ;v2.1
 PHWL ]1;]2
_TCPIPSetSysEventTrigger MAC
 LDX #$6600+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPGetDNRTimeouts MAC ;v3.0
 PHS 2
_TCPIPGetDNRTimeouts MAC
 LDX #$6700+]tcpiptoolnum
 JSL $E10000
 <<<
~TCPIPSetDNRTimeouts MAC ;v3.0
 PHL ]1
_TCPIPSetDNRTimeouts MAC
 LDX #$6800+]tcpiptoolnum
 JSL $E10000
 <<<
