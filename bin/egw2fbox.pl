#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use DBI;
use Data::Dumper;
use List::Util qw [min max];

### CHANGELOG
# 0.3.0 2011-02-26 Kai Ellinger <coding@blicke.de>
#                  - Verbose function:
#                    * only prints if data was provided 
#                    * avoiding unneccesary verbose function calls
#                    * avoiding runtime errors due to uninitialized data in verbode mode
#                  - Respect that Fritzbox address book names can only have 25 characters
#                  - EGW address boock to Fritz Box phone book mapping:
#                    The Fritz Box Phone book knows 3 different telephone number types:
#                      'work', 'home' and 'mobile'
#                    Each Fritz Box phone book entry can have up to 3 phone numbers. 
#                    All 1-3 phone numbers can be of same type or differnt types.
#                    * Compact mode (if one EGW address has 1-3 phone numbers): 
#						EGW field tel_work          -> FritzBox field type 'work'
#						EGW field tel_cell          -> FritzBox field type 'mobile'
#						EGW field tel_assistent     -> FritzBox field type 'work'
#						EGW field tel_home          -> FritzBox field type 'home'
#						EGW field tel_cell_private  -> FritzBox field type 'mobile'
#						EGW field tel_other         -> FritzBox field type 'home'
#                      NOTE: Because we only have 3 phone numbers, we stick on the right number types. 
#                    * Business Fritz Box phone book entry (>3 phone numbers): 
#						EGW field tel_work          -> FritzBox field type 'work'
#						EGW field tel_cell          -> FritzBox field type 'mobile'
#						EGW field tel_assistent     -> FritzBox field type 'home'
#                      NOTE: On hand sets, the list order is work, mobile, home. That's why the 
#                            most important number is 'work' and the less important is 'home' here.
#                    * Private Fritz Box phone book entry (>3 phone numbers):
#						EGW field tel_home          -> FritzBox field type 'work'
#						EGW field tel_cell_private  -> FritzBox field type 'mobile'
#						EGW field tel_other         -> FritzBox field type 'home'
#                      NOTE: On hand sets, the list order is work, mobile, home. That's why the 
#                            most important number is 'work' and the less important is 'home' here.
#                   - Added EGW DB connect string check
#
# 0.2.0 2011-02-25 Christian Anton <mail@christiananton.de>
#                  implementing XML-write as an extra function and implementing COMPACT_MODE which
#                  omits creating two contact entries for contacts which have only up to three numbers
#
# 0.1.0 2011-02-24 Kai Ellinger <coding@blicke.de>, Christian Anton <mail@christiananton.de>
#                  Initial version of this script, ready for world domination ;-)

my $egw_address_data;
my $cfg;

# the maximum number of characters that a Fritz box phone book name can have
my $FboxMaxLenghtForName = 32;
# Maybe the code page setting changes based on Fritz Box language settings 
# and must varry for characters other than germany special characters.
# This variable can be used to specifx the code page used at the exported XML.
my $FboxAsciiCodeTable = "iso-8859-1"; # 

my $o_verbose;
my $o_configfile = "egw2fbox.conf";

sub check_args {
        Getopt::Long::Configure ("bundling");
        GetOptions(
    	'v'   => \$o_verbose,		'verbose'	=> \$o_verbose,
		'c:s' => \$o_configfile,	'config:s'	=> \$o_configfile
		);
}

sub parse_config {
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

sub read_db {
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

	$sql = "
	  SELECT 
	    `contact_id`,
	    `n_prefix`,
	    `n_fn` ,
	    `tel_work` ,
	    `tel_cell` ,
	    `tel_assistent` ,
	    `tel_home` ,
	    `tel_cell_private`,
	    `tel_other`,
	    `contact_email`,
	    `contact_email_home`
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

sub reformatTelNr {
	my $Nr = shift;

	$Nr =~ s/^\+/00/;
	$Nr =~ s/[^\d]+//g;

	return $Nr;
}

sub write_xml_contact {
	my $contact_name = shift;
	my $contact_name_suffix = shift;
	my $numbers_array_ref = shift;

	my $now_timestamp = time();
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
				       reformatTelNr($$numbers_entry_ref{'nr'}) . 
				       "</number>\n";
		}
	}

	# print the bottom XML wrap for the contact's entry
	print FRITZXML "</telephony>\n";
	print FRITZXML "<services /><setup /><mod_time>$now_timestamp</mod_time></contact>";
}

sub count_contacts_numbers {
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

sub gen_fritz_xml {
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
		if($cfg->{COMPACT_MODE}) { 
			$number_of_numbers = count_contacts_numbers($key);
			verbose ("contact has $number_of_numbers phone numbers defined"); 
			}

		if ( ($cfg->{COMPACT_MODE}) && ($number_of_numbers <= 3) ){

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

			write_xml_contact($contact_name, '', \@numbers_array);

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

				write_xml_contact($contact_name, $cfg->{FBOX_BUSINESS_SUFFIX_STRING}, \@numbers_array);
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

				write_xml_contact($contact_name, $cfg->{FBOX_PRIVATE_SUFFIX_STRING}, \@numbers_array);
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


#### MAIN

check_args;
parse_config;
read_db;
gen_fritz_xml;
