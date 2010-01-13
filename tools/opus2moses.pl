#!/usr/bin/perl
#-*-perl-*-
#
# convert sentence aligned bitexts to factored moses input
# (requires XML::Parser)
#
# opus2moses.pl [OPTIONS] < sentence-align-file.xml
#
# OPTIONS:
#
# -s srcfactors ......... specify source language factors besides surface words
# -t trgfactors ......... the same for the target language (separated by ':')
#                         factors should be attributes of <w> tags!!
#                         (except 'word' which is the word itself)
# -d dir ................ home directory of the OPUS subcorpus
# -n file-pattern ....... skip bitext files that match pattern (e.g. ep-00-1*)
# -i .................... inverse selection (only files matching file pattern)
# -e src-data-file ...... output file for source language data (default = src)
# -f src-data-file ...... output file for target language data (default = trg)
#
# -p sentence-pair-file . stores sentence ID pairs of the extracted pairs
# -l .................... convert to lower case
# -1 .................... 1:1 links only
# -x max ................ max size of sentences (in nr of words)
#

use strict;
use XML::Parser;
use FileHandle;


use vars qw($opt_s $opt_t $opt_d $opt_n $opt_i $opt_e $opt_f $opt_h $opt_p $opt_l $opt_1 $opt_x);
use Getopt::Std;

getopts('s:t:d:n:ie:f:hp:l1x:');

if ($opt_h){
    print <<"EOH";

 opus2moses.pl [OPTIONS] < sentence-align-file.xml

 convert sentence aligned bitexts to factored moses input
 (requires XML::Parser)

 OPTIONS:

 -s srcfactors ......... specify source language factors besides surface words
 -t trgfactors ......... the same for the target language (separated by ':')
                         factors should be attributes of <w> tags!!
                         (except 'word' which is the word itself)
 -d dir ................ home directory of the OPUS subcorpus
 -n file-pattern ....... skip bitext files that match pattern (e.g. ep-00-1*)
 -i .................... inverse selection (only files matching file pattern)
 -e src-data-file ...... output file for source language data (default = src)
 -f src-data-file ...... output file for target language data (default = trg)
 -1 .................... extract 1:1 sentence alignments only
 -x max ................ maximum size of selected sentences (default=80)

EOH
    exit;
}


my $CORPUSHOME   = $opt_d || $ENV{HOME}.'/projects/OPUS/corpus/Europarl3';
my $SRCFACTORSTR = $opt_s || "word";
my $TRGFACTORSTR = $opt_t || "word";

# my $SRCFACTORSTR = $opt_s || "lem:tree";
# my $TRGFACTORSTR = $opt_t || "lem:tree";

my $SRCOUTFILE   = $opt_e || 'src';
my $TRGOUTFILE   = $opt_f || 'trg';

my @SrcFactors = split(/:/,$SRCFACTORSTR);
my @TrgFactors = split(/:/,$TRGFACTORSTR);

my $MAX = $opt_x || 80;

## make XML parser object for parsing the sentence alignment file

my $BitextParser = new XML::Parser(Handlers => {Start => \&AlignTagStart,
						End => \&AlignTagEnd});
my $BitextHandler = $BitextParser->parse_start;

## global variables for the source and target language XML parsers

my ($SrcParser,$TrgParser);
my ($SrcHandler,$TrgHandler);

my ($SRC,$TRG);         # filehandles for reading bitexts

## open output files

my $SRCOUT = new FileHandle;
my $TRGOUT = new FileHandle;

$SRCOUT->open("> $SRCOUTFILE");
$TRGOUT->open("> $TRGOUTFILE");

binmode($SRCOUT, ":utf8");
binmode($TRGOUT, ":utf8");

if ($opt_p){
    open P,">$opt_p" || warn "cannot open $opt_p ...\n";
}

## use '>' as input delimiter when reading (usually end of XML tag)

$/='>';

## read through sentence alignment file and parse XML
## - sub routines for reading source and target language corpora are
##   called from XML handlers connected to this XML parser object
## - aligned sentences have to be in the same order in the corpus files
##   as they appear in the sentence alignment file!

while (<>){
    eval { $BitextHandler->parse_more($_); };
    if ($@){
	warn $@;
	print STDERR $_;
    }
}

$SRCOUT->close();
$TRGOUT->close();

if ($opt_p){
    close P;
}


## finished!
##--------------------------------------------------------------------------




