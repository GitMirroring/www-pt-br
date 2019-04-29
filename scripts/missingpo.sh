#!/bin/bash
#
#    missingpo.sh - reportes PO files diff between www and www-team dirs
#    Copyright (C) 2017-2019 Rafael Fontenelle
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
#
#
# DESCRIPTION
#    This script reports PO files existence diff between www (CVS repository
#    for www.gnu.org) and www-team (language team's repository) directories.
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

if [ -z "$missingwww" ]; then
    echo "Nada, tudo ok aqui."
else
    echo "$(echo $missingwww | tr ' ' '\n')"
fi

echo ""
echo "*** Arquivos PO disponíveis no wwwdir, mas faltando no teamdir:"

if [ -z "$missingteam" ]; then
    echo "Nada, tudo ok aqui."
else
    echo "$(echo $missingteam | tr ' ' '\n')"
    echo ""
    echo ""
    echo "  Dica: Você pode copiar o arquivo de wwwdir para teamdir usando:"
    echo ""
    echo "   f=arquivo.po"
    echo '   cp ../www/$(dirname $f)/po/$(basename $f) $f'
    echo ""
    echo "  sendo 'arquivo.po' o nome, com o caminho relativo, informado"
    echo "  acima como presente no wwwdir e ausente no teamdir."
fi
