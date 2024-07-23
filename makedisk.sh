#!/bin/bash

BLDDIR=./build_temp
DSK=udnet.po
PFX=udnet
cadius createvolume $DSK $PFX 800kb

mkdir $BLDDIR


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
	fname=${s##*/}
	echo "$fname=Type($ftype),AuxType($auxtype),VersionCreate(B8),MinVersion(FF),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" > $BLDDIR/_FileInformation.txt
	cadius addfile $DSK $PFX $BLDDIR/$fname
}


orcafy ./src/orca/uthernet.asm B0 0003
orcafy ./src/orca/uthernet2.asm B0 0003
orcafy ./src/orca/udcustom.macros B0 0003
orcafy ./src/orca/m16.tcpip B0 0003
orcafy ./src/orca/resources.src B0 0003
orcafy ./src/orca/make B0 0006

# ewans copy
orcafy ./src/orca/uthernet.macros B0 0003

# finally, the udrive ll driver
cadify ./src/merlin/udrive BC 4083
