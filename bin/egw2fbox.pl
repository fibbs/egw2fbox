#!/usr/bin/perl
##### START: Documentation HEAD in POD format #####
=pod

=head1 NAME

egw2fbox.pl

=head1 DESCRIPTION

The purpose of this script is to run on a server and provide an automated way of sharing eGroupware 
hosted phone numbers and e-mail addresses with clients not supporting any other server based 
synchronization.

The phone numbers and e-mail addresses are read from the eGroupware database table I<contacts> and 
exports in the native format of each clients.

Because the supported clients have very limited address book capabilities, this is a one-way communication 
only. Hence, client side changes are not reported back to eGroupware and the client address books 
should be configured to be readonly as much as possible.

Further, F<egw2fbox.pl> had build-in functionality called I<lazy update> to reduce write cycles as much as 
possible. This reduces CPU time but - more important - also reduces the need for uploading data to clients
where continuous writing would have disadvantages. One example the FritzBox address 
book that stores the addresses in flash memory. Flash memory has a limited amount of possible writes.
But F<egw2fbox.pl> can be safely used because it avoids unnecessary write cycles as much as possible.

Currently supported clients are:

=over 3

=item phone numbers:

- Fritz Box router address book

=item e-mail addresses:

- Round Cube web mailer including personal and global address book

- MUTT command line mail client

=back

For uploading the created XML address book to a Fritz Box a small perl script called FritzUploader from Jan-Piet Mens is used.

=head1 SYNOPSIS

C<<< egw2fbox.pl [--verbose] [-v] [--config filename.ini] [-c filename.ini] [--version] [--help] [-h] [-?] [--man] [--changelog] >>>

=head1 OPTIONS

Runtime:

=over 15

=item --verbose -v

Logs to STDOUT while executing the script.

=item --config filename.ini   -c filename.ini

File name containing all configuration.

See sections CONFIG FILE and TUTORIALS for further information.

=back

Documentation:

=over 15

=item --version

Prints the version numbers.

=item --help -h -?

Print a brief help message.

=item --man

Prints the complete manual page.

=item --changelog

Prints the change log.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2014 by Christian Anton <mail@christiananton.de>, Kai Ellinger <coding@blicke.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

=cut
# What is my current version number?
# For compatibility reasons use 0.01.02 instead of 0.1.2 
BEGIN { $VERSION = "0.08.03"; }
=pod

=head1 HISTORY

 0.08.03 2014-02-18 Christian Anton <mail@christiananton.de>, Kai Ellinger <coding@blicke.de>
      Moving code to github, adding README.md

 0.08.02 2013-10-03 Kai Ellinger <coding@blicke.de>
      Fixed bin/fritzuploader.pl in order to work with new Fritzbox firmware versions 
       See: https://github.com/jpmens/fritzuploader/issues/1

 0.08.01 2011-05-05 Kai Ellinger <coding@blicke.de>
       Documentation:
       - Finished API docs
       - Creating 'bin/create_docs.sh' and related files under 'docs' directory
       - Creating minor versions of INSTALL and CONFIG FILE sections

 0.08.00 2011-04-05 Kai Ellinger <coding@blicke.de>
       Documentation:
       - Started implementing the documentation via perlpod
       - Implemented command line options:
         [--version] [--help] [-h] [-?] [--man] [--changelog]

 0.07.01 2011-03-30 Kai Ellinger <coding@blicke.de>
       Round Cube DB:
       - Fixed bug that not set value for 'email', 'name', 'firstname' or 'surname' 
         column causes SQL errors. 'email', 'name', 'firstname' will never be NULL
         due to the implementation. But 'surname' might.
       - Checking $userId, $changed and $sth as well
       - Don't let the whole script fail if $userId or $sth is NULL. Only roll back 
         the Round Cube DB transaction!

 0.07.00 2011-03-29 Kai Ellinger <coding@blicke.de>
       - Lazy Update implemented
       - Implemented dedicated EGW user lists FBOX_EGW_ADDRBOOK_OWNERS, RCUBE_EGW_ADDRBOOK_OWNERS, MUTT_EGW_ADDRBOOK_OWNERS
         in addition to already existing global EGW user list EGW_ADDRBOOK_OWNERS

 0.06.00 2011-03-28 Kai Ellinger <coding@blicke.de>
       RoundCube:
       - It turned out that the current state of the implementation already 
         supports global address books in Round Cube. Successfully tested!
       - You need to install the Round Cube plug in 'globaladdressbook' first.
         Download: http://trac.roundcube.net/wiki/Plugin_Repository

       Cronjob.sh:
       - Moving hard coded variables from cronjob.sh to egw2fbox.conf:
          * CRON_FBOX_XML_HASH, CRON_FBOX_UPLOAD_SCRIPT
       - Added comment awareness of config file parser in cronjob.sh

       Update clients only if EGW contacts changed for defined EGW user:
       - Preparation of egw2fbox.conf for lazy update feature:
          * EGW_LAZY_UPDATE_TIME_STAMP_FILE, FBOX_LAZY_UPDATE, RCUBE_LAZY_UPDATE, MUTT_LAZY_UPDATE

       Allow defining a different EGW user list for each client:
       - Preparation of egw2fbox.conf for defining different EGW address book owners per each client
          * FBOX_EGW_ADDRBOOK_OWNERS, RCUBE_EGW_ADDRBOOK_OWNERS, MUTT_EGW_ADDRBOOK_OWNERS

 0.05.04 2011-03-28 Kai Ellinger <coding@blicke.de>
       - Removing need for $egw_address_data being an global variable to be able to 
         sync different user / group address books for different clients
       - Making egw_read_db() flexible to return addresses for different address book owners
       - Caching EGW addresses to avoid DB access
       - egw_read_db() now retuning last modified time stamp to stop writing data to external
         client if not modified since last run, if MAIN calling export routine supports this

 0.05.03 2011-03-10 Kai Ellinger <coding@blicke.de>
       - implemented SQL part of round cube address book sync but
         still check field size before inserting into DB needs tbd

 0.05.02 2011-03-08 Kai Ellinger <coding@blicke.de>
       - started implementing round cube address book sync because I feel it is urgent ;-)
         did not touch any SQL code, need to update all TO DOs with inserting SQL code
       - remove need for $FRITZXML being a global variable

 0.05.01 2011-03-04 Christian Anton <mail@christiananton.de>
       - tidy up code to fulfill Perl::Critic tests at "gentle" severity:
       http://www.perlcritic.org/

 0.05.00 2011-03-04 Christian Anton <mail@christiananton.de>, Kai Ellinger <coding@blicke.de>
       - data is requested from DB in UTF8 and explicitly converted in desired encoding
         inside of fbox_write_xml_contact function
       - mutt export function now writes aliases file in UTF-8 now. If you use anything
         different - you're wrong!
       - fixed bug: for private contact entries in FritzBox the home number was taken from
         database field tel_work instead of tel_home
       - extended fbox_reformatTelNr to support local phone number annotation to work around
         inability of FritzBox to rewrite phone number for incoming calls

 0.04.00 2011-03-02 Kai Ellinger <coding@blicke.de>
       - added support for mutt address book including an example file showing 
         how to configure ~/.muttrc to support a local address book and a global
         EGW address book
       - replaced time stamp in fritz box xml with real time stamp from database
         this feature is more interesting for round cube integration where we have
         a time stamp field in the round cube database
       - added some comments

 0.03.00 2011-02-26 Kai Ellinger <coding@blicke.de>
       - Verbose function:
          * only prints if data was provided
          * avoiding unnecessary verbose function calls
          * avoiding runtime errors due to uninitialized data in verbose mode
       - Respect that Fritzbox address book names can only have 25 characters
       - EGW address book to Fritz Box phone book mapping:
         The Fritz Box Phone book knows 3 different telephone number types:
           'work', 'home' and 'mobile'
         Each Fritz Box phone book entry can have up to 3 phone numbers.
         All 1-3 phone numbers can be of same type or different types.
         * Compact mode (if one EGW address has 1-3 phone numbers):
            EGW field tel_work          -> FritzBox field type 'work'
            EGW field tel_cell          -> FritzBox field type 'mobile'
            EGW field tel_assistent     -> FritzBox field type 'work'
            EGW field tel_home          -> FritzBox field type 'home'
            EGW field tel_cell_private  -> FritzBox field type 'mobile'
            EGW field tel_other         -> FritzBox field type 'home'
           NOTE: Because we only have 3 phone numbers, we stick on the right number types.
         * Business Fritz Box phone book entry (>3 phone numbers):
            EGW field tel_work          -> FritzBox field type 'work'
            EGW field tel_cell          -> FritzBox field type 'mobile'
            EGW field tel_assistent     -> FritzBox field type 'home'
           NOTE: On hand sets, the list order is work, mobile, home. That's why the
                 most important number is 'work' and the less important is 'home' here.
         * Private Fritz Box phone book entry (>3 phone numbers):
            EGW field tel_home          -> FritzBox field type 'work'
            EGW field tel_cell_private  -> FritzBox field type 'mobile'
            EGW field tel_other         -> FritzBox field type 'home'
           NOTE: On hand sets, the list order is work, mobile, home. That's why the
                 most important number is 'work' and the less important is 'home' here.
        - Added EGW DB connect string check
        - All EGW functions have now prefix 'egw_', all Fritz Box functions prefix
          'fbox_' and all Round Cube functions 'rcube_' to prepare the source for
          adding the round cube sync.

 0.02.00 2011-02-25 Christian Anton <mail@christiananton.de>
          implementing XML-write as an extra function and implementing COMPACT_MODE which
          omits creating two contact entries for contacts which have only up to three numbers

 0.01.00 2011-02-24 Kai Ellinger <coding@blicke.de>, Christian Anton <mail@christiananton.de>
          Initial version of this script, ready for world domination ;-)