## open source and target corpus files (could be gzipped)
## create new XML parser objects and start parsing

sub OpenCorpora{
    my ($srcfile,$trgfile)=@_;

    if ((! -e "$CORPUSHOME/$srcfile") && (-e "$CORPUSHOME/$srcfile.gz")){
	$srcfile.='.gz';
    }
    if ((! -e "$CORPUSHOME/$trgfile") && (-e "$CORPUSHOME/$trgfile.gz")){
	$trgfile.='.gz';
    }

    ## check if file names match pattern of files to be skipped
    if (defined $opt_n){
	if ($opt_i){
	    if ($srcfile!~/$opt_n/ && $trgfile!~/$opt_n/){
		print "skip $srcfile-$trgfile\n";
		return 0;
	    }
	}
	elsif ($srcfile=~/$opt_n/ || $trgfile=~/$opt_n/){
	    print "skip $srcfile-$trgfile\n";
	    return 0;
	}
    }

    print STDERR "open bitext $srcfile <-> $trgfile\n";

    ## open filehandles to read from
    $SRC = new FileHandle;
    $TRG = new FileHandle;
    if ($srcfile=~/\.gz$/){$SRC->open("gzip -cd < $CORPUSHOME/$srcfile |");}
    else{$SRC->open("< $CORPUSHOME/$srcfile");}
    if ($trgfile=~/\.gz$/){$TRG->open("gzip -cd < $CORPUSHOME/$trgfile |");}
    else{$TRG->open("< $CORPUSHOME/$trgfile");}

    $SrcParser = new XML::Parser(Handlers => {Start => \&XmlTagStart,
					      End => \&XmlTagEnd,
					      Default => \&XmlChar});
    $SrcHandler = $SrcParser->parse_start;
    $SrcHandler->{OUT} = $SRCOUT;
    @{$SrcHandler->{FACTORS}} = @SrcFactors;
    $TrgParser = new XML::Parser(Handlers => {Start => \&XmlTagStart,
					      End => \&XmlTagEnd,
					      Default => \&XmlChar});
    $TrgHandler = $TrgParser->parse_start;
    $TrgHandler->{OUT} = $TRGOUT;
    @{$TrgHandler->{FACTORS}} = @TrgFactors;
}

sub CloseCorpora{
    $SRC->close() if (defined $SRC);
    $TRG->close() if (defined $TRG);
}



## read from file handle and parse XML with corpus parser object
## idstr should be space-delimitered string of sentence IDs
## read until all sentences (all IDs) are found!
## --> all sentences have to exist and have to appear in the same order
##     they are specified in idstr (no crossing links whatsoever!)

sub ParseSentences{
    my ($idstr,$handle,$fh)=@_;
    my @ids=split(/\s+/,$idstr);
    @{$handle->{IDS}}=@ids;

    return if not @{$handle->{IDS}};

    while (<$fh>){
	eval { $handle->parse_more($_); };
	if ($@){
	    warn $@;
	    print STDERR $_;
	}
	return 1 if ($handle->{CLOSEDSID} eq $ids[-1]);
    }
}



##-------------------------------------------------------------------------
## XML parser handlers for sentence alignment parser


## XML opening tags
## - linkGrp --> open a new bitext (source & target corpus file)
## - link    --> a new sentence alignment: read sentences from source & target

