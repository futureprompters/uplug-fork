#
# USAGE
#
#  make   ................... make files needed for ISA (sentence alignment) 
#                             with default corpus (1988sven)
#  make sentalign ........... make ISA files for default corpus
#  make wordalign ........... make ICA files (word alignment) for default corpus
#  make ALIGN=xx wordalign .. make ICA files using word alignment config 'xx'
#                             (default: 'basic', check uplug/systems/align/word
#                              in your Uplug directory for alternatives)
#  make C=cc sentalign ...... make files for ISA for corpus 'cc'
#                             (corpus name should be nnXXYY where 
#                              XX is the ID of the source language (2 chars!)
#                              YY is the ID of the target language (2 chars!)
#                              and nn is some name (without spaces)
#                             the Makefile expects source and target files in
#                             corpora/ with the names 'nnXX.txt' and 'nnYY.txt'
#  make C=cc clues .......... make basic clues and (basic) giza clues
#  make C=cc basicclues ..... string similarity and dice
#  make C=cc gizaclues ...... GIZA refined and GIZA prefix
#  make C=cc gizaposclues ... GIZA with POS tags (useless if you don't have POS tags!)
#  make C=cc dynamicclues ... makes dynamic clues (requires word alignment
#  make C=cc wordalign ...... make ICA files for corpus 'cc' (same as above)
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# set the UPLUG, UPLUGSHARE, SENTALIGNER variables below
# if uplug is not in your path and globally installed
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#############################################################################
# set the following variables if necessary:
#
# CORPUS ...... name of the corpus (without extension)
# SRCLANG ..... source language identifier (eg. en, sv, ...)
# TRGLANG ..... target language identifier (eg. en, sv, ...)
#
# UPLUG ....... home directory of your Uplug distribution
# UPLUGWEB .... location of uplug when accessed from PHP
# ALIGN ....... type of word alignment to be run (to create clue DBMs)
#
#
# SRCXML ...... source language document (default: $(CORPUS)$(SRCLANG).xml)
# TRGXML ...... target language document (default: $(CORPUS)$(TRGLANG).xml)
#
#############################################################################

VERSION  = 0.1
CONTENTS = $(shell ls) 


PWD = $(shell pwd)

# UPLUG = path to uplug start script
# UPLUGSHARE = home directory of shared data
# SENTALIGNER = default alignment program (Gale&Church)

ifndef UPLUG
  UPLUG       = $(shell which uplug)
endif
ifndef UPLUGSHARE
  UPLUGSHARE  = $(shell perl -e 'use Uplug::Config;print &shared_home();')
endif
ifndef SENTALIGNER
  SENTALIGNER = $(shell perl -e 'use Uplug::Config;print find_executable("align2");')
endif

ALIGN = basic

# UPLUG = ${PWD}/uplug
# UPLUGWEB = uplug

## default: look for a *.ces file in the current directory

C = 1988sven
# CORPUS = $(patsubst %.ces,%,$(wildcard *.ces))
CORPUS = corpora/$(C)

## default: first two characters of the corpus name (or path) = SRCLANG
## default: characters 3 and 4 of the corpus name (or path) = TRGLANG

#SRCLANG = $(shell echo '$(CORPUS)' | sed 's/^\(..\).*$$/\1/')
#TRGLANG = $(shell echo '$(CORPUS)' | sed 's/^..\(..\).*$$/\1/')

SRCLANG = $(shell echo '$(CORPUS)' | sed 's/^.*\(..\)..$$/\1/')
TRGLANG = $(shell echo '$(CORPUS)' | sed 's/^.*\(..\)$$/\1/')

LANGPAIR = $(SRCLANG)$(TRGLANG)
INVLANGPAIR = $(TRGLANG)$(SRCLANG)

BASENAME = $(shell echo '$(CORPUS)' | sed 's/$(LANGPAIR)//')

#############################################################################

SRCXML = $(BASENAME)$(SRCLANG).xml
TRGXML = $(BASENAME)$(TRGLANG).xml

SRCTXT = $(patsubst %.xml,%.txt,$(SRCXML))
TRGTXT = $(patsubst %.xml,%.txt,$(TRGXML))
ENCODING = iso-8859-1

#############################################################################

SENTALIGN = $(CORPUS).ces
SENTALIGNIDS = $(CORPUS).ids
WORDALIGN = $(CORPUS).$(ALIGN)

#############################################################################


CORPUSDIR = $(shell echo '$(CORPUS)' | sed 's|/[^/]*$$||')
DATADIR = $(CORPUS)

CONFIG = $(DATADIR)/config.inc
ISACONFIG = $(DATADIR)/config.isa
ICACONFIG = $(DATADIR)/config.ica


# make all .............. make config and data-dirs to run ISA (sentalign)
# make sentalign ........ prepare for ISA (interactice sentence aligner)
# make wordalign ........ run word alignment to make clues for ICA


all: sentalign

sentalign: $(SRCXML) $(TRGXML) $(DATADIR) $(CONFIG)
	chmod o+w $(CORPUSDIR)

wordalign: $(DATADIR) $(SENTALIGN) $(SENTALIGNIDS) $(WORDALIGN) $(CONFIG)