=head1 INSTALLATION

- A current version of B<PERL> is needed. F<egw2fbox.pl> requires module DBI and DBD::Mysql. 
F<fritzuploader.pl> requires module XML::Simple. All other modules needed to run the script 
are part of the standard perl library and don't need to be installed.

- Clone the head revision from L<https://github.com/fibbs/egw2fbox>

- Copy file F<etc/egw2fbox.conf.default> to F<etc/egw2fbox.conf> and update values according to your needs

- Test in verbose mode: C<<< /path/to/egw2fbox/bin/cronjob.sh -v -c /path/to/egw2fbox/etc/egw2fbox.conf >>>

- Add to your crontab:

C<<< */20 * * * * /path/to/egw2fbox/bin/cronjob.sh -c /path/to/egw2fbox/etc/egw2fbox.conf >>>

=head1 CONFIG FILE

This section may later describes the structure of the INI file used by this script. 
Until now, see the comments in F<egw2fbox.conf.default>.

* File F<egw2fbox.pl> uses command line option C<-config /path/to/fileName.ini>, default is F<egw2fbox.conf>.

* File F<cronjob.sh> uses command line option C<-c /path/to/fileName.ini>, no default value.

* File F<fritzuploader.pl> searches for the value of environment variable FRITZUPLOADERCFG, default is F<fritzuploader.conf>.

=head2 eGoupware section

Configuration settings related to the eGroupware database

=head2 FritzBox section

Configuration settings related to the Fritz Box

=head2 Round Cube section

Configuration settings related to the Round Cube database

=head2 MUTT section

Configuration settings related to MUTT

=head1 API

=cut
##### END: Documentation HEAD in POD format #####


#### modules

##### START: perl module requirements ##### 
=pod

=head2 Required Perl modules

Most Perl modules used by this program are part of the standard perl library perlmodlib L<http://perldoc.perl.org/perlmodlib.html> and are installed by default.

The only modules that might not be available by default are to access the MySQL database and are named DBI and DBD::Mysql.

=cut
##### END: perl module requirements #####
# see http://perldoc.perl.org/perlmodlib.html for what is provided via perlmodlib
use warnings;     # installed by default via perlmodlib
use strict;       # installed by default via perlmodlib

use Getopt::Long qw(:config autoversion); # installed by default via perlmodlib
use Pod::Usage;   # installed by default via perlmodlib
use DBI;          # not included in perlmodlib: DBI and DBD::Mysql needs to be installed if not already done
use Data::Dumper;            # installed by default via perlmodlib
use List::Util qw [min max]; # installed by default via perlmodlib
use Encode;       # installed by default via perlmodlib
use Storable;     # installed by default via perlmodlib


#### global variables
## config
my $o_verbose;
my $o_configfile = "egw2fbox.conf";
my $cfg;

# buffer EGW database querry results for further use and avoid updates if nothing changed
my $cachedEgwAddressBookData;
my $oldEgwTimeStamps;
my $lazyUpdateConfigured = 0;

## fritz box config parameters we don't like to be modified without thinking
# the maximum number of characters that a Fritz box phone book name can have
my $FboxMaxLenghtForName = 32;
# Maybe the code page setting changes based on Fritz Box language settings
# and must vary for characters other than germany special characters.
# This variable can be used to specify the code page used at the exported XML.
my $FboxAsciiCodeTable = "iso-8859-1"; #


#### function section

##### START: function documentation ##### 
=pod

=head2 Function check_args ()

This function is checking command line options and printing help messages if requested.

IN: No parameter

OUT: Returns nothing

=cut
##### END: function documentation #####
sub check_args {
	my $o_info_help = 0;
	my $o_info_changelog = 0;
	my $o_info_man = 0;
	
	Getopt::Long::Configure ("bundling");
	#if(!
		GetOptions(
			'v'   => \$o_verbose,     'verbose'   => \$o_verbose,
			'c:s' => \$o_configfile,  'config:s'  => \$o_configfile,
			# don't need to check for 'version|v' if using Getopt::Long qw(:config autoversion) and not implementing those options myself
			# could use Getopt::Long qw(:config autohelp) here but like to include OPTIONS section
			'help|h|?' => \$o_info_help,
			'changelog' => \$o_info_changelog,
			'man' => \$o_info_man
		);
	#)
	### print help on option error or no option
	#{ pod2usage(-verbose => 99, -sections => "NAME|SYNOPSIS|OPTIONS"); }
	
	### print help if requested
	pod2usage(-verbose => 99, -sections => "NAME|SYNOPSIS|OPTIONS") if ($o_info_help);
	
	### version is implemented by Getopt::Long qw(:config autoversion)
	
	### change log
	pod2usage(-verbose => 99, -sections => "NAME|HISTORY") if($o_info_changelog);
	
	### complete man page
	pod2usage(-verbose => 2) if ($o_info_man);
	
	# TODO - maybe a parameter per each client to force sync even if XXX_LAZY_UPDATE = 1 is set
}

##### START: function documentation ##### 
=pod

=head2 Function parse_config ()

This function is parsing the config file given by command line option '-c filename.ini'.

IN: No parameter

OUT: Returns nothing

=cut
##### END: function documentation #####
sub parse_config {
	# - we are not using perl module Config::Simple here because it was not installed
	#   on our server by default and we saw compile errors when trying to install it via CPAN
	# - we decided to implement our own config file parser to keep the installation simple 
	#   and let the script run with as less dependencies as possible
	my $CFGFILE;
	if(! open ($CFGFILE, '<', "$o_configfile") ) {
		warn "ERROR: could not open config file '$o_configfile': $!\n\n";
		pod2usage(-verbose => 99, -sections => "NAME|SYNOPSIS");
	} # changed to return a usage info in case no or a wrong file name was given

	while(defined(my $line = <$CFGFILE>) )
	{
		chomp $line;
		$line =~ s/#.*//g;
		$line =~ s/\s+$//;
		next if $line !~ /=/;
		$line =~ s/\s*=\s*/=/;
		$line =~ /^([^=]+)=(.*)/;
		my $key = $1;
		my $value = $2;

		$cfg->{$key} = $value;
	}
	close $CFGFILE;

}