sub AlignTagStart{
    my ($p,$e,%a)=@_;

    if ($e eq 'linkGrp'){
	if ($opt_p){
	    print P "## $a{fromDoc}\t$a{toDoc}\n";
	}
	return &OpenCorpora($a{fromDoc},$a{toDoc});
    }

    if ($e eq 'link'){
	## only if bitext filehandles are defined ...
	if (defined $SRC && defined $TRG){
	    my ($src,$trg) = split(/\s*\;\s*/,$a{xtargets});
	    if ($src=~/\S/ && $trg=~/\S/){
		if ($opt_1){
		    return if ($src=~/\S\s\S/);
		    return if ($trg=~/\S\s\S/);
		}

		$SrcHandler->{OUTSTR}='';   # reset output string
		$TrgHandler->{OUTSTR}='';

		&ParseSentences($src,$SrcHandler,$SRC);
		&ParseSentences($trg,$TrgHandler,$TRG);

		# skip if no words found
		return if (not $SrcHandler->{NRWORDS});
		return if (not $TrgHandler->{NRWORDS});
		# skip if sentences are too long
		return if ($SrcHandler->{NRWORDS} > $MAX);
		return if ($TrgHandler->{NRWORDS} > $MAX);
		# skip if ratio<=9 (like in clean_corpus for MOSES)
		return if $SrcHandler->{NRWORDS}/$TrgHandler->{NRWORDS}>9;
		return if $TrgHandler->{NRWORDS}/$SrcHandler->{NRWORDS}>9;

		$SrcHandler->{OUTSTR}=~s/^\s+//;  # remove leading spaces
		$SrcHandler->{OUTSTR}=~s/\s+$//;  # remove final spaces
		$TrgHandler->{OUTSTR}=~s/^\s+//;
		$TrgHandler->{OUTSTR}=~s/\s+$//;

		print $SRCOUT $SrcHandler->{OUTSTR},"\n" if (defined $SRCOUT);
		print $TRGOUT $TrgHandler->{OUTSTR},"\n" if (defined $TRGOUT);

		if ($opt_p){
		    print P "$src\t$trg\n";
		}
	    }
	}
    }
}


## closing tags: linkGrp --> close source and target corpus files

sub AlignTagEnd{
    my ($p,$e)=@_;
    if ($e eq 'linkGrp'){
	return &CloseCorpora();
    }
}



##-------------------------------------------------------------------------
## XML parser handlers for corpus parser (separate for source and target)


## XML opening tags
## - s: starts a new sentence --> store ID
## - w: starts a new word --> factors should be attributes of this tag!

sub XmlTagStart{
    my ($p,$e,%a)=@_;

    if ($e eq 's'){
	$p->{OPENSID} = $a{id};
	delete $p->{CLOSEDSID};
	$p->{NRWORDS}=0;
	return 1;
    }
    if ($e eq 'w'){
	if ($p->{OPENSID} eq $p->{IDS}->[0]){
	    $p->{OPENW} = 1;
	    %{$p->{WATTR}} = %a;
	    $p->{WORD}='';
	    $p->{NRWORDS}++;
	}
    }
}

## strings within tags
## - open w-tag? --> print string to SRCOUT

sub XmlChar{
    my ($p,$c)=@_;
    if ($p->{OPENW}){
	if ($p->{OPENSID} eq $p->{IDS}->[0]){
#	    $c=~tr/| \n/___/;
	    $p->{WATTR}->{word}.=$c;
	}
    }
}

## XML closing tags
## - s: end of sentence --> shift ID-set if necessary
## - w: end of word --> add space in the end (adds extra space after last word)

sub XmlTagEnd{
    my ($p,$e,%a)=@_;

    if ($e eq 's'){
	$p->{CLOSEDSID} = $p->{OPENSID};
	if ($p->{CLOSEDSID} eq $p->{IDS}->[0]){
	    shift(@{$p->{IDS}});
	}
	delete $p->{OPENSID};
    }
    elsif ($e eq 'w'){
	if ($p->{OPENSID} eq $p->{IDS}->[0]){
	    $p->{OPENW} = 0;
	    my @factors=();
	    foreach my $f (@{$p->{FACTORS}}){
		$p->{WATTR}->{$f}=~s/^\s+//s;
		$p->{WATTR}->{$f}=~s/\s+$//s;
		$p->{WATTR}->{$f}=~tr/| \n/___/;    # ' ' and '|' not allowed!
		$p->{WATTR}->{$f} = 'UNKNOWN' if ($p->{WATTR}->{$f}!~/\S/);
		if ($f eq 'lem'){
		    if ($p->{WATTR}->{$f}=~/UNKNOWN/){
			$p->{WATTR}->{$f}=$p->{WATTR}->{word};
		    }
		    elsif ($p->{WATTR}->{$f}=~/\@card\@/){
			$p->{WATTR}->{$f}=$p->{WATTR}->{word};
		    }
		}
		if ($opt_l){
		    $p->{WATTR}->{$f}=lc($p->{WATTR}->{$f});
		}
		push(@factors,$p->{WATTR}->{$f});
	    }
	    if (defined $p->{OUT}){
		my $OUT = $p->{OUT};
		$p->{OUTSTR}.=join('|',@factors);  # save string
		$p->{OUTSTR}.=' ';
#		print $OUT join('|',@factors);     # instead of printing
#		print $OUT ' ';                    # directly!
	    }
	}
    }
}
