
# install chasen and uplug

VERSION = 0.1

CONTENTS = $(shell ls)

ifdef PREFIX
  MAKE_ARGS = PREFIX=${PREFIX}
  CONFIG_ARGS = --prefix=${PREFIX}
endif

# binary for chasen
CHASENBIN = ${shell which chasen 2>/dev/null}

# if chasen is not found: compile it
ifndef ($(CHASENBIN))
ifdef PREFIX
  CHASENPREFIX = ${PREFIX}
else
  CHASENPREFIX = /usr/local
endif
  CHASENBIN = ${CHASENPREFIX}/bin/chasen
endif


CHASEN=chasen-2.4.5
DARTS=darts-0.32
IPADIC=ipadic-2.7.0


all install: ${CHASENBIN} uplug/Makefile
	${MAKE} -C uplug $@

test:
	${MAKE} uplug/Makefile
	${MAKE} -C uplug $@

clean:
	-${MAKE} uplug/Makefile
	-${MAKE} -C uplug $@
	-rm -fr $(DARTS) $(CHASEN) $(IPADIC)

manifest: clean

dist: clean
	rm -f */Makefile.old
	mkdir -p $(notdir $(shell pwd))-$(VERSION)
	mv $(CONTENTS) $(notdir $(shell pwd))-$(VERSION)
	tar -czf $(notdir $(shell pwd))-$(VERSION).tar.gz $(notdir $(shell pwd))-$(VERSION)
	mv $(notdir $(shell pwd))-$(VERSION)/* .
	rmdir $(notdir $(shell pwd))-$(VERSION)




${CHASENBIN}: 
	${MAKE} $(DARTS)/Makefile $(CHASEN)/Makefile $(IPADIC)/Makefile
	${MAKE} -C $(DARTS) all install
	${MAKE} -C $(CHASEN) all install
	${MAKE} -C $(IPADIC) all install
	rm -fr $(DARTS) $(CHASEN) $(IPADIC)

$(DARTS)/Makefile:
	tar -xzf $(DARTS).tar.gz
	cd $(DARTS) && ./configure ${CONFIG_ARGS}

# a little hack: make a symbolic link to ../darts/darts.h to make it compile ...

$(CHASEN)/Makefile: $(DARTS)/Makefile 
	tar -xzf $(CHASEN).tar.gz
	( cd $(CHASEN) && ./configure --with-darts=../$(DARTS) ${CONFIG_ARGS} )
	( cd $(CHASEN) && ln -s ../$(DARTS)/darts.h . )

# dictionary

$(IPADIC)/Makefile: $(CHASEN)/Makefile 
	tar -xzf $(IPADIC).tar.gz
	( cd $(IPADIC) && \
	  ./configure 	--with-chasen-config=../$(CHASEN) \
			--with-mkchadic=../$(CHASEN)/mkchadic \
			--with-chasenrc-path=${CHASENPREFIX}/etc/chasenrc  \
			--with-dicdir=${CHASENPREFIX}/share \
			${CONFIG_ARGS} )

uplug/Makefile: uplug/Makefile.PL
	(cd $(dir $@) && perl Makefile.PL ${MAKE_ARGS})