##### START: function documentation ##### 
=pod

=head2 Function verbose (STRING message)

Printing out verbose messages if verbose mode is enabled.

IN: Takes the message to print out

OUT: Returns nothing

=cut
##### END: function documentation #####
sub verbose{
	my $msg = shift;
	if ($o_verbose && $msg) {
		print "$msg\n";
	}
}

##### START: function documentation ##### 
=pod

=head2 Function sort_user_id_list (STRING user_id_list)

This function is called by function find_EGW_user (STRING user_id_list) to sort 
the user list it looked up before.

This is needed to avoid unnecessary database accesses even the config parameters EGW_ADDRBOOK_OWNERS, 
FBOX_EGW_ADDRBOOK_OWNERS, RCUBE_EGW_ADDRBOOK_OWNERS and MUTT_EGW_ADDRBOOK_OWNERS list 
the user ids in different order and with different wide spaces.

The default Perl sort algorithm is used even if it is not a numeric algorithm. But this is not needed anyway.

IN: Takes an unsorted user id list string

OUT: Returns a sorted user id list string

=cut
##### END: function documentation #####
# this is to have EGW user list '1,2,3', '1, 2, 3' and '2,   3 ,1' converted to the same value
# otherwise different egw2fbox.conf values for the same user ids would result in not using the cached values
sub sort_user_id_list{
	my $user_id_string = shift;
	verbose("sort_user_id_list() Got unsorted list: '" . $user_id_string . "'");
	
	# removing all wide spaces
	$user_id_string =~ s/\s*//g;
	
	# if we have more than one user id
	if($user_id_string =~ /,/) {
		# split into a string
		my @user_id_list = split(/,/, $user_id_string);
		# the sort algorithm is unimportant as long as all values are sorted the same way
		# I know that this does not sort the values in a numeric way but I don't care
		my @user_id_list_sorted = sort @user_id_list;
		$user_id_string = "@user_id_list_sorted";
		$user_id_string =~ s/ /,/g;
		
	}
	verbose("sort_user_id_list() Returning sorted list: '" . $user_id_string . "'");
	return $user_id_string;
}

##### START: function documentation ##### 
=pod

=head2 Function find_EGW_user (STRING config_parameter)

This function returns a sorted user id list string that is either defined by the global 
configuration parameter EGW_ADDRBOOK_OWNERS or one of the parameters
FBOX_EGW_ADDRBOOK_OWNERS, RCUBE_EGW_ADDRBOOK_OWNERS and MUTT_EGW_ADDRBOOK_OWNERS
to overwrite the global parameter.

IN: Config parameter name FBOX_EGW_ADDRBOOK_OWNERS, RCUBE_EGW_ADDRBOOK_OWNERS or MUTT_EGW_ADDRBOOK_OWNERS

OUT: Returns a sorted user id list string

=cut
##### END: function documentation #####
sub find_EGW_user {
	my $additional_user_list = shift;
	# value to return
	my $egwUserForThisClient;
	# default value, if defined
	if($cfg->{EGW_ADDRBOOK_OWNERS}) {
		verbose("find_EGW_user() - EGW_ADDRBOOK_OWNERS is set!");
		$egwUserForThisClient = sort_user_id_list($cfg->{EGW_ADDRBOOK_OWNERS});
	}
	# specific user, if defined
	if($cfg->{$additional_user_list}) {
		verbose("find_EGW_user() - $additional_user_list is set!");
		$egwUserForThisClient = sort_user_id_list($cfg->{$additional_user_list});
	}
	### verbose output
	if($o_verbose) {
		verbose("find_EGW_user() - found user list '$egwUserForThisClient'");
		if($oldEgwTimeStamps->{$egwUserForThisClient}) {
			verbose("find_EGW_user() - found old time stamp: '$oldEgwTimeStamps->{$egwUserForThisClient}'");
		} else {
			verbose("find_EGW_user() - NO old time stamp!");
		}
	}
	return $egwUserForThisClient;
}

##### START: function documentation ##### 
=pod

=head2 Function egw_read_db (STRING user_id_list)

Connects to eGroupware database and looks up address book values for the given user id list including time stamp of last change.

IN: User id list to lookup

OUT: Returns two parameters:

- all address data belonging to the user list

- the time stamp when this list was modified the last time

