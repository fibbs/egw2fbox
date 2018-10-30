# NAME

egw2fbox.pl

# DESCRIPTION

The purpose of this script is to run on a server and provide an automated way of sharing eGroupware 
hosted phone numbers and e-mail addresses with clients not supporting any other server based 
synchronization.

The phone numbers and e-mail addresses are read from the eGroupware database table _contacts_ and 
exports in the native format of each clients.

Because the supported clients have very limited address book capabilities, this is a one-way communication 
only. Hence, client side changes are not reported back to eGroupware and the client address books 
should be configured to be readonly as much as possible.

`egw2fbox.pl` has functionality called _lazy update_ that can be configured per each client RoundCube,
MUTT and FritzBox that only writes to the clients if data inside the eGroupware database was changed. 
This reduces CPU time but - more important - also reduces the need for uploading data
to clients where continuous writing would have disadvantages. 
For example the FritzBox address book that stores the addresses in flash memory. Because flash memory has a 
limited write cycles, it is better to update the address book only if there had been changes. `egw2fbox.pl` 
can be safely used together with `cronjob.sh` because it avoids unnecessary write cycles as much as possible.

Currently supported clients are:

- phone numbers:

    \- Fritz Box router address book

- e-mail addresses:

    \- Round Cube web mailer including personal and global address book

    \- MUTT command line mail client

For uploading the created XML address book to a Fritz Box a small perl script called FritzUploader from Jan-Piet Mens is used.

# SYNOPSIS

`egw2fbox.pl [--verbose] [-v] [--config filename.ini] [-c filename.ini] [--version] [--help] [-h] [-?] [--man] [--changelog]`

# OPTIONS

Runtime:

- --verbose -v

    Logs to STDOUT while executing the script.

- --config filename.ini   -c filename.ini

    File name containing all configuration.

    See sections CONFIG FILE and TUTORIALS for further information.

Documentation:

- --version

    Prints the version numbers.

- --help -h -?

    Print a brief help message.

- --man

    Prints the complete manual page.

- --changelog

    Prints the change log.

# COPYRIGHT AND LICENSE

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

# HISTORY

    0.08.05 2018-10-31 Kai Ellinger <coding@blicke.de>
         Fixed file format issues in FritzBox phone book XML file
           
    0.08.04 2017-08-06 Kai Ellinger <coding@blicke.de>
         Added user name support to bin/fritzuploader.pl

    0.08.03 2014-02-28 Christian Anton <mail@christiananton.de>, Kai Ellinger <coding@blicke.de>
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

# INSTALLATION

\- A current version of **PERL** is needed. `egw2fbox.pl` requires module DBI and DBD::Mysql. 
`fritzuploader.pl` requires module XML::Simple and URI::Encode. All other modules needed to run the script 
are part of the standard perl library and don't need to be installed.

