pod2readme egw2fbox.pl ../docs/README
pod2html --infile=egw2fbox.pl --outfile=../docs/html/egw2fbox.html --title "egw2fbox documentation"
pod2man egw2fbox.pl ../docs/man/egw2fbox.1
pod2markdown egw2fbox.pl README.md.tmp
cat README.md.tmp | perl -e '$doPrint = 1; while(defined ( my $line = <STDIN>) ) { if ($line =~/^# INSTALLATION/) { $doPrint = 1; } if ($line =~/^# AUTHORS/) { $doPrint = 1; } if ($line =~/^# HISTORY/) { $doPrint = 0; } if ($line =~/^# API/) { $doPrint = 0; } if($doPrint) { print $line; } } ' >../README.md
perl egw2fbox.pl --changelog >../docs/CHANGELOG
find ../docs -name "*.bak" -exec rm {} \;
find ../docs -ls
ls -la ../README*
rm *.tmp