=cut
##### END: function documentation #####
sub egw_read_db {
	# List of owners to return address book entries for
	my $egw_user_name_list = shift;
	
	# eGroupware info to return
	my $egw_address_data;
	my $egw_address_modified;
	
	
	# DB related handles
	my $dbh;
	# data
	my $sth_data;
	my $sql_data;
	# last modified
	my $sth_mod;
	my $sql_mod;
	

	# default values for DB connect
	if (!$cfg->{EGW_DBHOST}) { $cfg->{EGW_DBHOST} = 'localhost'; }
	if (!$cfg->{EGW_DBPORT}) { $cfg->{EGW_DBPORT} = 3306; }
	if (!$cfg->{EGW_DBNAME}) { $cfg->{EGW_DBNAME} = 'egroupware'; }
	# don't set default values for DB user and password
	die "ERROR: EGW database can't be accessed without DB user name or password set!"
		if( !($cfg->{EGW_DBUSER}) || !($cfg->{EGW_DBPASS}) );

	my $dsn = "dbi:mysql:$cfg->{EGW_DBNAME}:$cfg->{EGW_DBHOST}:$cfg->{EGW_DBPORT}";
	$dbh = DBI->connect($dsn, $cfg->{EGW_DBUSER}, $cfg->{EGW_DBPASS}) or die "could not connect db: $!";
	# read database via UTF8; convert in print function if needed
	$dbh->do("SET NAMES utf8");
	# convert UTF8 values inside EGW DB to latin1 because Fritz Box expects German characters in iso-8859-1
	#$dbh->do("SET NAMES latin1");  # latin1 is good at least for XML files created with iso-8859-1
	
	#  mysql> describe egw_addressbook;
	#  +----------------------+--------------+------+-----+---------+----------------+
	#  | Field                | Type         | Null | Key | Default | Extra          |
	#  +----------------------+--------------+------+-----+---------+----------------+
	#  | contact_id           | int(11)      | NO   | PRI | NULL    | auto_increment | 
	#  | contact_tid          | varchar(1)   | YES  |     | n       |                | 
	#  | contact_owner        | bigint(20)   | NO   | MUL | NULL    |                | 
	#  | contact_private      | tinyint(4)   | YES  |     | 0       |                | 
	#  | cat_id               | varchar(255) | YES  | MUL | NULL    |                | 
	#  | n_family             | varchar(64)  | YES  | MUL | NULL    |                | 
	#  | n_given              | varchar(64)  | YES  | MUL | NULL    |                | 
	#  | n_middle             | varchar(64)  | YES  |     | NULL    |                | 
	#  | n_prefix             | varchar(64)  | YES  |     | NULL    |                | 
	#  | n_suffix             | varchar(64)  | YES  |     | NULL    |                | 
	#  | n_fn                 | varchar(128) | YES  |     | NULL    |                | 
	#  | n_fileas             | varchar(255) | YES  | MUL | NULL    |                | 
	#  | contact_bday         | varchar(12)  | YES  |     | NULL    |                | 
	#  | org_name             | varchar(128) | YES  | MUL | NULL    |                | 
	#  | org_unit             | varchar(64)  | YES  |     | NULL    |                | 
	#  | contact_title        | varchar(64)  | YES  |     | NULL    |                | 
	#  | contact_role         | varchar(64)  | YES  |     | NULL    |                | 
	#  | contact_assistent    | varchar(64)  | YES  |     | NULL    |                | 
	#  | contact_room         | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_street       | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_street2      | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_locality     | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_region       | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_postalcode   | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_one_countryname  | varchar(64)  | YES  |     | NULL    |                | 
	#  | contact_label        | text         | YES  |     | NULL    |                | 
	#  | adr_two_street       | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_two_street2      | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_two_locality     | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_two_region       | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_two_postalcode   | varchar(64)  | YES  |     | NULL    |                | 
	#  | adr_two_countryname  | varchar(64)  | YES  |     | NULL    |                | 
	#  | tel_work             | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_cell             | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_fax              | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_assistent        | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_car              | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_pager            | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_home             | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_fax_home         | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_cell_private     | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_other            | varchar(40)  | YES  |     | NULL    |                | 
	#  | tel_prefer           | varchar(32)  | YES  |     | NULL    |                | 
	#  | contact_email        | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_email_home   | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_url          | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_url_home     | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_freebusy_uri | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_calendar_uri | varchar(128) | YES  |     | NULL    |                | 
	#  | contact_note         | text         | YES  |     | NULL    |                | 
	#  | contact_tz           | varchar(8)   | YES  |     | NULL    |                | 
	#  | contact_geo          | varchar(32)  | YES  |     | NULL    |                | 
	#  | contact_pubkey       | text         | YES  |     | NULL    |                | 
	#  | contact_created      | bigint(20)   | YES  |     | NULL    |                | 
	#  | contact_creator      | int(11)      | NO   |     | NULL    |                | 
	#  | contact_modified     | bigint(20)   | NO   |     | NULL    |                | 
	#  | contact_modifier     | int(11)      | YES  |     | NULL    |                | 
	#  | contact_jpegphoto    | longblob     | YES  |     | NULL    |                | 
	#  | account_id           | int(11)      | YES  | UNI | NULL    |                | 
	#  | contact_etag         | int(11)      | YES  |     | 0       |                | 
	#  | contact_uid          | varchar(255) | YES  | MUL | NULL    |                | 
	#  +----------------------+--------------+------+-----+---------+----------------+

	# read last modified time stamp
	$sql_mod = "
		SELECT
			MAX(`contact_modified`)
		FROM
			`egw_addressbook`
		WHERE
			`contact_owner` IN ( $egw_user_name_list )
	";
	
	$sth_mod = $dbh->prepare($sql_mod);
	$sth_mod->execute;
	my @egw_address_modified_array = $sth_mod->fetchrow_array;
	$egw_address_modified = $egw_address_modified_array[0];
	verbose("egw_read_db() last addess modify time stamp for user(s) '$egw_user_name_list' is '$egw_address_modified'!");
	# SQL close statement handle after use
	$sth_mod->finish;

	# read address book data
	$sql_data = "
		SELECT
			`contact_id`,
			`n_prefix`,
			`n_fn`,
			`n_given`,
			`n_middle`,
			`n_family`,
			`tel_work`,
			`tel_cell`,
			`tel_assistent`,
			`tel_home`,
			`tel_cell_private`,
			`tel_other`,
			`contact_email`,
			`contact_email_home`,
			`contact_modified`
		FROM
			`egw_addressbook`
		WHERE
			`contact_owner` IN ( $egw_user_name_list )
	";
#			`contact_owner` IN ( $cfg->{EGW_ADDRBOOK_OWNERS} )


	$sth_data = $dbh->prepare($sql_data);
	$sth_data->execute;

	$egw_address_data = $sth_data->fetchall_hashref('contact_id');
	# SQL close statement handle after use
	$sth_data->finish;

	#print "Name for id 57 is $egw_address_data->{57}->{n_fn}\n";
	my $amountData = keys(%{$egw_address_data});
	verbose("egw_read_db() found $amountData data rows in egw addr book");

	die "no data for owner(s) $cfg->{ADDRBOOK_OWNERS} found" if ( 0 == $amountData );

	# Disconnect from DB
	$dbh->disconnect or warn "error diconnecting from EGW database: " . $dbh->errstr;
	
	# Return found addresses
	return $egw_address_data, $egw_address_modified;
}


##### START: function documentation ##### 
=pod

=head2 Function fbox_reformatTelNr (STRING phone_number)

This is a helper function called by function fbox_write_xml_contact format the phone number in a way that the Fritz Box can resolve it.
How the phone number is formatted exactly is defined in the fritz box configuration section of the config file. 

First, each phone number is re-formatted like 00498912345678. Later the phone numbers with the same country code or with the same area code 
get the leading numbers removed if configured. 

This is needed because the Fritz Box can not recognize that phone number 00498912345678 is the same as 08912345678 calling from the 
same country is the same as 12345678 calling from the same city. But the right phone number syntax is very important to get the names 
resolved for incoming calls as well as to replace the phone numbers with the names in the phone call protocols maintain
that can either be viewed via web console or mail. Same is true for the incoming mail box calls that can be forwarded via e-mail as well.

IN: Phone number in any format it can exist in eGrouware

OUT: Phone number formatted in a way that the Fritz Box can resolve incoming calls correctly

=cut
##### END: function documentation #####
sub fbox_reformatTelNr {
	my $nr = shift;

	# this function will most likely _not_ work in countries using the north american numbering plan
	# if you use a FritzBox in one of these states, fix this function and submit changes to us
	# http://en.wikipedia.org/wiki/North_American_Numbering_Plan

	# first rewrite all phone numbers to international format: 
	# 004912345678 (where 00 is FBOX_INTERNATIONAL_ACCESS_CODE)
	$nr =~ s/^\+/$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}/;

	# dele all non-decimals
	$nr =~ s/[^\d]+//g;

	# change national numbers starting with FBOX_NATIONAL_ACCESS_CODE + FBOX_MY_AREA_CODE to the same 
	# format (i.e. 08935350 -> 004935350)
	if(!($nr =~ /^$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}/) && ($nr =~ /^$cfg->{FBOX_NATIONAL_ACCESS_CODE}/) ) {
		$nr =~  s/^$cfg->{FBOX_NATIONAL_ACCESS_CODE}/$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}$cfg->{FBOX_MY_COUNTRY_CODE}/;
	}

	# change all local numbers NOT starting with FBOX_INTERNATIONAL_ACCESS_CODE to be in the same format
	# i.e. 12345 -> 00498912345
	if(!($nr =~ /^$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}/) ) {
		$nr =~ s/^/$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}$cfg->{FBOX_MY_COUNTRY_CODE}$cfg->{FBOX_MY_AREA_CODE}/;
	}

	# from here on we have universal peace! All phone numbers are in same format!
	# depending on configuration options we reformat numbers now to ensure that FritzBox can resolve phone numbers
	# of incoming calls to real names

	if ($cfg->{FBOX_DELETE_MY_COUNTRY_CODE}) {

		# numbers of my area
		if ($cfg->{FBOX_DELETE_MY_AREA_CODE}) {
			$nr =~ s/^$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}$cfg->{FBOX_MY_COUNTRY_CODE}$cfg->{FBOX_MY_AREA_CODE}//;
		}

		# numbers of my country
		$nr =~ s/^$cfg->{FBOX_INTERNATIONAL_ACCESS_CODE}$cfg->{FBOX_MY_COUNTRY_CODE}/$cfg->{FBOX_NATIONAL_ACCESS_CODE}/;
	}

	return $nr;
}

##### START: function documentation ##### 
=pod

=head2 Function fbox_write_xml_contact (HANDLE xml_file, STRING contact_name, STRING contact_name_suffix, ARRAY REF phone_numbers, NUMBER timestamp)

