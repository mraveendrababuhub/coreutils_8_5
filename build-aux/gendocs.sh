#!/bin/sh -e
# gendocs.sh -- generate a GNU manual in many formats.  This script is
#   mentioned in maintain.texi.  See the help message below for usage details.

scriptversion=2016-01-01.00

# Copyright 2003-2016 Free Software Foundation, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Original author: Mohit Agarwal.
# Send bug reports and any other correspondence to bug-gnulib@gnu.org.
#
# The latest version of this script, and the companion template, is
# available from the Gnulib repository:
#
# http://git.savannah.gnu.org/cgit/gnulib.git/tree/build-aux/gendocs.sh
# http://git.savannah.gnu.org/cgit/gnulib.git/tree/doc/gendocs_template

# TODO:
# - image importing was only implemented for HTML generated by
#   makeinfo.  But it should be simple enough to adjust.
# - images are not imported in the source tarball.  All the needed
#   formats (PDF, PNG, etc.) should be included.

prog=`basename "$0"`
srcdir=`pwd`

scripturl="http://git.savannah.gnu.org/cgit/gnulib.git/plain/build-aux/gendocs.sh"
templateurl="http://git.savannah.gnu.org/cgit/gnulib.git/plain/doc/gendocs_template"

: ${SETLANG="env LANG= LC_MESSAGES= LC_ALL= LANGUAGE="}
: ${MAKEINFO="makeinfo"}
: ${TEXI2DVI="texi2dvi"}
: ${DOCBOOK2HTML="docbook2html"}
: ${DOCBOOK2PDF="docbook2pdf"}
: ${DOCBOOK2TXT="docbook2txt"}
: ${GENDOCS_TEMPLATE_DIR="."}
: ${PERL='perl'}
: ${TEXI2HTML="texi2html"}
unset CDPATH
unset use_texi2html

version="gendocs.sh $scriptversion

Copyright 2016 Free Software Foundation, Inc.
There is NO warranty.  You may redistribute this software
under the terms of the GNU General Public License.
For more information about these matters, see the files named COPYING."

usage="Usage: $prog [OPTION]... PACKAGE MANUAL-TITLE

Generate output in various formats from PACKAGE.texinfo (or .texi or
.txi) source.  See the GNU Maintainers document for a more extensive
discussion:
  http://www.gnu.org/prep/maintain_toc.html

Options:
  --email ADR use ADR as contact in generated web pages; always give this.

  -s SRCFILE   read Texinfo from SRCFILE, instead of PACKAGE.{texinfo|texi|txi}
  -o OUTDIR    write files into OUTDIR, instead of manual/.
  -I DIR       append DIR to the Texinfo search path.
  --common ARG pass ARG in all invocations.
  --html ARG   pass ARG to makeinfo or texi2html for HTML targets,
                 instead of --css-ref=/software/gnulib/manual.css.
  --info ARG   pass ARG to makeinfo for Info, instead of --no-split.
  --no-ascii   skip generating the plain text output.
  --no-html    skip generating the html output.
  --no-info    skip generating the info output.
  --no-tex     skip generating the dvi and pdf output.
  --source ARG include ARG in tar archive of sources.
  --split HOW  make split HTML by node, section, chapter; default node.
  --tex ARG    pass ARG to texi2dvi for DVI and PDF, instead of -t @finalout.

  --texi2html  use texi2html to make HTML target, with all split versions.
  --docbook    convert through DocBook too (xml, txt, html, pdf).

  --help       display this help and exit successfully.
  --version    display version information and exit successfully.

Simple example: $prog --email bug-gnu-emacs@gnu.org emacs \"GNU Emacs Manual\"

Typical sequence:
  cd PACKAGESOURCE/doc
  wget \"$scripturl\"
  wget \"$templateurl\"
  $prog --email BUGLIST MANUAL \"GNU MANUAL - One-line description\"

Output will be in a new subdirectory \"manual\" (by default;
use -o OUTDIR to override).  Move all the new files into your web CVS
tree, as explained in the Web Pages node of maintain.texi.

Please use the --email ADDRESS option so your own bug-reporting
address will be used in the generated HTML pages.

MANUAL-TITLE is included as part of the HTML <title> of the overall
manual/index.html file.  It should include the name of the package being
documented.  manual/index.html is created by substitution from the file
$GENDOCS_TEMPLATE_DIR/gendocs_template.  (Feel free to modify the
generic template for your own purposes.)

