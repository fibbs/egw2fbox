#!/bin/bash

while getopts  "c:" flag
do
  case "$flag" in
	c)
		CONFIGFILE=$OPTARG
		;;
  esac
done

if [ -z $CONFIGFILE ]; then
	echo "you must supply a config file using the -c argument"
	exit 253

elif [ ! -f "$CONFIGFILE" ]; then
	echo "could not open config file"
	exit 254
fi

BASEDIR=$(grep "CRON_BASEDIR" $CONFIGFILE | cut -d"=" -f2|sed "s/ //g"|sed "s/\/\+$//")

if [ ! -d "$BASEDIR" ]; then
	echo "basedir $BASEDIR not found or is not a directory"
	exit 252
fi

BINDIR=$BASEDIR/bin
CONFDIR=$BASEDIR/etc
DATADIR=$BASEDIR/data
# create data files viewable for user only
umask 077

cd $BASEDIR

# call the magic perl script
$BINDIR/egw2fbox.pl -c $CONFDIR/egw2fbox.conf
if [ $? -ne 0 ]; then
	echo "egroupware exporter did not finish correctly"
	exit 251
fi

# hash
NEWHASH=$(cat $DATADIR/phonebook.xml | grep -v mod_time | md5sum | cut -d" " -f1)
OLDHASH=$(cat $DATADIR/phonebook.hash 2>/dev/null)

if [ "_$OLDHASH" != "_$NEWHASH" ]; then
	export FRITZUPLOADERCFG=$CONFDIR/egw2fbox.conf
	$BINDIR/fritzuploader.pl

	if [ $? -eq 0 ]; then
		# only persist new hash if fritzuploader has run correctly
		# in case of i. e. network problems that one should fail and
		# make this wrapper script recognize that another upload is
		# needed
		echo $NEWHASH >$DATADIR/phonebook.hash
	fi
fi
