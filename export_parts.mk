OPENSCAD=openscad
MODULES=$(shell grep -o 'export_[a-zA-Z0-9_-]*' $(BASE))
SCADS=$(patsubst export_%,out/%.scad,$(MODULES))
STLS=$(patsubst export_%,out/%.stl,$(MODULES))
TARGETS=$(STLS)

all: ${TARGETS}
.PHONY: all clean

.SECONDARY: $(SCADS)

out/%.scad: $(BASE)
	@mkdir -p out
	echo -ne 'use <../$(BASE)>\nexport_$*();' > $@

%.stl: %.scad
	$(OPENSCAD) -o $@ $<

clean:
	rm -f $(SCADS)
	rm -f $(STLS)
	rmdir out