If you have several manuals, you'll need to run this script several
times with different MANUAL values, specifying a different output
directory with -o each time.  Then write (by hand) an overall index.html
with links to them all.

If a manual's Texinfo sources are spread across several directories,
first copy or symlink all Texinfo sources into a single directory.
(Part of the script's work is to make a tar.gz of the sources.)

As implied above, by default monolithic Info files are generated.
If you want split Info, or other Info options, use --info to override.

You can set the environment variables MAKEINFO, TEXI2DVI, TEXI2HTML,
and PERL to control the programs that get executed, and
GENDOCS_TEMPLATE_DIR to control where the gendocs_template file is
looked for.  With --docbook, the environment variables DOCBOOK2HTML,
DOCBOOK2PDF, and DOCBOOK2TXT are also consulted.

By default, makeinfo and texi2dvi are run in the default (English)
locale, since that's the language of most Texinfo manuals.  If you
happen to have a non-English manual and non-English web site, see the
SETLANG setting in the source.

Email bug reports or enhancement requests to bug-gnulib@gnu.org.
"

MANUAL_TITLE=
PACKAGE=
EMAIL=webmasters@gnu.org  # please override with --email
commonarg= # passed to all makeinfo/texi2html invcations.
dirargs=   # passed to all tools (-I dir).
dirs=      # -I directories.
htmlarg=--css-ref=/software/gnulib/manual.css
infoarg=--no-split
generate_ascii=true
generate_html=true
generate_info=true
generate_tex=true
outdir=manual
source_extra=
split=node
srcfile=
texarg="-t @finalout"

while test $# -gt 0; do
  case $1 in
    -s)          shift; srcfile=$1;;
    -o)          shift; outdir=$1;;
    -I)          shift; dirargs="$dirargs -I '$1'"; dirs="$dirs $1";;
    --common)    shift; commonarg=$1;;
    --docbook)   docbook=yes;;
    --email)     shift; EMAIL=$1;;
    --html)      shift; htmlarg=$1;;
    --info)      shift; infoarg=$1;;
    --no-ascii)  generate_ascii=false;;
    --no-html)   generate_ascii=false;;
    --no-info)   generate_info=false;;
    --no-tex)    generate_tex=false;;
    --source)    shift; source_extra=$1;;
    --split)     shift; split=$1;;
    --tex)       shift; texarg=$1;;
    --texi2html) use_texi2html=1;;

    --help)      echo "$usage"; exit 0;;
    --version)   echo "$version"; exit 0;;
    -*)
      echo "$0: Unknown option \`$1'." >&2
      echo "$0: Try \`--help' for more information." >&2
      exit 1;;
    *)
      if test -z "$PACKAGE"; then
        PACKAGE=$1
      elif test -z "$MANUAL_TITLE"; then
        MANUAL_TITLE=$1
      else
        echo "$0: extra non-option argument \`$1'." >&2
        exit 1
      fi;;
  esac
  shift
done

# makeinfo uses the dirargs, but texi2dvi doesn't.
commonarg=" $dirargs $commonarg"

# For most of the following, the base name is just $PACKAGE
base=$PACKAGE

if test -n "$srcfile"; then
  # but here, we use the basename of $srcfile
  base=`basename "$srcfile"`
  case $base in
    *.txi|*.texi|*.texinfo) base=`echo "$base"|sed 's/\.[texinfo]*$//'`;;
  esac
  PACKAGE=$base
elif test -s "$srcdir/$PACKAGE.texinfo"; then
  srcfile=$srcdir/$PACKAGE.texinfo
elif test -s "$srcdir/$PACKAGE.texi"; then
  srcfile=$srcdir/$PACKAGE.texi
elif test -s "$srcdir/$PACKAGE.txi"; then
  srcfile=$srcdir/$PACKAGE.txi
else
  echo "$0: cannot find .texinfo or .texi or .txi for $PACKAGE in $srcdir." >&2
  exit 1
fi

if test ! -r $GENDOCS_TEMPLATE_DIR/gendocs_template; then
  echo "$0: cannot read $GENDOCS_TEMPLATE_DIR/gendocs_template." >&2
  echo "$0: it is available from $templateurl." >&2
  exit 1
fi

# Function to return size of $1 in something resembling kilobytes.
calcsize()
{
  size=`ls -ksl $1 | awk '{print $1}'`
  echo $size
}

