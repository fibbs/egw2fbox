# requires pod2readme, pod2html, pod2man, pod2markdown to be installed and working
pod2readme egw2fbox.pl ../docs/README
pod2html --infile=egw2fbox.pl --outfile=../docs/html/egw2fbox.html --title "egw2fbox documentation"
pod2man egw2fbox.pl ../docs/man/egw2fbox.1
pod2markdown egw2fbox.pl ../docs/markdown/README.md
cat ../docs/markdown/README.md | perl -e '$doPrint = 1; while(defined ( my $line = <STDIN>) ) { if ($line =~/^# INSTALLATION/) { $doPrint = 1; } if ($line =~/^# AUTHORS/) { $doPrint = 1; } if ($line =~/^# HISTORY/) { $doPrint = 0; } if ($line =~/^# API/) { $doPrint = 0; } if($doPrint) { print $line; } } ' >../README.md
{
cat <<!

\- The full \`egw2fbox.pl\` documentation is available under [docs/markdown/README.md](docs/markdown/README.md)
!
} >>../README.md
cat ../docs/markdown/README.md | perl -e '$doPrint = 1; while(defined ( my $line = <STDIN>) ) { if ($line =~/^# DESCRIPTION/) { $doPrint = 0; } if ($line =~/^# INSTALLATION/) { $doPrint = 0; } if ($line =~/^# HISTORY/) { $doPrint = 1; } if($doPrint) { print $line; } } ' >../docs/markdown/CHANGELOG.md
perl egw2fbox.pl --changelog >../docs/CHANGELOG
find ../docs -name "*.bak" -exec rm {} \;
find ../docs -ls
ls -la ../README*
rm *.tmp
