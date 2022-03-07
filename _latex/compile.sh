#!/bin/bash

default_library="$HOME/texmf/bibtex/bib/library.bib"
show_help(){
  echo "Usage: $0 [-l english|french] [-c] [-a] [-b] [-e <default|library.bib>]"
  echo 
  echo "       -l choose the language in which to produce cv and publications list. Currently support english (and partially french)"
  echo "       -c, -a, -b Specify cleaning patterns. -c requests clean-up but specfiying after and/or before is still mandatory. -b/-a requests deletion before/after compilation"
  echo "       -e Extract publications by me (Godin-)Dubois, Kevin from the provided library file (defaults to $default_library)"
}

tmpfiles(){
  find . \( \
       -name '*.aux' -o -name '*.bbl' -o -name '*.bcf' -o -name '*.blg' -o -name '*.log' \
    -o -name '*.out' -o -name '*.run.xml' -o -name '*.synctex.gz' \) $1
}

pdfcompile(){
  pdflatex --interaction=batchmode "\\def\\kgdlang{$lang}\input{$1}"
}

clean(){
  n=$(tmpfiles | wc -l)
  echo "Deleting temporary files"
  tmpfiles -print
  tmpfiles -delete
  printf "> %d temporary files deleted\n\n" $n
}

cvfolder=$(find . -name "cv.tex" -printf '%h')
cd $cvfolder
wd=$(pwd)

lang="english"
clean=""
cleanbefore=""
cleanafter=""
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?l:abce:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    l)  lang=$OPTARG
        ;;
    c)  clean="yes"
        ;;
    b)  cleanbefore="yes"
        ;;
    a)  cleanafter="yes"
        ;;
    
    e)  library=$default_library
        [ "$OPTARG" != "default" ] && library="$OPTARG"
        bib2bib -q -r -s year -s '$key' -c 'author : "GodinDubois, Kevin*" or author : "Dubois, Kevin"' $library |
          grep -v -e "file =" -e "abstract =" | sed 's/type =/entrysubtype =/' |
          sed 's/\(url = {.*\) .*}/\1}/' > cv.bib
        echo "Extracted publications from $library"
        echo
        ;;
    esac
done


[ ! -z "$clean" -a ! -z "$cleanbefore" ] && clean


for l in misc/academicons_rgate
do
  if [ ! -f $l.pdf ]
  then
    cd $(dirname $l)
    lualatex $(basename $l).tex
    cd $wd
    printf "\033[32mCompiled misc file $l\033[0m\n\n"
  fi
done

lg=${lang:0:2}
echo "Compiling for '$lang' [$lg] language"
echo

for f in {cv,publications}
do
  pdfcompile $f
  biber --quiet $f
  pdfcompile $f 
  pdfcompile $f 
  
  echo
  o=${f}_${lg}.pdf
  mv -v $f.pdf $o
  
  [ "$lg" == "en" ] && cp -v $o ../$f.pdf
  
  if [ -f $o ]
  then
    printf "\033[32mCompiled file $f\033[0m\n\n"
  else
    printf "\033[31mFailed to compile file $f\033[0m\n\n"
  fi
done

bibfilesize=$(grep "entrysubtype" cv.bib | wc -l)
bibliosize=$(grep 'defaultrefcontext' cv.aux | wc -l)
if [ $bibfilesize -ne $bibliosize ] 
then
  printf "\033[33mMismatched bibliography: found %d pieces of work but only %d were cited\033[0m\n" $bibfilesize $bibliosize
  (
    echo "cv.bib cv.aux"
    diff -y \
      <(sed -n "s/^@.*{\([A-Za-z]*Dubois.*\),/\1/p" cv.bib | sort) \
      <(sed -n 's/.*defaultrefcontext{0}{\([^}]*\)}.*/\1/p' cv.aux | sort)
  ) | column -t
fi

[ ! -z "$clean" -a ! -z "$cleanafter" ] && clean
