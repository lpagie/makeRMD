#!/bin/bash

# AUTHOR / DATE
#   Ludo Pagie; 190419, makeRMD.py

# INTRO / BACKGROUND
#   wrapper script to compile Rmd (Rhtml) files
#
# USAGE / INPUT / ARGUMENTS / OUTPUT
# USAGE:
#   required:
#     Rmarkdown file; last argument
#   optional:
#     -d: output directory which will contain all intermediate files and all
#         final documents (unless 'outfile' is specified)
#         Default: same as input filename without filename extension.
#     -o: name (plus path) of outputfile
#         Default: same as input filename with extension .pdf/.html
#     -f: output  file format (pdf/html)
#         Default: pdf
#     -t: tag output filename with initial/date
#         Default: no tag
#     -v: print debug info
# INPUT:
#   Rmarkdown or markdown file
# OUTPUT:
#   pdf or html documents
#   All output is stored in a subdirectory. This directory is named after the
#   input file (removing the filename extension), unless the name of the
#   outputdirectory is specified (-d).
#   If the user specifies the name of the output file (-o) the 'final' output
#   file is named accordingly. The output filename can optionally contain a
#   path.
#   By default the script generates a pdf document, 

# TODO
#   

RSCRIPT=Rscript

TAG=""

# PARSE OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
USAGE=
usage() {
  echo >&2 "usage: ${SCRIPTNAME} -[doftvh] input-filename"
  echo >&2 "OPTIONS:"
  echo >&2 "  -d: directory for all output files (unless -o)"
  echo >&2 "  -o: filename of 'final' outputfile [default same as input with different extension"
  echo >&2 "  -f: file format of output doc [default: pdf; options: pdf/html]"
  echo >&2 "  -t: add inital/date-tag to file/dir-names [default: no tags added]"
  echo >&2 "  -v: verbose output"
  echo >&2 "  input-filename: last argument, Rmarkdown document"
  echo >&2 "  -h: print this message"
  echo >&2 ""
  echo >&2 "A wrapper around R,rmarkdown::render, to render (R)md documents to pdf[html] documents (-f)"
  echo >&2 "It takes a single (R)markdown file as input and generates a self-contained output doc"
  echo >&2 "All intermediate output is stored in a subdirectory with the same name as the input filename (without extension)"
  echo >&2 "Output directory name, output filename can be set explicitly by user (-d/-o)"
  echo >&2 "Output dir/filename can be extended with an initial/date tag (-t)"
  echo >&2 ""
  exit 1;
}
while getopts "h?d:o:f:tv" opt; do
  case $opt in
    o)
      OUTFILE=$OPTARG;
      ;;
    d)
      OUTDIR=$OPTARG;
      ;;
    f)
      OUTFORMAT=$OPTARG;
      ;;
    t)
      TAG="_LP$( date +"%y%m%d_%H%M" )"
      ;;
    v)
      VERBOSE=1;
      ;;
    h)
      usage;
      ;;
    \?)
      echo "option not recognized: "$opt
      usage
      ;;
  esac
done
shift $(( OPTIND - 1 ))

# check we have Rscript installed
command -v ${RSCRIPT} >/dev/null 2>&1 || { echo >&2 "${RSCRIPT} command not found"; usage; }


# CONFIGURE INPUT FILES
# check we have exactly 1 remaining argument
if [ ! $# -eq 1 ]; then
  echo -e "\nerror: no, or too many, arguments left after options are parsed (should be a single (R)markdown filename):"
  while test $# -gt 0; do
    echo $1
    shift
  done
  echo -e "Aborting\n\n"
  usage
fi

# retrieve input file from command line
INFILE=( "$1" );
# check if file exists
if [ ! -f ${INFILE} ]; then
  echo -e "error; Rmarkdown file (${INFILE}) doesn't exist.\nAborting\n\n" 
  exit 1
fi

# check and set all script parameters


# determine file extension
extension="${INFILE##*.}"
# determine input format
case ${extension} in
  Rmd|md)
    INFORMAT="md";
    ;;
  Rhtml)
    INFORMAT="html";
    ;;
  *)
    echo -e "filename extension (${extension}) unknown; allowed extensions are: Rmd, md, Rhtml.\nAborting\n\n"
    usage
    ;;
esac
unset extension

# Make name of input file absolute
D=`dirname "${INFILE}"`
B=`basename "${INFILE}"`
INFILE="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`/$B"

# CHECK VARIABLES/OPTIONS
# check all required options are set
## OUTDIR
#########
if [ -z ${OUTDIR+x} ]; then
  # OUTDIR is not specified by user
  # create new name based on inputfilename+tag
  OUTDIR="${INFILE%.*}${TAG}"
fi
# make OUTDIR path absolute
# create dir
mkdir -p "${OUTDIR}"
echo -e "outdir = ${OUTDIR}"
OUTDIR="`cd \"$OUTDIR\" 2>/dev/null && pwd || echo \"$OUTDIR\"`"
echo -e "outdir2 = ${OUTDIR}"

## OUTFORMAT
############
if [ -z "${OUTFORMAT+x}" ]; then
  # use default (pdf) if user did not specify
  OUTFORMAT="pdf"
fi
# check output format is in set of allowed formats
case "${OUTFORMAT}" in
  pdf)
    # this is allowed
    OUTFORMAT="pdf_document"
    OUTEXTENSION="pdf"
    ;;
  html)
    # this is allowed
    OUTFORMAT="html_document"
    OUTEXTENSION="html"
    ;;
  *)
    # all other formats are not allowed
    echo -e "supplied output format (${OUTFORMAT}) is not allowed (allowed options are: pdf/html).\nAborting"
    usage
    ;;
esac

## OUTFILE
##########
if [ -z ${OUTFILE+x} ]; then
  # OUTFILE not specified by user; built based on inputfile
  BASE=$( basename ${INFILE} )
  OUTFILE="${OUTDIR}/${BASE%.*}${TAG}.${OUTEXTENSION}"
else
  # make user supplied output file have absolute path
  # Make name of input file absolute
  D=`dirname "${OUTFILE}"`
  B=`basename "${OUTFILE}"`
  OUTFILE="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`/$B"
fi
# check that the directory of OUTFILE exists
if [ ! -d $( dirname "${OUTFILE}" ) ]; then
  mkdir -p $( dirname "${OUTFILE}" )
fi

## VERBOSE
if [ -x "${VERBOSE}" ]; then
  VERBOSE=0
else
  VERBOSE=1
fi

# input=INFILE
# output_format=OUTFORMAT
# output_file=OUTFILE
# output_dir=OUTDIR

RCMD="rmarkdown::render(input=\"${INFILE}\", output_format=\"${OUTFORMAT}\", output_file=\"${OUTFILE}\", output_dir=\"$( dirname "${OUTFILE}" )\", intermediates_dir=\"${OUTDIR}\", run_pandoc=T, clean=F)"
echo -e "command for Rscript = ${RCMD}"
${RSCRIPT} -e "${RCMD}"

