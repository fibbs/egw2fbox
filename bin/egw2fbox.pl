#!/usr/bin/perl
### FILE
#       egw2fbox.pl - reads addresses from eGroupware database
#                   - exports them to a XML file that can be imported to
#                     the Fritz Box phone book via Fritz Box web interface
#                   - exports them to the Round Cube web mailer address
#                     inside the Round Cube database
#
### COPYRIGHT
#       Copyright 2011  Christian Anton <mail@christiananton.de>
#                       Kai Ellinger <coding@blicke.de>
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#
### CHANGELOG
# 0.4.0 2011-03-02 Kai Ellinger <coding@blicke.de>
#                  - added support for mutt address book including an example file showing 
#                    how to configure ~/.muttrc to support a local address book and a global
#                    EGW address book
#..................- replaced time stamp in fritz box xml with real time stamp from database
#                    this feature is more interesting for round cube integration where we have
#                    a time stamp field in the round cube database
#                  - added some comments
#
# 0.3.0 2011-02-26 Kai Ellinger <coding@blicke.de>
#                  - Verbose function:
#                    * only prints if data was provided
#                    * avoiding unnecessary verbose function calls
#                    * avoiding runtime errors due to uninitialized data in verbose mode
#                  - Respect that Fritzbox address book names can only have 25 characters
#                  - EGW address book to Fritz Box phone book mapping:
#                    The Fritz Box Phone book knows 3 different telephone number types:
#                      'work', 'home' and 'mobile'
#                    Each Fritz Box phone book entry can have up to 3 phone numbers.
#                    All 1-3 phone numbers can be of same type or different types.
#                    * Compact mode (if one EGW address has 1-3 phone numbers):
#                       EGW field tel_work          -> FritzBox field type 'work'
#                       EGW field tel_cell          -> FritzBox field type 'mobile'
#                       EGW field tel_assistent     -> FritzBox field type 'work'
#                       EGW field tel_home          -> FritzBox field type 'home'
#                       EGW field tel_cell_private  -> FritzBox field type 'mobile'
#                       EGW field tel_other         -> FritzBox field type 'home'
#                      NOTE: Because we only have 3 phone numbers, we stick on the right number types.
#                    * Business Fritz Box phone book entry (>3 phone numbers):
#                       EGW field tel_work          -> FritzBox field type 'work'
#                       EGW field tel_cell          -> FritzBox field type 'mobile'
#                       EGW field tel_assistent     -> FritzBox field type 'home'
#                      NOTE: On hand sets, the list order is work, mobile, home. That's why the
#                            most important number is 'work' and the less important is 'home' here.
#                    * Private Fritz Box phone book entry (>3 phone numbers):
#                       EGW field tel_home          -> FritzBox field type 'work'
#                       EGW field tel_cell_private  -> FritzBox field type 'mobile'
#                       EGW field tel_other         -> FritzBox field type 'home'
#                      NOTE: On hand sets, the list order is work, mobile, home. That's why the
#                            most important number is 'work' and the less important is 'home' here.
#                   - Added EGW DB connect string check
#                   - All EGW functions have now prefix 'egw_', all Fritz Box functions prefix
#                     'fbox_' and all Round Cube functions 'rcube_' to prepare the source for
#                     adding the round cube sync.
#
# 0.2.0 2011-02-25 Christian Anton <mail@christiananton.de>
#                  implementing XML-write as an extra function and implementing COMPACT_MODE which
#                  omits creating two contact entries for contacts which have only up to three numbers
#
# 0.1.0 2011-02-24 Kai Ellinger <coding@blicke.de>, Christian Anton <mail@christiananton.de>
#                  Initial version of this script, ready for world domination ;-)

#### modules
use warnings;     # installed by default via permodlib
use strict;       # installed by default via permodlib
use Getopt::Long; # installed by default via permodlib
use DBI;          # not included in permodlib: DBI and DBI::Mysql needs to be installed if not already done
use Data::Dumper;            # installed by default via permodlib
use List::Util qw [min max]; # installed by default via permodlib

#### global variables
## config
my $o_verbose;
my $o_configfile = "egw2fbox.conf";
my $cfg;

## eGroupware
my $egw_address_data;

## fritz box
# the maximum number of characters that a Fritz box phone book name can have
my $FboxMaxLenghtForName = 32;
# Maybe the code page setting changes based on Fritz Box language settings
# and must vary for characters other than germany special characters.
# This variable can be used to specify the code page used at the exported XML.
my $FboxAsciiCodeTable = "iso-8859-1"; #


