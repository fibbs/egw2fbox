pod2readme egw2fbox.pl ../docs/README
pod2html --infile=egw2fbox.pl --outfile=../docs/html/egw2fbox.html --title "egw2fbox documentation"
pod2man egw2fbox.pl ../docs/man/egw2fbox.1
perl egw2fbox.pl --changelog >../docs/CHANGELOG
find ../docs -name "*.bak" -exec rm {} \;
find ../docs -ls
rm *.tmp
