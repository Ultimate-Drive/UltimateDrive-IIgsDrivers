TARGET1 = udnet.s
WORKDIR1 = gsos-marinetti-driver/src/merlin
CLEAN1 = udnet

TARGET2 = nda.s
WORKDIR2 = gsos-nda/src
CLEAN2 = udnda

TARGET3 = gsosdriver.s
WORKDIR3 = gsos-device-driver/src
CLEAN3 = udgsosdev

MERLIN = merlin32
MACRODIR := "$(CURDIR)/lib/merlin-macros"
MERLIN_FLAGS = -V $(MACRODIR)


all:
	@cd $(WORKDIR1) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET1)
	@cd $(WORKDIR2) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET2)
	@cd $(WORKDIR3) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET3)

udnet:
	@cd $(WORKDIR1) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET1)
nda:
	@cd $(WORKDIR2) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET2)
device:
	@cd $(WORKDIR3) && $(MERLIN) $(MERLIN_FLAGS) $(TARGET3)

clean:
	@rm -f $(WORKDIR1)/$(CLEAN1)
	@rm -f $(WORKDIR2)/$(CLEAN2)
	@rm -f $(WORKDIR3)/$(CLEAN3)
	