#### functions
sub check_args {
				Getopt::Long::Configure ("bundling");
				GetOptions(
					'v'   => \$o_verbose,     'verbose'   => \$o_verbose,
					'c:s' => \$o_configfile,  'config:s'  => \$o_configfile
		);
}

sub parse_config {
	# - we are not using perl module Config::Simple here because it was not installed
	# on our server by default and we saw compile errors when trying to install it via CPAN
	# - we decided to implement our own config file parser to keep the installation simple 
	#   and let the script run with as less dependencies as possible
	open (CONFIG, "$o_configfile") or die "could not open config file: $!";

	while(defined(my $line = <CONFIG>) )
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
	close CONFIG;

}

sub verbose{
	my $msg = shift;
	if ($o_verbose && $msg) {
		print "$msg\n";
	}
}

sub egw_read_db {
	my $dbh;
	my $sth;
	my $sql;

	my @res;

	# default values for DB connect
	if (!$cfg->{EGW_DBHOST}) { $cfg->{EGW_DBHOST} = 'localhost'; }
	if (!$cfg->{EGW_DBPORT}) { $cfg->{EGW_DBPORT} = 3306; }
	if (!$cfg->{EGW_DBNAME}) { $cfg->{EGW_DBNAME} = 'egroupware'; }
	# don't set default values for DB user and password
	die "ERROR: EGW database can't be accessed without DB user name or password set!"
		if( !($cfg->{EGW_DBUSER}) || !($cfg->{EGW_DBPASS}) );

	my $dsn = "dbi:mysql:$cfg->{EGW_DBNAME}:$cfg->{EGW_DBHOST}:$cfg->{EGW_DBPORT}";
	$dbh = DBI->connect($dsn, $cfg->{EGW_DBUSER}, $cfg->{EGW_DBPASS}) or die "could not connect db: $!";
	#$dbh->do("SET NAMES utf8");
	# convert UTF8 values inside EGW DB to latin1 because Fritz Box expects German characters in iso-8859-1
	$dbh->do("SET NAMES latin1");  # latin1 is good at least for XML files created with iso-8859-1

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

	$sql = "
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
			`contact_owner` IN ( $cfg->{EGW_ADDRBOOK_OWNERS} )
	";

	$sth = $dbh->prepare($sql);
	$sth->execute;

	$egw_address_data = $sth->fetchall_hashref('contact_id');

	#print "Name for id 57 is $egw_address_data->{57}->{n_fn}\n";
	my $amountData = keys(%{$egw_address_data});
	verbose("found $amountData data rows in egw addr book");

	die "no data for owner(s) $cfg->{ADDRBOOK_OWNERS} found" if ( 0 == $amountData );
}

sub fbox_reformatTelNr {
	my $Nr = shift;

	$Nr =~ s/^\+/00/;
	$Nr =~ s/[^\d]+//g;

	return $Nr;
}

sub fbox_write_xml_contact {
	my $contact_name = shift;
	my $contact_name_suffix = shift;
	my $numbers_array_ref = shift;
  my $now_timestamp = shift;
	#my $now_timestamp = time();
	my $name_length;
	my $output_name;

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
	print FRITZXML "<contact>\n<category>0</category>\n<person><realName>$output_name</realName></person>\n";
	print FRITZXML "<telephony>\n";

	foreach my $numbers_entry_ref (@$numbers_array_ref) {
		# not defined values causing runtime errors
		$o_verbose && verbose ("   type: ". ($numbers_entry_ref->{'type'} || "<undefined>") . " , number: ". ($numbers_entry_ref->{'nr'}|| "<undefined>")  );
		if ($$numbers_entry_ref{'nr'}) {
			print FRITZXML "<number type=\"$$numbers_entry_ref{'type'}\" vanity=\"\" prio=\"0\">" .
							 fbox_reformatTelNr($$numbers_entry_ref{'nr'}) .
							 "</number>\n";
		}
	}

	# print the bottom XML wrap for the contact's entry
	print FRITZXML "</telephony>\n";
	print FRITZXML "<services /><setup /><mod_time>$now_timestamp</mod_time></contact>";
}