This is a function called by function fbox_gen_fritz_xml for each single contact that needs to be written to the 
XML file. The contact name is formatted to fit into the restrictions of  the Fritz Box and the phones connected to it.

IN: 

- handle for XML file

- contact_name

- contact_name_suffix = shift;

- array ref with all phone numbers

- timestamp of last update in eGroupware DB

OUT: Nothing

=cut
##### END: function documentation #####
sub fbox_write_xml_contact {
	my $FRITZXML = shift;
	my $contact_name = shift;
	my $contact_name_suffix = shift;
	my $numbers_array_ref = shift;
	my $now_timestamp = shift;
	my $name_length;
	my $output_name;

	# convert output name to character encoding as defined in $FboxAsciiCodeTable
	# only contact name and contact name's suffix can contain special chars
	Encode::from_to($contact_name, "utf8", $FboxAsciiCodeTable);
	Encode::from_to($contact_name_suffix, "utf8", $FboxAsciiCodeTable);
	
	# reformat name according to max length and suffix
	if ($contact_name_suffix) {
		$name_length = min($cfg->{FBOX_TOTAL_NAME_LENGTH},$FboxMaxLenghtForName) - 1 - length($contact_name_suffix);
		$output_name = substr($contact_name,0,$name_length);
		$output_name =~ s/\s+$//;
		$output_name = $output_name . " " . $contact_name_suffix;
	} else {
		$name_length = min($cfg->{FBOX_TOTAL_NAME_LENGTH},$FboxMaxLenghtForName);
		$output_name = substr($contact_name,0,$name_length);
		$output_name =~ s/\s+$//;
	}
	
	# print the top XML wrap for the contact's entry
	print $FRITZXML "<contact>\n<category>0</category>\n<person><realName>$output_name</realName></person>\n";
	print $FRITZXML "<telephony>\n";

	foreach my $numbers_entry_ref (@$numbers_array_ref) {
		# not defined values causing runtime errors
		$o_verbose && verbose ("fbox_write_xml_contact()   type: ". ($numbers_entry_ref->{'type'} || "<undefined>") . " , number: ". ($numbers_entry_ref->{'nr'}|| "<undefined>")  );
		if ($$numbers_entry_ref{'nr'}) {
			print $FRITZXML "<number type=\"$$numbers_entry_ref{'type'}\" vanity=\"\" prio=\"0\">" .
				fbox_reformatTelNr($$numbers_entry_ref{'nr'}) .
				"</number>\n";
		}
	}

	# print the bottom XML wrap for the contact's entry
	print $FRITZXML "</telephony>\n";
	print $FRITZXML "<services /><setup /><mod_time>$now_timestamp</mod_time></contact>";
}

##### START: function documentation ##### 
=pod

=head2 Function fbox_count_contacts_numbers (HASH REF egw_address_data, STRING key_to_search)

This is a function called by function fbox_gen_fritz_xml for each single contact found in the eGroupware address book to 
know how many phone numbers this contact has. If there are no phone numbers, this contact must not imported to the Fritz Box.
If there are more than 3 phone numbers, the contact must be split into a business contact and a private contact because
the Fritz Box can only hold 3 phone numbers per contact.

IN: 

- HASH REF the address list to search

- STRING key of the address that needs to be searched from the list

OUT: NUMBER count of found phone numbers

=cut
##### END: function documentation #####
sub fbox_count_contacts_numbers {
	my $egw_address_data = shift;
	my $key = shift;
	my $count = 0;

	$count++ if ($egw_address_data->{$key}->{'tel_work'});
	$count++ if ($egw_address_data->{$key}->{'tel_cell'});
	$count++ if ($egw_address_data->{$key}->{'tel_assistent'});
	$count++ if ($egw_address_data->{$key}->{'tel_home'});
	$count++ if ($egw_address_data->{$key}->{'tel_cell_private'});
	$count++ if ($egw_address_data->{$key}->{'tel_other'});

	return $count;
}


##### START: function documentation ##### 
=pod

=head2 Function fbox_gen_fritz_xml (HASH REF egw_address_data)

This function creates the XML file to upload to the Fritz Box.

IN: HASH REF the address list

OUT: Nothing

=cut
##### END: function documentation #####
sub fbox_gen_fritz_xml {
	## eGroupware
	my $egw_address_data = shift;
	
	## taking modification time stamp from EGW DB instead
	# my $now_timestamp = time();

	# make file descriptor for XML output file global
	my $FRITZXML;
	
	# open file
	open ($FRITZXML, '>', $cfg->{FBOX_OUTPUT_XML_FILE}) or die "could not open file! $!";
	print $FRITZXML <<EOF;
<?xml version="1.0" encoding="${FboxAsciiCodeTable}"?>
<phonebooks>
<phonebook name="Telefonbuch">
EOF
	# data should look like this:
	# <contact>
	#   <category>0</category>
	#   <person>
	#     <realName>test user</realName>
	#   </person>
	#   <telephony>
	#     <number type="home" vanity="" prio="0">08911111</number>
	#     <number type="mobile" vanity="" prio="0">08911112</number>
	#     <number type="work" vanity="" prio="0">08911113</number>
	#   </telephony>
	#   <services />
	#   <setup />
	#   <mod_time>1298300800</mod_time>
	# </contact>

	## start iterate

	foreach my $key ( keys(%{$egw_address_data}) ) {
		my $contact_name = $egw_address_data->{$key}->{'n_fn'};
		verbose ("fbox_gen_fritz_xml() generating XML snippet for contact $contact_name");
		if ($egw_address_data->{$key}->{'n_prefix'}) {
			$contact_name =~ s/^$egw_address_data->{$key}->{'n_prefix'}\s*//;
		}

		my $number_of_numbers = 0;
		# counting phone numbers is only in compact mode needed
		if($cfg->{FBOX_COMPACT_MODE}) {
			$number_of_numbers = fbox_count_contacts_numbers($egw_address_data, $key);
			verbose ("fbox_gen_fritz_xml() contact has $number_of_numbers phone numbers defined");
			}

		if ( ($cfg->{FBOX_COMPACT_MODE}) && ($number_of_numbers <= 3) ){

			verbose ("fbox_gen_fritz_xml() entering compact mode for this contact entry");
			my @numbers_array;


			# tel_work belongs to business phone numbers in EGW
			if ($egw_address_data->{$key}->{'tel_work'}) {
				push @numbers_array, { type=>'work', nr=>$egw_address_data->{$key}->{'tel_work'} };
			}


			# tel_cell belongs to business phone numbers in EGW (work mobile)
			# setting type to 'mobile'; others might like to set it to 'work' instead
			if ($egw_address_data->{$key}->{'tel_cell'}) {
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell'} };
			}


			# tel_assistent belongs to business phone numbers in EGW
			if ($egw_address_data->{$key}->{'tel_assistent'}) {
				push @numbers_array, { type=>'work', nr=>$egw_address_data->{$key}->{'tel_assistent'} };
			}

			# tel_home belongs to private phone numbers in EGW
			if ($egw_address_data->{$key}->{'tel_home'}) {
				push @numbers_array, { type=>'home', nr=>$egw_address_data->{$key}->{'tel_home'} };
			}

			# tel_cell_private belongs to private phone numbers in EGW
			# setting type to 'mobile'; others might like to set it to 'home' instead
			if ($egw_address_data->{$key}->{'tel_cell_private'}) {
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell_private'} };
			}

			# tel_other belongs to private phone numbers in EGW
			if ($egw_address_data->{$key}->{'tel_other'}) {
				push @numbers_array, { type=>'home', nr=>$egw_address_data->{$key}->{'tel_other'} };
			}

			fbox_write_xml_contact($FRITZXML, $contact_name, '', \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});

		} else {

			verbose ("fbox_gen_fritz_xml() entering non-compact mode for this contact entry");

			# start print the business contact entry
			if (
				($egw_address_data->{$key}->{'tel_work'}) ||
				($egw_address_data->{$key}->{'tel_cell'}) ||
				($egw_address_data->{$key}->{'tel_assistent'})
			 ) {

				verbose ("fbox_gen_fritz_xml()  start writing the business contact entry");
				my @numbers_array;

				push @numbers_array, { type=>'home',   nr=>$egw_address_data->{$key}->{'tel_work'} };
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell'} };
				push @numbers_array, { type=>'work',   nr=>$egw_address_data->{$key}->{'tel_assistent'} };

				fbox_write_xml_contact($FRITZXML, $contact_name, $cfg->{FBOX_BUSINESS_SUFFIX_STRING}, \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});
			}
			# end print the business contact entry

			# start print the private contact entry
			if (
				($egw_address_data->{$key}->{'tel_home'}) ||
				($egw_address_data->{$key}->{'tel_cell_private'}) ||
				($egw_address_data->{$key}->{'tel_other'})
			) {

				verbose ("fbox_gen_fritz_xml()  start writing the private contact entry");
				my @numbers_array;

				push @numbers_array, { type=>'home',   nr=>$egw_address_data->{$key}->{'tel_home'} };
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell_private'} };
				push @numbers_array, { type=>'work',   nr=>$egw_address_data->{$key}->{'tel_other'} };

				fbox_write_xml_contact($FRITZXML, $contact_name, $cfg->{FBOX_PRIVATE_SUFFIX_STRING}, \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});
			}
			# end print the private contact entry
		}
		# end non-compact mode
	}
	## end iterate


	print $FRITZXML <<EOF;
