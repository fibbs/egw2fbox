#!/bin/bash

BASEDIR=/Users/kellinge/egw2fbox
BINDIR=$BASEDIR/bin
CONFDIR=$BASEDIR/etc
DATADIR=$BASEDIR/data
# create data files viewable for user only
umask 077

cd $BASEDIR

# call the magic perl script
$BINDIR/egw2fbox.pl -c $CONFDIR/egw2fbox.conf

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
