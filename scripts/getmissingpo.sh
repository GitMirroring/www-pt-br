#!/bin/bash
# 
# NAME
#    getmissingpo
#
# SYNOPSIS
#    getmissingpo
#
# DESCRIPTION
#    getmissingpo reports PO files existence diff between www (CVS repository
#    on gnu.org) and www-team (language team's repository) directories.
#
#    For that spectific language, this script gets all PO files inside each
#    repository (www and www-team), then match those file-lists to get the
#    difference and, finally, reports which PO files are missing in which
#    repository (but exists in the other one).
#
#    You may find this script useful to report files in www-team that are
#    not available in www (they were probably not committed yet or removed/not
#    sent to www) and vice-versa (already committed to www, so probably need
#    to be committed to www-team as well).
# 

GNUDIR=${1:-$HOME/GNU/sync}
wwwdir=$GNUDIR/www
teamdir=$GNUDIR/www-pt-br

if [ ! -d $GNUDIR ]; then
    echo "Diretório raiz inválido \"GNUDIR = $GNUDIR\""
    exit 1
fi
if [ ! -d $wwwdir ]; then
    echo "Falha em encontrar o repositório web GNU oficial \"wwwdir = $wwwdir\""
    exit 1
fi
if [ ! -d $teamdir ]; then
    echo "Falha em encontrar o repositório web GNU brasileiro \"teamdir = $teamdir\""
    exit 1
fi

wwwpofiles=$(find $wwwdir/ -type f -name '*.pt-br.po' | sed "s|$wwwdir/||g;s|po/||g" | sort)
# don't compare compendium, as it exists only in www
wwwpofiles=${wwwpofiles/"server/gnun/compendia/compendium.pt-br.po"}

teampofiles=$(find $teamdir/ -type f -name '*.pt-br.po' | sed "s|$teamdir/||g" | sort)

allmissing=$(echo "$wwwpofiles $teampofiles" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')
missingwww=""
missingteam=""
for po in $allmissing; do
    if ! [ $(echo "$wwwpofiles" | grep $po) ]; then
        missingwww+=" $po"
    elif ! [ $(echo "$teampofiles" | grep $po) ]; then
        missingteam+=" $po"
    fi
done

echo ""
echo "wwwdir  = $wwwdir"
echo "teamdir = $teamdir"
echo ""
echo "*** Arquivos PO disponíveis no teamdir, mas faltando no wwwdir:"
echo "$(echo $missingwww | tr ' ' '\n')"
echo ""
echo "*** Arquivos PO disponíveis no wwwdir, mas faltando no teamdir:"
echo "$(echo $missingteam | tr ' ' '\n')"
echo ""