</phonebook>
</phonebooks>
EOF
	close $FRITZXML;
}


##### START: function documentation ##### 
=pod

=head2 Function rcube_update_address_book (HASH REF egw_address_data)

This function the Round Cube database with names and e-mail addresses of the 
EGW address book by deleting the whole contacts table for the configured user 
and inserting each contact again. If there is any error, the whole DB transaction
is rolled back.

IN: HASH REF the address list

OUT: Nothing

=cut
##### END: function documentation #####
sub rcube_update_address_book {
	verbose ("rcube_update_address_book() updating round cube address book");
	
	## eGroupware data
	my $egw_address_data = shift;
	
	# TODO - a good boy would force the Round Cube address book to be updated even there has not been 
	#        any changes inside the EGW address book but some one updated the Round Cube address book 
	#      - this is because EGW is always the master and because any changes inside Round Cube do not
	#        make any sense and can't be synced back to EGW
	#      - if a user likes to have his own address book in Round Cube still, he can use a global 
	#        address book for the EGW data
	#      ..... but, I'm not perfect!
	
	## DB related handles
	my $dbh;
	# perldoc of DBI recommends a new handle for each SQL statement
	my $sql4insert; # the SQL statement should use bind variables
	# INSERT INTO `contacts` (`email`, `name`, `firstname`, `surname`, `user_id`, `changed`)
	# VALUES ($email, $name, $firstName, $familyName, $userId, $changed)
	$sql4insert = "INSERT INTO `contacts` (`email`, `name`, `firstname`, `surname`, `user_id`, `changed`) VALUES (?, ?, ?, ?, ?, ?)";
	my $sth4insert;

	# default values for DB connect
	if (!$cfg->{RCUBE_DBHOST}) { $cfg->{RCUBE_DBHOST} = 'localhost'; }
	if (!$cfg->{RCUBE_DBPORT}) { $cfg->{RCUBE_DBPORT} = 3306; }
	if (!$cfg->{RCUBE_DBNAME}) { $cfg->{RCUBE_DBNAME} = 'roundcubemail'; }
	# don't set default values for DB user and password
	die "ERROR: Round Cube database can't be accessed without DB user name or password set!"
		if( !($cfg->{RCUBE_DBUSER}) || !($cfg->{RCUBE_DBPASS}) );

	# SQL connect to the RCUBE database
	my $dsn = "dbi:mysql:$cfg->{RCUBE_DBNAME}:$cfg->{RCUBE_DBHOST}:$cfg->{RCUBE_DBPORT}";
	$dbh = DBI->connect($dsn, $cfg->{RCUBE_DBUSER}, $cfg->{RCUBE_DBPASS}) or die "could not connect db: $!";
	# access database via UTF8; convert in print function if needed
	$dbh->do("SET NAMES utf8");

	# wrap all into a DB transaction if the DB supports transactions to be able to rollback changes if any error occurred
	# Benefit: not deleting old data if there are any issues with inserting new data
	# See example: http://search.cpan.org/~timb/DBI-1.616/DBI.pm#Transactions

	# SQL START TRANSACTION
	$dbh->{AutoCommit} = 0;  # enable transactions, if possible
	$dbh->{RaiseError} = 1;
	eval {

		## we don't need any more because we have EGW field contact_modified
		#my $now_timestamp = time();
		#  mysql> describe contacts;
		#  +------------+------------------+------+-----+---------------------+----------------+
		#  | Field      | Type             | Null | Key | Default             | Extra          |
		#  +------------+------------------+------+-----+---------------------+----------------+
		#  | contact_id | int(10) unsigned | NO   | PRI | NULL                | auto_increment | 
		#  | changed    | datetime         | NO   |     | 1000-01-01 00:00:00 |                | 
		#  | del        | tinyint(1)       | NO   |     | 0                   |                | 
		#  | name       | varchar(128)     | NO   |     |                     |                | 
		#  | email      | varchar(255)     | NO   |     | NULL                |                | 
		#  | firstname  | varchar(128)     | NO   |     |                     |                | 
		#  | surname    | varchar(128)     | NO   |     |                     |                | 
		#  | vcard      | text             | YES  |     | NULL                |                | 
		#  | user_id    | int(10) unsigned | NO   | MUL | 0                   |                | 
		#  +------------+------------------+------+-----+---------------------+----------------+
		### Round Cube table to EGW table field mapping:
		# contact_id = auto
		# changed = contact_modified
		# name = n_fn - n_prefix + (RCUBE_BUSINESS_SUFFIX_STRING|RCUBE_PRIVATE_SUFFIX_STRING according to type of e-mail address)
		# email = (contact_email|contact_email_home)
		# firstname = n_given + n_middle
		# surname = n_family
		# vcard = null
		# user_id = RCUBE_ADDRBOOK_OWNERS per each value (can be multiple)
		###
		# NOTE: Need to cut strings to place into name, email, firstname, surname
		###

		# SQL DELETE old contacts for specified users
		# perldoc of DBI recommends a new handle for each SQL statement
		my $sth4delete = $dbh->prepare("DELETE FROM `contacts` WHERE `user_id` IN (?)");
		foreach my $userId ( split(',', $cfg->{RCUBE_ADDRBOOK_OWNERS} ) ) {
			$o_verbose && verbose "rcube_update_address_book() Deleting RCUBE addresses for user id: -$userId-";
			verbose "rcube_update_address_book() Returning: " . $sth4delete->execute( $userId );
		}
		# SQL close statement handle after use
		$sth4delete->finish;

		# SQL prepare INSERT statement to be re-used for better performance inside script
		$sth4insert = $dbh->prepare($sql4insert);

		# Insert contact details for contacts having mail addresses specified
		foreach my $key ( keys(%{$egw_address_data}) ) {
			my $contact_name = $egw_address_data->{$key}->{'n_fn'};
			verbose ("rcube_update_address_book() generating rcube address book for contact $contact_name");

			# if there is a prefix such as Mr, Mrs, Herr Frau, remove it
			if ($egw_address_data->{$key}->{'n_prefix'}) {
				$contact_name =~ s/^$egw_address_data->{$key}->{'n_prefix'}\s*//;
			}

			# if first name exists
			my $first_name = "";
			if($egw_address_data->{$key}->{'n_given'}) { $first_name = $egw_address_data->{$key}->{'n_given'}; }
			if($egw_address_data->{$key}->{'n_middle'}) { $first_name = " " . $egw_address_data->{$key}->{'n_middle'}; }

			# each round cube user has his own address book
			foreach my $userId ( split(',', $cfg->{RCUBE_ADDRBOOK_OWNERS}) ) {

				# the business e-mail address
				if($egw_address_data->{$key}->{'contact_email'}) {
					my $full_name = $contact_name;
					# if suffix exists
					if($cfg->{RCUBE_BUSINESS_SUFFIX_STRING}) { $full_name .= " " . $cfg->{RCUBE_BUSINESS_SUFFIX_STRING}; }
					rcube_insert_mail_address(
						$sth4insert,
						$egw_address_data->{$key}->{'contact_email'},
						$full_name,
						$first_name,
						$egw_address_data->{$key}->{'n_family'},
						$userId,
						$egw_address_data->{$key}->{'contact_modified'}
					);
				}

				# the private e-mail address
				if($egw_address_data->{$key}->{'contact_email_home'}) {
					my $full_name = $contact_name;
					# if suffix exists
					if($cfg->{RCUBE_PRIVATE_SUFFIX_STRING}) { $full_name .= " " . $cfg->{RCUBE_PRIVATE_SUFFIX_STRING}; }
					rcube_insert_mail_address(
						$sth4insert,
						$egw_address_data->{$key}->{'contact_email_home'},
						$full_name,
						$first_name,
						$egw_address_data->{$key}->{'n_family'},
						$userId,
						$egw_address_data->{$key}->{'contact_modified'}
					);
				}
			} #END: foreach my $userId ( split(',',) $cfg->{RCUBE_ADDRBOOK_OWNERS} )

		} # END: foreach my $key ( keys(%{$egw_address_data}) )

		# SQL close statement handle after use
		$sth4insert->finish;

		# SQL COMMIT
		#2 test transactions only: $dbh->rollback;
		$dbh->commit; # commit the changes if we get this far
		
	};

	# SQL ROLLBACK if there was any error
	if ($@) {
		warn "Transaction aborted because $@";
		# now rollback to undo the incomplete changes
		# but do it in an eval{} as it may also fail
		eval { $dbh->rollback };
		# add other application on-error-clean-up code here
	}

	# SQL Disconnect from DB
	$dbh->disconnect or warn "error diconnecting from Round Cube database: " . $dbh->errstr;
}