sub fbox_count_contacts_numbers {
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

sub fbox_gen_fritz_xml {
	my $now_timestamp = time();

	open (FRITZXML, ">", $cfg->{FBOX_OUTPUT_XML_FILE}) or die "could not open file! $!";
	print FRITZXML <<EOF;
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
		verbose ("generating XML snippet for contact $contact_name");
		if ($egw_address_data->{$key}->{'n_prefix'}) {
			$contact_name =~ s/^$egw_address_data->{$key}->{'n_prefix'}\s*//;
		}

		my $number_of_numbers = 0;
		# counting phone numbers is only in compact mode needed
		if($cfg->{FBOX_COMPACT_MODE}) {
			$number_of_numbers = fbox_count_contacts_numbers($key);
			verbose ("contact has $number_of_numbers phone numbers defined");
			}

		if ( ($cfg->{FBOX_COMPACT_MODE}) && ($number_of_numbers <= 3) ){

			verbose ("entering compact mode for this contact entry");
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

			fbox_write_xml_contact($contact_name, '', \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});

		} else {

			verbose ("entering non-compact mode for this contact entry");

			# start print the business contact entry
			if (
				($egw_address_data->{$key}->{'tel_work'}) ||
				($egw_address_data->{$key}->{'tel_cell'}) ||
				($egw_address_data->{$key}->{'tel_assistent'})
			 ) {

				verbose ("  start writing the business contact entry");
				my @numbers_array;

				push @numbers_array, { type=>'home',   nr=>$egw_address_data->{$key}->{'tel_work'} };
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell'} };
				push @numbers_array, { type=>'work',   nr=>$egw_address_data->{$key}->{'tel_assistent'} };

				fbox_write_xml_contact($contact_name, $cfg->{FBOX_BUSINESS_SUFFIX_STRING}, \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});
			}
			# end print the business contact entry

			# start print the private contact entry
			if (
				($egw_address_data->{$key}->{'tel_home'}) ||
				($egw_address_data->{$key}->{'tel_cell_private'}) ||
				($egw_address_data->{$key}->{'tel_other'})
			 ) {

				verbose ("  start writing the private contact entry");
				my @numbers_array;

				push @numbers_array, { type=>'home',   nr=>$egw_address_data->{$key}->{'tel_work'} };
				push @numbers_array, { type=>'mobile', nr=>$egw_address_data->{$key}->{'tel_cell_private'} };
				push @numbers_array, { type=>'work',   nr=>$egw_address_data->{$key}->{'tel_other'} };

				fbox_write_xml_contact($contact_name, $cfg->{FBOX_PRIVATE_SUFFIX_STRING}, \@numbers_array, $egw_address_data->{$key}->{'contact_modified'});
			}
			# end print the business contact entry
		}
		# end non-compact mode
	}
	## end iterate


	print FRITZXML <<EOF;
</phonebook>
</phonebooks>
EOF
	close FRITZXML;
}

sub rcube_update_address_book {
	verbose ("updating round cube address book");
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

}


sub mutt_update_address_book {
	verbose ("updating mutt address book");
	my $index = 0;

	open (MUTT, ">", $cfg->{MUTT_EXPORT_FILE}) or die "could not open file! $!";

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
			#print MUTT "alias $index $contact_name $cfg->{MUTT_BUSINESS_SUFFIX_STRING} <$egw_address_data->{$key}->{'contact_email'}>\n";
			printf MUTT "alias %03d %s %s <%s>\n", $index, $contact_name, $cfg->{MUTT_BUSINESS_SUFFIX_STRING},$egw_address_data->{$key}->{'contact_email'};
		}
		
		# this is the private e-mail address
		if($egw_address_data->{$key}->{'contact_email_home'}) {
			$index++;
			printf MUTT "alias %03d %s %s <%s>\n", $index, $contact_name, $cfg->{MUTT_PRIVATE_SUFFIX_STRING},$egw_address_data->{$key}->{'contact_email_home'};
		}

	}
	#end: foreach my $key ( keys(%{$egw_address_data}) )
	
	close MUTT;
}


#### MAIN

check_args;
parse_config;
egw_read_db;
if($cfg->{FBOX_EXPORT_ENABLED}) { fbox_gen_fritz_xml; }
if($cfg->{RCUBE_EXPORT_ENABLED}) { rcube_update_address_book; }
if($cfg->{MUTT_EXPORT_ENABLED}) { mutt_update_address_book; }
