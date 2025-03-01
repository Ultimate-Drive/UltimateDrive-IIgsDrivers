This directory contains the ORCA/M sources for the Uthernet I + II drivers.

These are only included for reference and are not part of the UltimateDrive product. 

All rights reserved by the authors within. 



### Build Notes

Install Orca/M, 2.1.0 should suffice

Create disk image with makedisk utility.

Launch a IIgs emulator with your disk and run Orca/M.

Build with "make" script.
```
prefix :udnet
make
```


### OLD NOTES - for reference only
To create an LDF file from Orca/m
```
prefix :udnet+
macgen uthernet.asm uthernet.macros 13:AInclude:m= 13:AppleUtil:m= :udnet:m16.tcpip :udnet:udcustom.macros
macgen uthernet.asm uthernet.macros 13:AppleUtil:m16.util2 13:AInclude:m=  :udnet:m16.tcpip :udnet:udcustom.macros

macgen uthernet2.asm uthernet.macros 13:ORCAInclude:m16.ORCA 13:AppleUtil:m16.util2 13:AInclude:m=  :udnet:m16.tcpip :udnet:udcustom.macros
asml uthernet.asm
filetype uthernet ldf
```

Note: LDF filetype is $BC according to Cadius (aux 4083)
From doc: Marinetti link layer modules are OMF files of file type $00BC and auxilliary type $00004083

```
filetype emulator.asm $b0 $0003
17/macgen +C emulator.asm emulator.macros emulator.macros 13/Ainclude/mm16.= 13/Ainclude/m16.= 13/ORCAInclude/M16.=
assemble +W +E +T emulator.asm keep=emulator
link +b emulator keep=emulator
filetype Emulator $bc $4083
copy -c Emulator /hard.disk/system/tcpip/Emulator
shutdown

```