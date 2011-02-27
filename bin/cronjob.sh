#!/bin/bash

### FUNCS
function verbose {
	if [ -n "$VERBOSE" ]
	then
		echo "$0: $1"
	fi
}

### INIT
# read command line option: cronjob.sh -c config.file 
while getopts "c:v" flag
do
  case "$flag" in
	c)
		CONFIGFILE=$OPTARG
		;;
	v)
		VERBOSE=1
		;;
  esac
done

# read config file
verbose "reading config file..."
if [ -z $CONFIGFILE ]
then
	echo "you must supply a config file using the -c argument"
	exit 253

elif [ ! -f "$CONFIGFILE" ]
then
	echo "could not open config file"
	exit 254
fi

BASEDIR=$(grep "CRON_BASEDIR" $CONFIGFILE | cut -d"=" -f2|sed "s/ //g"|sed "s/\/\+$//")

if [ ! -d "$BASEDIR" ]; then
	echo "basedir $BASEDIR not found or is not a directory"
	exit 252
fi

BINDIR=$BASEDIR/bin
DATADIR=$BASEDIR/data


### DO WORK
# create data files viewable for user only
umask 077

cd $BASEDIR

# call the magic perl script
if [ -n "$VERBOSE" ]
then
	verbose "about to start the worker script in verbose mode"
	EGW2FBOX_ARGS="-c $CONFIGFILE -v"
else
	verbose "about to start the worker script"
	EGW2FBOX_ARGS="-c $CONFIGFILE"
fi

$BINDIR/egw2fbox.pl $EGW2FBOX_ARGS
if [ $? -ne 0 ]; then
	echo "egroupware exporter did not finish correctly"
	exit 251
else
	verbose "worker script ended successfully"
fi

# hash
NEWHASH=$(cat $DATADIR/phonebook.xml | grep -v mod_time | md5sum | cut -d" " -f1)
OLDHASH=$(cat $DATADIR/phonebook.hash 2>/dev/null)

if [ "_$OLDHASH" = "_$NEWHASH" ]
then
	verbose "hashes of last and new output xml do not differ, not updating fritzbox"
else
	verbose "now uploading new XML file to FritzBox"
	export FRITZUPLOADERCFG=$CONFIGFILE
	$BINDIR/fritzuploader.pl

	if [ $? -eq 0 ]; then
		# only persist new hash if fritzuploader has run correctly
		# in case of i. e. network problems that one should fail and
		# make this wrapper script recognize that another upload is
		# needed
		echo $NEWHASH >$DATADIR/phonebook.hash
		verbose "upload succeeded"
	else
		verbose "upload could not be finished correctly"
	fi
fi