$(DATADIR):
	mkdir -p $(DATADIR)
	chmod o+w $(DATADIR)
	mkdir -p $(DATADIR)/data/runtime
	chmod o+w $(DATADIR)/data/runtime

$(SRCXML):
	$(UPLUG) pre/basic -ci '$(ENCODING)' -in $(SRCTXT) -out $@

$(TRGXML):
	$(UPLUG) pre/basic -ci '$(ENCODING)' -in $(TRGTXT) -out $@

$(SENTALIGN): $(SRCXML) $(TRGXML)
	$(UPLUG) align/sent -src $(SRCXML) -trg $(TRGXML) -out $@

$(SENTALIGNIDS): $(SENTALIGN)
	grep '<link ' $(SENTALIGN) |\
	sed 's/^.* id="//' |\
	cut -d '"' -f1 > $@
	rm -f config.inc


pre_wordalign: $(SENTALIGN) $(DATADIR)/link

$(DATADIR)/link: ${UPLUGSHARE}/systems/align/word/test/link
	cp $< $@
	chmod o+w $@


$(WORDALIGN): pre_wordalign
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/$(ALIGN) \
	          -in ${PWD}/$(SENTALIGN) \
	          -out $(PWD)/$(WORDALIGN) )


clues: pre_wordalign basicclues gizaclues

dynamicclues: pre_wordalign $(WORDALIGN)
	( cd $(DATADIR);\
	$(UPLUG) align/word/dynamicclues \
	          -in ${PWD}/$(WORDALIGN) )

basicclues: pre_wordalign
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/basicclues \
	          -in ${PWD}/$(SENTALIGN) )

gizaclues: pre_wordalign gizarefined gizaprefix
gizaposclues: pre_wordalign gizapos gizaposword

gizarefined: pre_wordalign $(DATADIR)/giza-refined.links $(DATADIR)/giza-refined-i.links
gizaprefix: pre_wordalign $(DATADIR)/giza-prefix.links $(DATADIR)/giza-prefix-i.links
gizapos: pre_wordalign $(DATADIR)/giza-pos.links $(DATADIR)/giza-pos-i.links
gizaposword: pre_wordalign $(DATADIR)/giza-pos-word.links $(DATADIR)/giza-pos-word-i.links

$(DATADIR)/giza-refined.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/giza-word-refined -c 1 \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-refined.links )


$(DATADIR)/giza-pos.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-pos \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )

$(DATADIR)/giza-pos-word.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-pos-word \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )

$(DATADIR)/giza-prefix.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-word-prefix \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )



$(DATADIR)/giza-pos-i.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-pos-i \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )

$(DATADIR)/giza-pos-word-i.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-pos-word-i \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )

$(DATADIR)/giza-prefix-i.links: $(SENTALIGN)
	rm -f $(DATADIR)/corpora
	ln -s $(PWD)/corpora $(DATADIR)/
	( cd $(DATADIR);\
	$(UPLUG) align/word/GIZA/gizaclue-word-prefix-i \
	          -in ${PWD}/$(SENTALIGN) \
		  -out $(DATADIR)/giza-pos.links )




$(CONFIG): $(DATADIR)/%.inc: include/%.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%UPLUGSHARE%%#$(UPLUGSHARE)#' |\
	sed 's#%%SENTALIGNER%%#$(SENTALIGNER)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ISACONFIG): $(DATADIR)/%.isa: include/%.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%UPLUGSHARE%%#$(UPLUGSHARE)#' |\
	sed 's#%%SENTALIGNER%%#$(SENTALIGNER)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

$(ICACONFIG):$(DATADIR)/%.ica: include/%.in $(SRCXML) $(TRGXML)
	sed 's#%%IDFILE%%#$(SENTALIGNIDS)#' $< |\
	sed 's#%%DATADIR%%#$(DATADIR)#' |\
	sed 's#%%SRCXML%%#$(SRCXML)#' |\
	sed 's#%%TRGXML%%#$(TRGXML)#' |\
	sed 's#%%BITEXT%%#$(SENTALIGN)#' |\
	sed 's#%%UPLUG%%#$(UPLUG)#' |\
	sed 's#%%UPLUGSHARE%%#$(UPLUGSHARE)#' |\
	sed 's#%%SENTALIGNER%%#$(SENTALIGNER)#' |\
	sed 's#%%LANGPAIR%%#$(LANGPAIR)#' |\
	sed 's#%%INVLANGPAIR%%#$(INVLANGPAIR)#' > $@

clean:
	rm -f config.inc
	rm -f $(SENTALIGNIDS)
#	rm -f $(WORDALIGN)

test:
	echo $(CORPUS)
	echo $(LANGPAIR)
	echo $(INVLANGPAIR)




manifest: clean

dist: clean
	rm -f */Makefile.old
	mkdir -p $(notdir $(shell pwd))-$(VERSION)
	mv $(CONTENTS) $(notdir $(shell pwd))-$(VERSION)
	tar -czf $(notdir $(shell pwd))-$(VERSION).tar.gz $(notdir $(shell pwd))-$(VERSION)
	mv $(notdir $(shell pwd))-$(VERSION)/* .
	rmdir $(notdir $(shell pwd))-$(VERSION)
