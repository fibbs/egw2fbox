# egw2fbox

## DESCRIPTION

The purpose of this script is to run on a server and provide an automated way of sharing eGroupware 
hosted phone numbers and e-mail addresses with clients not supporting any other server based 
synchronization.

The phone numbers and e-mail addresses are read from the eGroupware database table _contacts_ and 
exported into the native format of each client.

Because of the very limited address book capabilities of some of the clients, this is a one-way communication 
only. Hence, client side changes are not synchronized back into eGroupware and the client address books 
should be configured to be readonly if possible.

<<<<<<< HEAD
`egw2fbox.pl` has functionality called _lazy update_ that can be configured per each client RoundCube,
MUTT and FritzBox that only writes to the clients if data inside the eGroupware database was changed. 
This reduces CPU time but - more important - also reduces the need for uploading data
to clients where continuous writing would have disadvantages. 
For example the FritzBox address book that stores the addresses in flash memory. Because flash memory has a 
limited write cycles, it is better to update the address book only if there had been changes. `egw2fbox.pl` 
can be safely used together with `cronjob.sh` because it avoids unnecessary write cycles as much as possible.
=======
Further, eGroupware had a built-in functionality called _lazy update_ to reduce write cycles as much as 
possible. This reduces CPU time but - more important - also reduces the need for uploading data to clients
where continuous writing would have disadvantages. One good example is the Fritzbox addressbook that stores the addresses in flash memory. Flash memory has a limited amount of possible writes.
`egw2fbox.pl` can be safely used because it avoids unnecessary write cycles as much as possible.
>>>>>>> 0b39bd061060d9c96fa1452c29ddcae314811752

Currently supported clients are:

### for phone numbers
- AVM Fritzbox router addressbook

### for email addresses
- *Roundcube* web mailer including personal and global address book
- *mutt* command line mail client

For uploading the created XML address book to a Fritzbox a tiny perl script called FritzUploader from Jan-Piet Mens is used.

# SYNOPSIS

`egw2fbox.pl [--verbose] [-v] [--config filename.ini] [-c filename.ini] [--version] \`
`  [--help] [-h] [-?] [--man] [--changelog]`

# OPTIONS

### Runtime:

- `--verbose`, `-v`

    Logs to STDOUT while executing the script.

- `--config filename.ini`,   `-c filename.ini`

    File name containing all configuration.

    See sections CONFIG FILE and TUTORIALS for further information.

### Documentation:

- `--version`

    Prints the version numbers.

- `--help`, `-h`, `-?`

    Print a brief help message.

- `--man`

    Prints the complete manual page.

- `--changelog`

    Prints the changelog.

## COPYRIGHT AND LICENSE

<<<<<<< HEAD
Copyright 2011-2014 by Christian Anton <mail@christiananton.de>, Kai Ellinger <coding@blicke.de>
=======
Copyright 2011 by Christian Anton (@fibbs) and Kai Ellinger
>>>>>>> 0b39bd061060d9c96fa1452c29ddcae314811752

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

## INSTALLATION

- A current version of __PERL__ is needed. `egw2fbox.pl` requires module DBI and DBD::Mysql. 
`fritzuploader.pl` requires module XML::Simple. All other modules needed to run the script 
are part of the standard perl library and don't need to be installed.
<<<<<<< HEAD

\- Clone the head revision from [https://github.com/fibbs/egw2fbox](https://github.com/fibbs/egw2fbox)

\- Copy file `etc/egw2fbox.conf.default` to `etc/egw2fbox.conf` and update values according to your needs

\- Test in verbose mode: `/path/to/egw2fbox/bin/cronjob.sh -v -c /path/to/egw2fbox/etc/egw2fbox.conf`

\- Add to your crontab:

=======
- Download the head revision via [http://git.fibbs.org/?p=egw2fbox.git;a=snapshot;h=HEAD;sf=tgz](http://git.fibbs.org/?p=egw2fbox.git;a=snapshot;h=HEAD;sf=tgz)
- Copy file `etc/egw2fbox.conf.default` to `etc/egw2fbox.conf` and update values according to your needs
- Test in verbose mode: `/path/to/egw2fbox/bin/cronjob.sh -v -c /path/to/egw2fbox/etc/egw2fbox.conf`
- Add to your crontab:
>>>>>>> 0b39bd061060d9c96fa1452c29ddcae314811752
`*/20 * * * * /path/to/egw2fbox/bin/cronjob.sh -c /path/to/egw2fbox/etc/egw2fbox.conf`

## CONFIGURATION FILE

This section may later describe the structure of the INI file used by this script. 
Until now, see the comments in `egw2fbox.conf.default`.

* File `egw2fbox.pl` uses command line option `-config /path/to/fileName.ini`, default is `egw2fbox.conf`.
* File `cronjob.sh` uses command line option `-c /path/to/fileName.ini`, no default value.
* File `fritzuploader.pl` searches for the value of environment variable FRITZUPLOADERCFG, default is `fritzuploader.conf`.

### eGoupware section

Configuration settings related to the eGroupware database

### Fritzbox section

Configuration settings related to the Fritzbox

### Roundcube section

Configuration settings related to the Roundcube database

### MUTT section

Configuration settings related to MUTT

## AUTHORS

- Christian Anton (@fibbs)
- Kai Ellinger

## SEE ALSO

<<<<<<< HEAD
\- MUTT command line mail client [http://www.mutt.org](http://www.mutt.org)

\- The full `egw2fbox.pl` documentation is available under [docs/markdown/README.md](docs/markdown/README.md)
=======
- Fritz Box router product family from AVM [http://www.avm.de/en/Produkte/FRITZBox/index.html](http://www.avm.de/en/Produkte/FRITZBox/index.html)
- FritzUploader to upload XML address books to a Fritz Box from Jan-Piet Mens [https://github.com/jpmens/fritzuploader](https://github.com/jpmens/fritzuploader) 
- Round Cube Web based mail client [http://roundcube.net](http://roundcube.net)
- MUTT command line mail client [http://www.mutt.org](http://www.mutt.org)
>>>>>>> 0b39bd061060d9c96fa1452c29ddcae314811752