##### START: function documentation ##### 
=pod

=head2 Function rcube_insert_mail_address (HANDLE sql_statement_handle, STRING email, STRING name, STRING first_name, STRING family_name, NUMBER timestamp)

Helper function called by function rcube_update_address_book.

Executes an INSERT statement per each e-mail address.

IN:

- handle for SQL statement

- email address

- full name

- first name

- family name

- changed time stamp from EGW database

OUT: Nothing

=cut
##### END: function documentation #####
sub rcube_insert_mail_address() {
		my $sth       = shift;
		my $email     = shift;
		my $name      = shift;
		my $firstName = shift;
		my $familyName= shift;
		my $userId    = shift;
		my $changed   = shift;

		$o_verbose && verbose ("rcube_insert_mail_address() RQ user id '$userId' contact '$name' mail '$email'");

		# each of those DB fields must not be null, set empty string so that SQL INSERT does not fail!
		# DB field 'email', 'name', 'firstname' will never be NULL due to the implementation. But 'surname' might.
		foreach my $mustNotbeNull ($email, $name, $firstName, $familyName) {
			if(!$mustNotbeNull) { $mustNotbeNull = ''; }
		}
		#$changed should always be taken from EGW DB but in case it is not set
		if(!$changed) { $changed = time(); }
		# this should never happen as well
		# do transaction roll back!
		if(!$userId) { print "ERROR: How can it be that no Round Cube user id was given? Doing rollback!\n"; my $pleaseRollbackSqlWork = 1/0; }
		if(!$sth) { print "ERROR: How can it be that I have no SQL statement handle for the Round Cube DB? Doing rollback!\n"; my $pleaseRollbackSqlWork = 1/0; }
		
		# TODO - check field size before inserting anything into table
		
		# insert into table; use the already prepared statement $sth and insert the values via bind variables
		# See DBI - http://search.cpan.org/~timb/DBI-1.616/DBI.pm

		# SQL INSERT statement execution
		# INSERT INTO `contacts` (`email`, `name`, `firstname`, `surname`, `user_id`, `changed`)
		# VALUES ($email, $name, $firstName, $familyName, $userId, $changed)
		$o_verbose && verbose "rcube_insert_mail_address() SQL INSERT INTO `contacts` (`email`, `name`, `firstname`, `surname`, `user_id`, `changed`) VALUES ('$email', '$name', '$firstName', '$familyName', '$userId', '$changed')";
		verbose "rcube_insert_mail_address() Returning: " . $sth->execute($email, $name, $firstName, $familyName, $userId, $changed);
		
}


##### START: function documentation ##### 
=pod

=head2 Function mutt_update_address_book (HASH REF egw_address_data)

This function creates a TXT file to be used as MUTT address book.

IN: HASH REF the address list

OUT: Nothing

=cut
##### END: function documentation #####
sub mutt_update_address_book {
	verbose ("mutt_update_address_book() updating mutt address book");
	
	## eGroupware
	my $egw_address_data = shift;
	
	## start writing address file
	my $index = 0;
	open (my $MUTT, ">", $cfg->{MUTT_EXPORT_FILE}) or die "could not open file! $!";

	foreach my $key ( keys(%{$egw_address_data}) ) {
		
		# contact name is full contact name - prefix
		my $contact_name = $egw_address_data->{$key}->{'n_fn'};
		if ($egw_address_data->{$key}->{'n_prefix'}) {
			$contact_name =~ s/^$egw_address_data->{$key}->{'n_prefix'}\s*//;
		}

		# Alias | Name | eMailAdresse |
		#
		#alias Maxi Max Mustermann <MaxMustermann@mail.de>
		#alias SuSE Susi Mustermann <SusiMustermann@mail.de>
		
		# this is the business e-mail address
		if($egw_address_data->{$key}->{'contact_email'}) {
			$index++;
			printf $MUTT "alias %03d %s %s <%s>\n", $index, $contact_name, $cfg->{MUTT_BUSINESS_SUFFIX_STRING},$egw_address_data->{$key}->{'contact_email'};
		}
		
		# this is the private e-mail address
		if($egw_address_data->{$key}->{'contact_email_home'}) {
			$index++;
			printf $MUTT "alias %03d %s %s <%s>\n", $index, $contact_name, $cfg->{MUTT_PRIVATE_SUFFIX_STRING},$egw_address_data->{$key}->{'contact_email_home'};
		}

	}
	#end: foreach my $key ( keys(%{$egw_address_data}) )
	
	close $MUTT;
}



##### START: function documentation ##### 
=pod

=head2 MAIN

Function check_args () and parse_config () are called to load the configuration before reading 
the EGW database and creating address books for FritzBox, Round Cube and MUTT function creates 
a TXT file to be used as MUTT address book.

=cut
##### END: function documentation #####
#### MAIN
check_args;
parse_config;

