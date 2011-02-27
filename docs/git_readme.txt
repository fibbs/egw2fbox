- clone:
git clone ssh://kellinge@fibbs.org/var/git/egw2fbox.git egw2fbox
- add files:
git add *
git add bin/*
git add etc/*
- commit files:
git commit -a
- send to remote repo:
git remote add -m master remote ssh://kellinge@fibbs.org/var/git/egw2fbox.git
git push remote master
Enter passphrase for key '/Users/kellinge/.ssh/id_rsa': 
Counting objects: 8, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (7/7), done.
Writing objects: 100% (8/8), 6.77 KiB, done.
Total 8 (delta 0), reused 0 (delta 0)
To ssh://kellinge@fibbs.org/var/git/egw2fbox.git
 * [new branch]      master -> master
- get latest version:
git pull remote master

