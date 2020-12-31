#!/bin/bash
#
#    statistics.sh - get statistics of GNU web translation
#    Copyright (C) 2016, 2018, 2020 Rafael Fontenelle
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

die() {
    echo $1 >&2;
    exit 1
}

usage() {
    prog=$(basename $0)
    cat <<EOM
Usage: $prog [Options] [DIR]
Get statistics for languages in the GNU web pages translation project

Options:
   -l <LANG>, --lang <LANG>  output statistics for only language code LANG;
                             if not specified, list stats for all languages
   -h, --help, ?, usage      display this help message and exit
   -s, --by-string           sort the output by the number of translated
                             strings; this changes the default sort order,
                             which is by the number of translated files
   -d                        ignored; kept for backward compatibility

   DIR                       specify the DIR directory for a local checkout
                             of the repository of the GNU web pages project;
                             defaults to the current working directory

Output format:
    <rank> <lang-code>  <file-num> <file-%>  <string-num> <string-%>

A few examples of usage:
 $ $prog
 $ $prog -s
 $ $prog -l pt-br
 $ $prog -l pt-br my/path/to/www
 $ $prog ../www

This script will list the languages supported by the GNU Web translation
system (provided by the file server/gnun/languages.txt), ranking them by
either the number of translated .po files (default) or translated strings.

All supported languages are listed by default. If a supported lang code is
specified, the list will be grepped to output only the statistics for this
language.

These percentages are obtained by using the number of translated .po files
multiplied by a hundred, divided by the number of .pot files; replace files
with strings, if -s/--by-string option is used.

This script was inspired by the math formula sent by Bruno Felix in 2015 to
the www-pt-br-general mail list, as can be seen in:
https://lists.gnu.org/archive/html/www-pt-br-general/2015-09/msg00003.html

For more information on how to do checkout of the GNU web pages repository,
check the GNU Web Translators Manual in:
  <https://www.gnu.org/software/trans-coord/manual/web-trans/>

Report bugs to <www-pt-br-general@gnu.org>.

EOM
}

# Return the total amount of filenames and strings from a list of GNU Gettext
# POT or PO files provided. The file extension is automatically recognized,
# but POT file extension must be '.pot' or '.pot.opt', and PO file extension
# must be '.po'.
# The output format is '<file_count> <string_count>', so this output must be
# split before its values are used.
getcount() {
    local stringcount=0
    local filecount=0
    local currentstringcount
    local MSGFMT=/usr/bin/msgfmt

    allfiles="$*"

    for file in $allfiles; do

        if [[ $file =~ '.pot'$ || $file =~ '.pot.opt'$ ]]; then
          column='$4'
        elif [[ $file =~ '.po'$ ]]; then
          column='$1'
        else
          die "Unexpected filename: $file"
        fi

        currentstringcount=$(LC_ALL='C' $MSGFMT --statistics -o /dev/null $file 2>&1 \
                             | grep 'translated message' | awk "{print $column}")

        if [ $currentstringcount -gt 0 ]; then
          (( filecount++ ))
          stringcount=$(( stringcount + currentstringcount ))
        else
          # Ignoring invalid value invalid file
          continue
        fi
    done

    echo "$filecount $stringcount"
}

# Evaluate and print the statistics. Calls 'getcount' function for getting
# number of po/pot files and translation strings.
getstats() {
     # Asterisk variable required for the command below
    ast='*'

    potfilelist=$(find ./ \( -name '*.pot' -o -name '*.pot.opt' \) | sed 's|./||')
    potcount=$(getcount $potfilelist)
    potfiles=${potcount%% *}
    potstrings=${potcount##* }

    column=2; echo "files..."
    [ $orderbystring -eq 1 ] && ( column=4; echo "strings...";)

    printf "Collecting statistics from PO files, and ordering by translated "

    printf "   %-6s %-10s %s\n" "Langs" "Files" "Strings"
    for l in $LANGS; do
        pofilelist=$(find ./ -name "$ast.$l.po" | sed 's|./||')
        pocount=$(getcount $pofilelist)
        pofiles=${pocount%% *}
        postrings=${pocount##* }

        strings="$postrings ($(( postrings * 100 / potstrings ))%)"
        files="$pofiles ($(( pofiles * 100 / potfiles ))%)"

        printf "%-6s %-10s %s\n" "$l" "$files" "$strings"
    done  \
    |  sort -grk${column} | nl -s' ' -w2
}

# Parse the arguments provided
LANG=""; DIR=""; orderbystring=0
while [ $# -ne 0 ]; do
    if [[ $1 == '--help' || $1 == '-h' || $1 == '?' || $1 == 'usage' ]]; then
        usage
        exit 0
    elif [[ $1 == '-l' || $1 == '--lang' ]]; then
        [ -z $2 ] && die "Missing language code for the option $1"
        LANG=$2
        shift; shift
    elif [[ $1 == '-d' ]]; then
        shift
    elif [[ $1 == '-s' || $1 == '--by-string' ]]; then
        orderbystring=1
        shift
    elif [[ $1 != "${1##-}" ]]; then
        die "Invalid option -- \"$1\""
    else
        DIR=$1
        shift
    fi
done

# Test DIR, look for www repository and set wwwdir variable
if [ -z $DIR ]; then
    DIR="$(pwd)"
elif [ ! -d $DIR ]; then
    die "\"$DIR\" is not a directory."
fi
if [ -f "$DIR/server/gnun/languages.txt" ]; then
    wwwdir=$DIR
elif [[ ! -f "$DIR/server/gnun/languages.txt" && -d $DIR/../www ]]; then
    wwwdir=$DIR/../www
fi

cd $wwwdir || die "Failed to change to directory $wwwdir"
wwwdir=$(pwd)

# Check whether language code is valid for GNU web pages
if [ ! -z $LANG ]; then
    grep $LANG server/gnun/languages.txt > /dev/null
    [ $? -ne 0 ] && die "Unsupported language '$LANG' in the file $wwwdir/server/gnun/languages.txt"
fi

# Set target language(s) to be used in the 'for' statement below
LANGS=$(sed -e '/^#.*$/d;s/^\(^[a-z-]*[^[:space:]]\).*$/\1/' server/gnun/languages.txt);

# Get and output statistics for all languages or for the specified one, if any
if [ -z $LANG ]; then
    getstats
else
    getstats | grep $LANG
fi