#### LAZY UPDATE - loading previous time stamps from EGW_LAZY_UPDATE_TIME_STAMP_FILE
if($cfg->{EGW_LAZY_UPDATE_TIME_STAMP_FILE} &&
    ( $cfg->{FBOX_LAZY_UPDATE} || $cfg->{RCUBE_LAZY_UPDATE} || $cfg->{MUTT_LAZY_UPDATE} )   ) {
	$lazyUpdateConfigured = 1;
	verbose("main() Lazy Update is configured; loading time stamps!");
	
	if( -r $cfg->{EGW_LAZY_UPDATE_TIME_STAMP_FILE} ) {
		$oldEgwTimeStamps = retrieve($cfg->{EGW_LAZY_UPDATE_TIME_STAMP_FILE});
	}
	
	if($o_verbose) {
		foreach my $key ( keys(%{$oldEgwTimeStamps}) ) {
			verbose("main() Lazy Update - Found user_id(" . $key . ") modify_time(" . $oldEgwTimeStamps->{$key} . ")");
		}
	}
}

### update FritzBox address book
if($cfg->{FBOX_EXPORT_ENABLED}) {
	verbose("main() FBOX -  START");
	if($cfg->{EGW_ADDRBOOK_OWNERS} || $cfg->{FBOX_EGW_ADDRBOOK_OWNERS}) {
		
		### lookup EGW users
		my $egwUserForThisClient = find_EGW_user('FBOX_EGW_ADDRBOOK_OWNERS');
		
		### read database for this user combination, if not already done
		if(! exists $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) {
			verbose("main() FBOX - Seems we did not already read the EGW DB for this user combination!");
			( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient }, 
			  $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) = egw_read_db($egwUserForThisClient);
		}
		
		### if lazy update is active: only generate output if old time stamp and new time stamp are different
		# also check if MUTT_EXPORT_FILE exists and try to create it if not!
		if(-e $cfg->{FBOX_OUTPUT_XML_FILE} && $cfg->{FBOX_LAZY_UPDATE}  && $oldEgwTimeStamps->{$egwUserForThisClient} && ($cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ==  $oldEgwTimeStamps->{$egwUserForThisClient} ) ) {
			verbose("main() FBOX - lazy update configured and time stamp '$oldEgwTimeStamps->{$egwUserForThisClient}' didn't change since last script run!");
			verbose("main() FBOX - doing nothing");
		} else {
			if($cfg->{FBOX_LAZY_UPDATE}) { verbose("main() FBOX - lazy update configured but time stamp changed to '$cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient }'!"); }
			else { verbose("main() FBOX - NO lazy update configured!"); }
			verbose("main() FBOX - update needed");
			fbox_gen_fritz_xml( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient } );
		}
	} 
	else { print "WARN: Did not find any EGW user for Fritz Box export!\nINFO: Please set EGW_ADDRBOOK_OWNERS or FBOX_EGW_ADDRBOOK_OWNERS!\n"; }
}

### update RoundCube address book
if($cfg->{RCUBE_EXPORT_ENABLED}) {
	verbose("main() RCUBE -  START");
	if($cfg->{EGW_ADDRBOOK_OWNERS} || $cfg->{RCUBE_EGW_ADDRBOOK_OWNERS}) {
		
		### lookup EGW users
		my $egwUserForThisClient = find_EGW_user('RCUBE_EGW_ADDRBOOK_OWNERS');
		
		### read database for this user combination, if not already done
		if(! exists $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) {
			verbose("main() RCUBE - Seems we did not already read the EGW DB for this user combination!");
			( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient }, 
			  $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) = egw_read_db($egwUserForThisClient);
		}
		
		### if lazy update is active: only generate output if old time stamp and new time stamp are different
		if($cfg->{RCUBE_LAZY_UPDATE}  && $oldEgwTimeStamps->{$egwUserForThisClient} && ($cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ==  $oldEgwTimeStamps->{$egwUserForThisClient} ) ) {
			verbose("main() RCUBE - lazy update configured and time stamp '$oldEgwTimeStamps->{$egwUserForThisClient}' didn't change since last script run!");
			verbose("main() RCUBE - doing nothing");
		} else {
			if($cfg->{RCUBE_LAZY_UPDATE}) { verbose("main() RCUBE - lazy update configured but time stamp changed to '$cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient }'!\n"); }
			else { verbose("main() RCUBE - NO lazy update configured!"); }
			verbose("main() RCUBE - update needed");
			rcube_update_address_book( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient } );
		}
	} 
	else { print "WARN: Did not find any EGW user for Round Cube export!\nINFO: Please set EGW_ADDRBOOK_OWNERS or RCUBE_EGW_ADDRBOOK_OWNERS!\n"; }
}


### update MUTT address book
if($cfg->{MUTT_EXPORT_ENABLED}) {
	verbose("main() MUTT -  START");
	if($cfg->{EGW_ADDRBOOK_OWNERS} || $cfg->{MUTT_EGW_ADDRBOOK_OWNERS}) {
		
		### lookup EGW users
		my $egwUserForThisClient = find_EGW_user('MUTT_EGW_ADDRBOOK_OWNERS');
		
		### read database for this user combination, if not already done
		if(! exists $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) {
			verbose("main() MUTT - Seems we did not already read the EGW DB for this user combination!");
			( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient }, 
			  $cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ) = egw_read_db($egwUserForThisClient);
		}
		
		### if lazy update is active: only generate output if old time stamp and new time stamp are different
		# also check if MUTT_EXPORT_FILE exists and try to create it if not!
		if(-e $cfg->{MUTT_EXPORT_FILE} && $cfg->{MUTT_LAZY_UPDATE}  && $oldEgwTimeStamps->{$egwUserForThisClient} && ($cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient } ==  $oldEgwTimeStamps->{$egwUserForThisClient} ) ) {
			verbose("main() MUTT - lazy update configured and time stamp '$oldEgwTimeStamps->{$egwUserForThisClient}' didn't change since last script run!");
			verbose("main() MUTT - doing nothing");
		} else {
			if($cfg->{MUTT_LAZY_UPDATE}) { verbose("main() MUTT - lazy update configured but time stamp changed to '$cachedEgwAddressBookData->{'TIME'}->{ $egwUserForThisClient }'!"); }
			else { verbose("main() MUTT - NO lazy update configured!"); }
			verbose("main() MUTT - update needed");
			mutt_update_address_book( $cachedEgwAddressBookData->{'DATA'}->{ $egwUserForThisClient } );
		}
	} 
	else { print "WARN: Did not find any EGW user for MUTT export!\nINFO: Please set EGW_ADDRBOOK_OWNERS or MUTT_EGW_ADDRBOOK_OWNERS!\n"; }
}

### LAZY UPDATE - saving current time stamps to EGW_LAZY_UPDATE_TIME_STAMP_FILE
if($lazyUpdateConfigured && $cachedEgwAddressBookData && $cachedEgwAddressBookData->{'TIME'}) {
	verbose("main() Lazy Update is configured; persisting time stamps!");
	store $cachedEgwAddressBookData->{'TIME'}, $cfg->{EGW_LAZY_UPDATE_TIME_STAMP_FILE};
}

__END__
##### START: Documentation TAIL in POD format #####
=pod

=head1 TUTORIALS

This is a set of small tutorials for synchronizing the supported clients with eGroupware.



=head2 Connecting to the database.

TBD

=head2 Setting up the FritzBox address book

TBD

=head2 Setting up the Round Cube address book

TBD

=head2 Setting up the MUTT address book

TBD

=head1 AUTHORS

Christian Anton <mail@christiananton.de>

Kai Ellinger <coding@blicke.de>

=head1 SEE ALSO

- Fritz Box router product family from AVM L<http://www.avm.de/en/Produkte/FRITZBox/index.html>

- FritzUploader to upload XML address books to a Fritz Box from Jan-Piet Mens L<https://github.com/jpmens/fritzuploader> 

- Round Cube Web based mail client L<http://roundcube.net>

- MUTT command line mail client L<http://www.mutt.org>

=cut
##### END: Documentation TAIL in POD format #####

