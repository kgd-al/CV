#!/bin/bash

show_help(){
  echo "Usage: $0 [-l english|french] [-c] [-a] [-b]"
  echo 
  echo "       -l choose the language in which to produce cv and publications list. Currently support english (and partially french)"
  echo "       -c, -a, -b Specify cleaning patterns. -c requests clean-up but specfiying after and/or before is still mandatory. -b/-a requests deletion before/after compilation"
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
  tmpfiles -print -delete
  printf "> %d temporary files deleted\n\n" $n
}

lang="english"
clean=""
cleanbefore=""
cleanafter=""
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?l:abc" opt; do
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
    esac
done

cvfolder=$(find . -name "cv.tex" -printf '%h')
cd $cvfolder
wd=$(pwd)

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

echo "Compiling for '$lang' language"
echo

for f in {cv,publications}
do
  pdfcompile $f
  biber --quiet $f
  pdfcompile $f 
  pdfcompile $f 
  
  echo
  mv -v $f.pdf ../
  
  if [ -f ../$f.pdf ]
  then
    printf "\033[32mCompiled file $f\033[0m\n\n"
  else
    printf "\033[31mFailed to compile file $f\033[0m\n\n"
  fi
done

[ ! -z "$clean" -a ! -z "$cleanafter" ] && clean
