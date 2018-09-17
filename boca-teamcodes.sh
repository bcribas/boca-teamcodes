#!/bin/bash
# This script extracts team runs from BOCADB dump
# Author: Bruno Ribas <brunoribas@utfpr.edu.br>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>

BOCADB="$1"

if (( $# < 1)); then
  echo Uso:
  echo "  $0 bocadb.DATE.tar.gz [contest-number|list]"
  echo "      DATE: is generate time of BOCA Dump"
  echo "        ex: bocadb.08Nov2014-19h03min.tar.gz"
  echo "      optional: contest-number of the contest witch data must be extracted"
  echo "                list : lists all contests stored at bocadb"
  exit 1
fi

TMPWORK=$(mktemp -d ${TMPDIR}BOCADUMP.XXX)
if [[ ! -d "$TMPWORK" ]]; then
  echo "Could not create directory to work. Aborting"
  exit 1
fi

tar xf "$BOCADB" -C "$TMPWORK"
cd "$TMPWORK"

if [[ ! -e restore.sql ]]; then
  echo "Something went wrong while uncompressing BOCADB($BOCADB)"
  echo "  check if this is the correct Dump generated by BOCA"
  exit 1
fi

CONTESTTABLE=$(grep -i "^COPY.*contesttable" restore.sql|grep '\.dat'|
  awk -F"'" '{print $(NF-1)}'| cut -d'/' -f2)

if [[ ! -e "$CONTESTTABLE" ]]; then
  echo "Could not find CONTESTTABLE dat file. Aborting"
  exit 1
fi

RUNTABLE=$(grep runtable restore.sql |grep '\.dat'|
  awk -F"'" '{print $(NF-1)}'| cut -d'/' -f2)

if [[ ! -e "$RUNTABLE" ]]; then
  echo "Could not find RUNTABLE dat file. Aborting"
  exit 1
fi

USERTABLE=$(grep -i "^COPY.*usertable" restore.sql|grep '\.dat'|
  awk -F"'" '{print $(NF-1)}'| cut -d'/' -f2)

if [[ ! -e "$USERTABLE" ]]; then
  echo "Could not find USERTABLE dat file. Aborting"
  exit 1
fi

ACTIVECONTEST=$2
ACTIVECONTEST=${ACTIVECONTEST// }

if [[ "$ACTIVECONTEST" == 'list' ]]; then
  awk -F"\t" '{printf $1" "$2 " "; if ($10 == "t" ) printf "-->Active<--\n"; else
  printf "\n";}' $CONTESTTABLE | grep -v '^0 '
  cd $OLDPWD
  rm -rf $TMPWORK
  exit 0
fi
if [[ "x$ACTIVECONTEST" == "x" ]]; then
  ACTIVECONTEST=$(awk -F"\t" '{print $1" "$10}' $CONTESTTABLE|grep t|awk '{print $1}')
fi


if ! grep -q "^$ACTIVECONTEST\>" $USERTABLE; then
  echo "Could not find ACTIVECONTEST. Aborting"
  exit 1
fi

declare -a mapuser
while read SITE USERNUMBER USERNAME TIPO; do
  mapuser[$SITE$USERNUMBER]="s$SITE-$USERNAME"
done <<< "$( grep "^$ACTIVECONTEST\>" $USERTABLE|awk -F'\t' '{print $2" "$3" "$4" "$7}'|grep 'team$')"

COPIADOS=0
IGNORADOS=0
#while read USERNUMBER RUNNUMBER FILENAME OID; do
while read USERNUMBER; do
  read SITE
  read RUNNUMBER
  read FILENAME
  read OID
  read PROBLEMID
  read ANSWER
  RESULT=NO
  if grep -q YES <<< "$ANSWER"; then
    RESULT=YES
  fi
  if [[ "x${mapuser[$SITE$USERNUMBER]}" == "x" ]]; then
    #echo "Assuming user number $USERNUMBER is not a TEAM"
    mkdir -p $OLDPWD/codigos/juizes
    cp blob_$OID.dat "$OLDPWD/codigos/juizes/$PROBLEMID-$RESULT-$RUNNUMBER-$FILENAME"
    ((IGNORADOS++))
    continue
  fi
  mkdir -p "$OLDPWD/codigos/${mapuser[$SITE$USERNUMBER]}"
  cp blob_$OID.dat "$OLDPWD/codigos/${mapuser[$SITE$USERNUMBER]}/$PROBLEMID-$RESULT-$RUNNUMBER-$FILENAME"
  ((COPIADOS++))
done <<< "$(grep "^$ACTIVECONTEST\>" $RUNTABLE |awk -F'\t' '{print $4"\n"$2"\n"$3"\n"$9"\n"$10"\n"$8"\n"$25}')"

echo "Copied $COPIADOS team runs"
echo "Ignored $IGNORADOS runs (judges submissions)"
echo "Runs processed $((COPIADOS+IGNORADOS))"
printf "Runs on this contest: "
grep "^$ACTIVECONTEST\>" $RUNTABLE|wc -l

cd $OLDPWD
rm -rf $TMPWORK

printf "Generating tar.bz2 of teams codes:"
cd codigos
mkdir -p packages.d
for i in *; do
  if [[ "$i" == "packages.d" ]]; then
    continue
  fi
  tar cfj "packages.d/$i.tar.bz2" "$i"
done
echo " Ok"

cd $OLDPWD
