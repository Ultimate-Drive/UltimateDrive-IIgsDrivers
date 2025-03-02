TARGET1 = udnet.s
WORKDIR1 = gsos-marinetti-driver/src/merlin
OUT1 = udnet

TARGET2 = nda.s
WORKDIR2 = gsos-nda/src
OUT2 = udnda

TARGET3 = gsosdriver.s
WORKDIR3 = gsos-device-driver/src
OUT3 = uddevice

MERLIN = merlin32
MACRODIR := "$(CURDIR)/lib/merlin-macros"
MERLIN_FLAGS = -V $(MACRODIR)


all:
	@cd $(WORKDIR1) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET1)
	@cd $(WORKDIR2) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET2)
	@cd $(WORKDIR3) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET3)
	@echo "\nChecking out files:\n" ; ls -al $(WORKDIR1)/$(OUT1) $(WORKDIR2)/$(OUT2) $(WORKDIR3)/$(OUT3)

udnet:
	@cd $(WORKDIR1) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET1)
nda:
	@cd $(WORKDIR2) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET2)
device:
	@cd $(WORKDIR3) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET3)

clean:
	rm -f $(WORKDIR1)/$(OUT1)
	rm -f $(WORKDIR2)/$(OUT2)
	rm -f $(WORKDIR3)/$(OUT3)
	