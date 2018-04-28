#!/bin/bash
#
#    statistics.sh - get translation percentage of GNU web for each language 
#    Copyright (C) 2016, 2018 Rafael Fontenelle
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
 -l LANG, --lang LANG     language which you want statistics for;
                          default returns statistics of all languages
                          known by the file server/gnun/languages.txt
                          within DIR
 -h, --help, ?, usage     display this help message and exit

DIR         specify the DIR directory for the local checkout of the
            repository of the GNU web pages project; default: use the
            current directory

Output format: rank, language and percentage

A few examples of use:
 $ $prog
 $ $prog -l pt-br
 $ $prog -l pt-br ../www
 $ $prog ../www
 $ $prog ../www

For more information on how to do checkout of the GNU web pages
repository, check the GNU Web Translator in:
  <https://www.gnu.org/software/trans-coord/manual/web-trans/>

EOM
}

# Parse the arguments provided
[ $# -gt 3 ] && die "Expected at most 3 arguments, but got $#"
LANG=""; DIR=""
while [ $# -ne 0 ]; do
    if [[ $1 == '--help' || $1 == '-h' || $1 == '?' || $1 == 'usage' ]]; then
        usage
        exit 0
    elif [[ $1 == '-l' || $1 == '--lang' ]]; then
        [ -z $2 ] && die "Missing language code for the option $1"
        LANG=$2
        shift; shift
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

cd $wwwdir  || die "Failed to change to directory $wwwdir"
wwwdir=$(pwd)

# Check whether language code is valid for GNU web pages
if [ ! -z $LANG ]; then
    grep $LANG server/gnun/languages.txt > /dev/null
    [ $? -ne 0 ] && die "Unsupported language \"$LANG\" in the file $wwwdir/server/gnun/languages.txt"
fi

# Set target languages to be used in the 'for' statement below
if [ -z $LANG ]; then
    LANGS=$(sed -e '/^#.*$/d;s/^\(^[a-z-]*[^[:space:]]\).*$/\1/' server/gnun/languages.txt);
else
    LANGS=$LANG
fi

# Set a variable for asterisk as it cannot be passed directly in the command below
ast='*'

# Command extract from the email sent by Bruno Felix. See:
#   https://lists.gnu.org/archive/html/www-pt-br-general/2015-09/msg00003.html
for l in $LANGS; do
    echo "$l  $(($(find ./ -name "$ast.$l.po" | wc -l) * 100 /
                 $(find ./ -name '*.pot' | wc -l) + 1))%"
done  \
|  sort -grk2 | nl -s' ' -w2
