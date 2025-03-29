OUTIMAGE=udutils

TARGET1 = udnet.s
WORKDIR1 = gsos-marinetti-driver/src/merlin
OUT1 = udnet

TARGET2 = nda.s
WORKDIR2 = gsos-nda/src
OUT2 = udnda

TARGET3 = gsosdriver.s
WORKDIR3 = gsos-device-driver/src
OUT3 = UltimateDrive

MERLIN = merlin32
MACRODIR := "$(CURDIR)/lib/merlin-macros"
MERLIN_FLAGS = -V $(MACRODIR)


all:
	@$(MAKE) udnet
	@$(MAKE) nda
	@$(MAKE) device
	@echo "\nMost recent build files:\n" ; ls -al $(WORKDIR1)/$(OUT1) $(WORKDIR2)/$(OUT2) $(WORKDIR3)/$(OUT3)
	@$(MAKE) image

image:
	@echo "\nCreating $(OUTIMAGE).po and adding files...\n"
	@echo "UltimateDrive=Type(BB),AuxType(0102),VersionCreate(70),MinVersion(BE),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" > $(WORKDIR3)/_FileInformation.txt 

	@cadius createvolume $(OUTIMAGE).po $(OUTIMAGE) 800kb
	@cadius addfile $(OUTIMAGE).po /$(OUTIMAGE) $(WORKDIR1)/$(OUT1)
	@cadius addfile $(OUTIMAGE).po /$(OUTIMAGE) $(WORKDIR2)/$(OUT2)
	@cadius addfile $(OUTIMAGE).po /$(OUTIMAGE) $(WORKDIR3)/$(OUT3)
	
udnet:
	@cd $(WORKDIR1) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET1)
nda:
	@cd $(WORKDIR2) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET2)
device:
	@cd $(WORKDIR3) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET3)


install:
	@cadius addfile gsoshd.po /gsos/System/Drivers/ $(WORKDIR3)/$(OUT3)

uninstall:
	@cadius deletefile gsoshd.po /gsos/System/Drivers/UltimateDrive

sd:
	@cp gsoshd.po /Volumes/ULTRA/
	@diskutil eject /Volumes/ULTRA
	@echo "Ejected."

clean:
	rm -f $(WORKDIR1)/$(OUT1)
	rm -f $(WORKDIR2)/$(OUT2)
	rm -f $(WORKDIR3)/$(OUT3)
	

