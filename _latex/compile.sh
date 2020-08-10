#!/bin/bash

tmpfiles(){
  find . \( \
       -name '*.aux' -o -name '*.bbl' -o -name '*.bcf' -o -name '*.blg' -o -name '*.log' \
    -o -name '*.out' -o -name '*.run.xml' -o -name '*.synctex.gz' \) $1
}

pdfcompile(){
  pdflatex --interaction=batchmode $1
}

if [ $# -eq 0 ]
then
  printf "Compile mode\n\n"
  cvfolder=$(find . -name "cv.tex" -printf '%h')
  cd $cvfolder
  wd=$(pwd)
  
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
  
  for f in {cv,publications}
  do
    pdfcompile $f
    biber --quiet $f
    pdfcompile $f 
    pdfcompile $f 
    
    echo
    mv -v $f.pdf ../
    printf "\033[32mCompiled file $f\033[0m\n\n"
  done
  
else
  echo "Clean mode"
#   tmpfiles
  printf "Deleted %d temporary files\n" $(tmpfiles | wc -l)
  tmpfiles -delete
fi