# copy_images OUTDIR HTML-FILE...
# -------------------------------
# Copy all the images needed by the HTML-FILEs into OUTDIR.
# Look for them in . and the -I directories; this is simpler than what
# makeinfo supports with -I, but hopefully it will suffice.
copy_images()
{
  local odir
  odir=$1
  shift
  $PERL -n -e "
BEGIN {
  \$me = '$prog';
  \$odir = '$odir';
  @dirs = qw(. $dirs);
}
" -e '
/<img src="(.*?)"/g && ++$need{$1};

END {
  #print "$me: @{[keys %need]}\n";  # for debugging, show images found.
  FILE: for my $f (keys %need) {
    for my $d (@dirs) {
      if (-f "$d/$f") {
        use File::Basename;
        my $dest = dirname ("$odir/$f");
        #
        use File::Path;
        -d $dest || mkpath ($dest)
          || die "$me: cannot mkdir $dest: $!\n";
        #
        use File::Copy;
        copy ("$d/$f", $dest)
          || die "$me: cannot copy $d/$f to $dest: $!\n";
        next FILE;
      }
    }
    die "$me: $ARGV: cannot find image $f\n";
  }
}
' -- "$@" || exit 1
}

case $outdir in
  /*) abs_outdir=$outdir;;
  *)  abs_outdir=$srcdir/$outdir;;
esac

echo "Making output for $srcfile"
echo " in `pwd`"
mkdir -p "$outdir/"

# 
if $generate_info; then
  cmd="$SETLANG $MAKEINFO -o $PACKAGE.info $commonarg $infoarg \"$srcfile\""
  echo "Generating info... ($cmd)"
  rm -f $PACKAGE.info* # get rid of any strays
  eval "$cmd"
  tar czf "$outdir/$PACKAGE.info.tar.gz" $PACKAGE.info*
  ls -l "$outdir/$PACKAGE.info.tar.gz"
  info_tgz_size=`calcsize "$outdir/$PACKAGE.info.tar.gz"`
  # do not mv the info files, there's no point in having them available
  # separately on the web.
fi  # end info

# 
if $generate_tex; then
  cmd="$SETLANG $TEXI2DVI $dirargs $texarg \"$srcfile\""
  printf "\nGenerating dvi... ($cmd)\n"
  eval "$cmd"
  # compress/finish dvi:
  gzip -f -9 $PACKAGE.dvi
  dvi_gz_size=`calcsize $PACKAGE.dvi.gz`
  mv $PACKAGE.dvi.gz "$outdir/"
  ls -l "$outdir/$PACKAGE.dvi.gz"

  cmd="$SETLANG $TEXI2DVI --pdf $dirargs $texarg \"$srcfile\""
  printf "\nGenerating pdf... ($cmd)\n"
  eval "$cmd"
  pdf_size=`calcsize $PACKAGE.pdf`
  mv $PACKAGE.pdf "$outdir/"
  ls -l "$outdir/$PACKAGE.pdf"
fi # end tex (dvi + pdf)

# 
if $generate_ascii; then
  opt="-o $PACKAGE.txt --no-split --no-headers $commonarg"
  cmd="$SETLANG $MAKEINFO $opt \"$srcfile\""
  printf "\nGenerating ascii... ($cmd)\n"
  eval "$cmd"
  ascii_size=`calcsize $PACKAGE.txt`
  gzip -f -9 -c $PACKAGE.txt >"$outdir/$PACKAGE.txt.gz"
  ascii_gz_size=`calcsize "$outdir/$PACKAGE.txt.gz"`
  mv $PACKAGE.txt "$outdir/"
  ls -l "$outdir/$PACKAGE.txt" "$outdir/$PACKAGE.txt.gz"
fi

# 

if $generate_html; then
# Split HTML at level $1.  Used for texi2html.
html_split()
{
  opt="--split=$1 --node-files $commonarg $htmlarg"
  cmd="$SETLANG $TEXI2HTML --output $PACKAGE.html $opt \"$srcfile\""
  printf "\nGenerating html by $1... ($cmd)\n"
  eval "$cmd"
  split_html_dir=$PACKAGE.html
  (
    cd ${split_html_dir} || exit 1
    ln -sf ${PACKAGE}.html index.html
    tar -czf "$abs_outdir/${PACKAGE}.html_$1.tar.gz" -- *.html
  )
  eval html_$1_tgz_size=`calcsize "$outdir/${PACKAGE}.html_$1.tar.gz"`
  rm -f "$outdir"/html_$1/*.html
  mkdir -p "$outdir/html_$1/"
  mv ${split_html_dir}/*.html "$outdir/html_$1/"
  rmdir ${split_html_dir}
}

if test -z "$use_texi2html"; then
  opt="--no-split --html -o $PACKAGE.html $commonarg $htmlarg"
  cmd="$SETLANG $MAKEINFO $opt \"$srcfile\""
  printf "\nGenerating monolithic html... ($cmd)\n"
  rm -rf $PACKAGE.html  # in case a directory is left over
  eval "$cmd"
  html_mono_size=`calcsize $PACKAGE.html`
  gzip -f -9 -c $PACKAGE.html >"$outdir/$PACKAGE.html.gz"
  html_mono_gz_size=`calcsize "$outdir/$PACKAGE.html.gz"`
  copy_images "$outdir/" $PACKAGE.html
  mv $PACKAGE.html "$outdir/"
  ls -l "$outdir/$PACKAGE.html" "$outdir/$PACKAGE.html.gz"

  # Before Texinfo 5.0, makeinfo did not accept a --split=HOW option,
  # it just always split by node.  So if we're splitting by node anyway,
  # leave it out.
  if test "x$split" = xnode; then
    split_arg=
  else
    split_arg=--split=$split
  fi
  #
  opt="--html -o $PACKAGE.html $split_arg $commonarg $htmlarg"
  cmd="$SETLANG $MAKEINFO $opt \"$srcfile\""
  printf "\nGenerating html by $split... ($cmd)\n"
  eval "$cmd"
  split_html_dir=$PACKAGE.html
  copy_images $split_html_dir/ $split_html_dir/*.html
  (
    cd $split_html_dir || exit 1
    tar -czf "$abs_outdir/$PACKAGE.html_$split.tar.gz" -- *
  )
  eval \
    html_${split}_tgz_size=`calcsize "$outdir/$PACKAGE.html_$split.tar.gz"`
  rm -rf "$outdir/html_$split/"
  mv $split_html_dir "$outdir/html_$split/"
  du -s "$outdir/html_$split/"
  ls -l "$outdir/$PACKAGE.html_$split.tar.gz"

else # use texi2html:
  opt="--output $PACKAGE.html $commonarg $htmlarg"
  cmd="$SETLANG $TEXI2HTML $opt \"$srcfile\""
  printf "\nGenerating monolithic html with texi2html... ($cmd)\n"
  rm -rf $PACKAGE.html  # in case a directory is left over
  eval "$cmd"
  html_mono_size=`calcsize $PACKAGE.html`
  gzip -f -9 -c $PACKAGE.html >"$outdir/$PACKAGE.html.gz"
  html_mono_gz_size=`calcsize "$outdir/$PACKAGE.html.gz"`
  mv $PACKAGE.html "$outdir/"

  html_split node
  html_split chapter
  html_split section
fi
fi # end html

# 
printf "\nMaking .tar.gz for sources...\n"
d=`dirname $srcfile`
(
  cd "$d"
  srcfiles=`ls -d *.texinfo *.texi *.txi *.eps $source_extra 2>/dev/null` || true
  tar czfh "$abs_outdir/$PACKAGE.texi.tar.gz" $srcfiles
  ls -l "$abs_outdir/$PACKAGE.texi.tar.gz"
)
texi_tgz_size=`calcsize "$outdir/$PACKAGE.texi.tar.gz"`

# 
# Do everything again through docbook.
if test -n "$docbook"; then
  opt="-o - --docbook $commonarg"
  cmd="$SETLANG $MAKEINFO $opt \"$srcfile\" >${srcdir}/$PACKAGE-db.xml"
  printf "\nGenerating docbook XML... ($cmd)\n"
  eval "$cmd"
  docbook_xml_size=`calcsize $PACKAGE-db.xml`
  gzip -f -9 -c $PACKAGE-db.xml >"$outdir/$PACKAGE-db.xml.gz"
  docbook_xml_gz_size=`calcsize "$outdir/$PACKAGE-db.xml.gz"`
  mv $PACKAGE-db.xml "$outdir/"

  split_html_db_dir=html_node_db
  opt="$commonarg -o $split_html_db_dir"
  cmd="$DOCBOOK2HTML $opt \"${outdir}/$PACKAGE-db.xml\""
  printf "\nGenerating docbook HTML... ($cmd)\n"
  eval "$cmd"
  (
    cd ${split_html_db_dir} || exit 1
    tar -czf "$abs_outdir/${PACKAGE}.html_node_db.tar.gz" -- *.html
  )
  html_node_db_tgz_size=`calcsize "$outdir/${PACKAGE}.html_node_db.tar.gz"`
  rm -f "$outdir"/html_node_db/*.html
  mkdir -p "$outdir/html_node_db"
  mv ${split_html_db_dir}/*.html "$outdir/html_node_db/"
  rmdir ${split_html_db_dir}

  cmd="$DOCBOOK2TXT \"${outdir}/$PACKAGE-db.xml\""
  printf "\nGenerating docbook ASCII... ($cmd)\n"
  eval "$cmd"
  docbook_ascii_size=`calcsize $PACKAGE-db.txt`
  mv $PACKAGE-db.txt "$outdir/"

  cmd="$DOCBOOK2PDF \"${outdir}/$PACKAGE-db.xml\""
  printf "\nGenerating docbook PDF... ($cmd)\n"
  eval "$cmd"
  docbook_pdf_size=`calcsize $PACKAGE-db.pdf`
  mv $PACKAGE-db.pdf "$outdir/"
fi

# 
printf "\nMaking index.html for $PACKAGE...\n"
if test -z "$use_texi2html"; then
  CONDS="/%%IF  *HTML_SECTION%%/,/%%ENDIF  *HTML_SECTION%%/d;\
         /%%IF  *HTML_CHAPTER%%/,/%%ENDIF  *HTML_CHAPTER%%/d"
else
  # should take account of --split here.
  CONDS="/%%ENDIF.*%%/d;/%%IF  *HTML_SECTION%%/d;/%%IF  *HTML_CHAPTER%%/d"
fi

curdate=`$SETLANG date '+%B %d, %Y'`
sed \
   -e "s!%%TITLE%%!$MANUAL_TITLE!g" \
   -e "s!%%EMAIL%%!$EMAIL!g" \
   -e "s!%%PACKAGE%%!$PACKAGE!g" \
   -e "s!%%DATE%%!$curdate!g" \
   -e "s!%%HTML_MONO_SIZE%%!$html_mono_size!g" \
   -e "s!%%HTML_MONO_GZ_SIZE%%!$html_mono_gz_size!g" \
   -e "s!%%HTML_NODE_TGZ_SIZE%%!$html_node_tgz_size!g" \
   -e "s!%%HTML_SECTION_TGZ_SIZE%%!$html_section_tgz_size!g" \
   -e "s!%%HTML_CHAPTER_TGZ_SIZE%%!$html_chapter_tgz_size!g" \
   -e "s!%%INFO_TGZ_SIZE%%!$info_tgz_size!g" \
   -e "s!%%DVI_GZ_SIZE%%!$dvi_gz_size!g" \
   -e "s!%%PDF_SIZE%%!$pdf_size!g" \
   -e "s!%%ASCII_SIZE%%!$ascii_size!g" \
   -e "s!%%ASCII_GZ_SIZE%%!$ascii_gz_size!g" \
   -e "s!%%TEXI_TGZ_SIZE%%!$texi_tgz_size!g" \
   -e "s!%%DOCBOOK_HTML_NODE_TGZ_SIZE%%!$html_node_db_tgz_size!g" \
   -e "s!%%DOCBOOK_ASCII_SIZE%%!$docbook_ascii_size!g" \
   -e "s!%%DOCBOOK_PDF_SIZE%%!$docbook_pdf_size!g" \
   -e "s!%%DOCBOOK_XML_SIZE%%!$docbook_xml_size!g" \
   -e "s!%%DOCBOOK_XML_GZ_SIZE%%!$docbook_xml_gz_size!g" \
   -e "s,%%SCRIPTURL%%,$scripturl,g" \
   -e "s!%%SCRIPTNAME%%!$prog!g" \
   -e "$CONDS" \
$GENDOCS_TEMPLATE_DIR/gendocs_template >"$outdir/index.html"

echo "Done, see $outdir/ subdirectory for new files."

# Local variables:
# eval: (add-hook 'write-file-hooks 'time-stamp)
# time-stamp-start: "scriptversion="
# time-stamp-format: "%:y-%02m-%02d.%02H"
# time-stamp-end: "$"
# End:
