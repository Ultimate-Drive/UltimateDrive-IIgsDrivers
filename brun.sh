#!/bin/bash

BLDDIR=./build_temp
DSK=gsosmerlin.po
PFX=gsos
#cadius createvolume $DSK $PFX 800kb

rm -rf $BLDDIR ; mkdir $BLDDIR


orcafy () {
	s=$1
	ftype=$2
	auxtype=$3
	fname=${s##*/}
	tr "\n" "\r" < $1 > $BLDDIR/$fname
	echo "$fname=Type($ftype),AuxType($auxtype),VersionCreate(B8),MinVersion(FF),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" > $BLDDIR/_FileInformation.txt
	cadius addfile $DSK $PFX $BLDDIR/$fname
}

cadify () {
	s=$1
	ftype=$2
	auxtype=$3
	addpath=$4
	fname=${s##*/}
	cp $s $BLDDIR/
	echo "$fname=Type($ftype),AuxType($auxtype),VersionCreate(B8),MinVersion(FF),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" > $BLDDIR/_FileInformation.txt
	cadius addfile $DSK $PFX/$addpath $BLDDIR/$fname
}


#orcafy ./src/orca/uthernet.asm B0 0003
#orcafy ./src/orca/uthernet2.asm B0 0003
#orcafy ./src/orca/udcustom.macros B0 0003
#orcafy ./src/orca/m16.tcpip B0 0003
#orcafy ./src/orca/resources.src B0 0003
#orcafy ./src/orca/make B0 0006
#orcafy ./src/orca/make2 B0 0006

# ewans copy
#orcafy ./src/orca/uthernet.macros B0 0003

# finally, the udrive ll driver
cd ./src/merlin
merlin32 -V ~/appleiigs/merlin32/Library/ udnet.s
cd ../..
cadius deletefile $DSK $PFX/System/TCPIP/udnet
cadify ./src/merlin/udnet BC 4083 System/TCPIP
#cadius addfile ../gs-hd-library/gsosmerlin.po /gsos/System/TCPIP ./src/merlin/udnet

#udnetdlg.res=Type(5E),AuxType(0001),
#cadius addfile $DSK $PFX ./src/merlin/udnetdlg.res 
#/Users/dagenbrock/appleiigs/gsplus2/GSplus2.app/Contents/MacOS/gsplus2
