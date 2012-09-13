#!/usr/bin/perl
#updates git submodules for vim bundles
#

use warnings;
use strict;

use Cwd;
chdir("..");
my $startPath = cwd();

open MODULE, ".gitmodules" or die ".gitmodules file does not exist!";

while(<MODULE>){
  if(/path\s+=\s+(.+?)$/){
    chdir($1);
    print $1."\n";
    `git checkout master`;
    `git fetch`;
    `git rebase origin/master`;
    chdir($startPath);
  }
}