\- Clone the head revision from [https://github.com/fibbs/egw2fbox](https://github.com/fibbs/egw2fbox)

\- Copy file `etc/egw2fbox.conf.default` to `etc/egw2fbox.conf` and update values according to your needs

\- Test in verbose mode: `/path/to/egw2fbox/bin/cronjob.sh -v -c /path/to/egw2fbox/etc/egw2fbox.conf`

\- Add to your crontab:

`*/20 * * * * /path/to/egw2fbox/bin/cronjob.sh -c /path/to/egw2fbox/etc/egw2fbox.conf`

# CONFIG FILE

This section may later describes the structure of the INI file used by this script. 
Until now, see the comments in `egw2fbox.conf.default`.

\* File `egw2fbox.pl` uses command line option `-config /path/to/fileName.ini`, default is `egw2fbox.conf`.

\* File `cronjob.sh` uses command line option `-c /path/to/fileName.ini`, no default value.

\* File `fritzuploader.pl` searches for the value of environment variable FRITZUPLOADERCFG, default is `fritzuploader.conf`.

## eGoupware section

Configuration settings related to the eGroupware database

## FritzBox section

Configuration settings related to the Fritz Box

## Round Cube section

Configuration settings related to the Round Cube database

## MUTT section

Configuration settings related to MUTT

# API

## Required Perl modules

Most Perl modules used by this program are part of the standard perl library perlmodlib [http://perldoc.perl.org/perlmodlib.html](http://perldoc.perl.org/perlmodlib.html) and are installed by default.

The only modules that might not be available by default are to access the MySQL database and are named DBI and DBD::Mysql.

## Function check\_args ()

This function is checking command line options and printing help messages if requested.

IN: No parameter

OUT: Returns nothing

## Function parse\_config ()

This function is parsing the config file given by command line option '-c filename.ini'.

IN: No parameter

OUT: Returns nothing

## Function verbose (STRING message)

Printing out verbose messages if verbose mode is enabled.

IN: Takes the message to print out

OUT: Returns nothing

## Function sort\_user\_id\_list (STRING user\_id\_list)

This function is called by function find\_EGW\_user (STRING user\_id\_list) to sort 
the user list it looked up before.

This is needed to avoid unnecessary database accesses even the config parameters EGW\_ADDRBOOK\_OWNERS, 
FBOX\_EGW\_ADDRBOOK\_OWNERS, RCUBE\_EGW\_ADDRBOOK\_OWNERS and MUTT\_EGW\_ADDRBOOK\_OWNERS list 
the user ids in different order and with different wide spaces.

The default Perl sort algorithm is used even if it is not a numeric algorithm. But this is not needed anyway.

IN: Takes an unsorted user id list string

OUT: Returns a sorted user id list string

## Function find\_EGW\_user (STRING config\_parameter)

This function returns a sorted user id list string that is either defined by the global 
configuration parameter EGW\_ADDRBOOK\_OWNERS or one of the parameters
FBOX\_EGW\_ADDRBOOK\_OWNERS, RCUBE\_EGW\_ADDRBOOK\_OWNERS and MUTT\_EGW\_ADDRBOOK\_OWNERS
to overwrite the global parameter.

IN: Config parameter name FBOX\_EGW\_ADDRBOOK\_OWNERS, RCUBE\_EGW\_ADDRBOOK\_OWNERS or MUTT\_EGW\_ADDRBOOK\_OWNERS

OUT: Returns a sorted user id list string

## Function egw\_read\_db (STRING user\_id\_list)

Connects to eGroupware database and looks up address book values for the given user id list including time stamp of last change.

IN: User id list to lookup

OUT: Returns two parameters:

\- all address data belonging to the user list

\- the time stamp when this list was modified the last time

## Function fbox\_reformatTelNr (STRING phone\_number)

This is a helper function called by function fbox\_write\_xml\_contact format the phone number in a way that the Fritz Box can resolve it.
How the phone number is formatted exactly is defined in the fritz box configuration section of the config file. 

First, each phone number is re-formatted like 00498912345678. Later the phone numbers with the same country code or with the same area code 
get the leading numbers removed if configured. 

This is needed because the Fritz Box can not recognize that phone number 00498912345678 is the same as 08912345678 calling from the 
same country is the same as 12345678 calling from the same city. But the right phone number syntax is very important to get the names 
resolved for incoming calls as well as to replace the phone numbers with the names in the phone call protocols maintain
that can either be viewed via web console or mail. Same is true for the incoming mail box calls that can be forwarded via e-mail as well.

IN: Phone number in any format it can exist in eGrouware

OUT: Phone number formatted in a way that the Fritz Box can resolve incoming calls correctly

## Function fbox\_write\_xml\_contact (HANDLE xml\_file, STRING contact\_name, STRING contact\_name\_suffix, ARRAY REF phone\_numbers, NUMBER timestamp)

This is a function called by function fbox\_gen\_fritz\_xml for each single contact that needs to be written to the 
XML file. The contact name is formatted to fit into the restrictions of  the Fritz Box and the phones connected to it.

IN: 

\- handle for XML file

\- contact\_name

\- contact\_name\_suffix = shift;

\- array ref with all phone numbers

\- timestamp of last update in eGroupware DB

OUT: Nothing

## Function fbox\_count\_contacts\_numbers (HASH REF egw\_address\_data, STRING key\_to\_search)

This is a function called by function fbox\_gen\_fritz\_xml for each single contact found in the eGroupware address book to 
know how many phone numbers this contact has. If there are no phone numbers, this contact must not imported to the Fritz Box.
If there are more than 3 phone numbers, the contact must be split into a business contact and a private contact because
the Fritz Box can only hold 3 phone numbers per contact.

IN: 

\- HASH REF the address list to search

\- STRING key of the address that needs to be searched from the list

OUT: NUMBER count of found phone numbers

## Function fbox\_gen\_fritz\_xml (HASH REF egw\_address\_data)

This function creates the XML file to upload to the Fritz Box.

IN: HASH REF the address list

OUT: Nothing

## Function rcube\_update\_address\_book (HASH REF egw\_address\_data)

This function the Round Cube database with names and e-mail addresses of the 
EGW address book by deleting the whole contacts table for the configured user 
and inserting each contact again. If there is any error, the whole DB transaction
is rolled back.

IN: HASH REF the address list

OUT: Nothing

## Function rcube\_insert\_mail\_address (HANDLE sql\_statement\_handle, STRING email, STRING name, STRING first\_name, STRING family\_name, NUMBER timestamp)

Helper function called by function rcube\_update\_address\_book.

Executes an INSERT statement per each e-mail address.

IN:

\- handle for SQL statement

\- email address

\- full name

\- first name

\- family name

\- changed time stamp from EGW database

OUT: Nothing

## Function mutt\_update\_address\_book (HASH REF egw\_address\_data)

This function creates a TXT file to be used as MUTT address book.

IN: HASH REF the address list

OUT: Nothing

## MAIN

Function check\_args () and parse\_config () are called to load the configuration before reading 
the EGW database and creating address books for FritzBox, Round Cube and MUTT function creates 
a TXT file to be used as MUTT address book.

# TUTORIALS

This is a set of small tutorials for synchronizing the supported clients with eGroupware.

## Connecting to the database.

TBD

## Setting up the FritzBox address book

TBD

## Setting up the Round Cube address book

TBD

## Setting up the MUTT address book

TBD

# AUTHORS

Christian Anton (@fibbs)

Kai Ellinger <coding@blicke.de>

# SEE ALSO

\- Fritz Box router product family from AVM [http://www.avm.de/en/Produkte/FRITZBox/index.html](http://www.avm.de/en/Produkte/FRITZBox/index.html)

\- FritzUploader to upload XML address books to a Fritz Box from Jan-Piet Mens [https://github.com/jpmens/fritzuploader](https://github.com/jpmens/fritzuploader) 

\- Round Cube Web based mail client [http://roundcube.net](http://roundcube.net)

\- MUTT command line mail client [http://www.mutt.org](http://www.mutt.org)
