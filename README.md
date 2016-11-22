# Install a "Perl" module into a non-standard directory

In practice, a standard "perl Makefile.PL" will be done to create the "Makefile", but this 
time we will make use of non-standard "Perl" installation directory instead of the default one
through an explicit declaration of all the "target" directories (parameters). 

Script expects two input command line arguments (positional parameters) :
* $1 : the path to the non-standard "Perl" installation directory (local repository).
* $2 : the path to the "make-file" of the Perl "module" we're about to install.

**Prerequisite** : "package" should be previously downloaded from the "CPAN" repository [ http://search.cpan.org/ ];
  for example : $ wget http://www.cpan.org/modules/by-module/lib/local-lib-1.008004.tar.gz
  Then we should unpack the "package" ( in our example : $ tar xzf local-lib-1.008004.tar.gz ), and 
  finally we should change to the newly created directory of the Perl "module" we're about to install; 
  i.e. the directory that contains the "make-file" ( Makefile.PL ); 
  in our example : $ cd local-lib-1.008004/.

**Important Note** : running "perl Makefile.PL" may print out a (long) list of missing "CPAN" module's 
  "dependencies"; failing to have the required modules (or the right versions thereof) will be fatal. 
  Unfortunately, this script does not install all those "dependencies" automatically; you should 
  carefully review "perl Makefile.PL" console output and (pre)install them - if necessary - manually. 
  Alternatively, you should make use of tools like "CPAN", which installs "Perl" modules with a fairly 
  simple interface, while it automatically confirms, downloads and installs any "dependencies".

**Troubleshooting** : "Perl" searches the directories listed in "@INC", and because "@INC" contains 
  only the default directories (plus the "." directory), it cannot find an already "locally" 
  installed "prerequisite" package. In such a case, we should also define/change the "PERL5LIB" 
  environment variable as follows for example:
  ```shell
    % export PERL5LIB=<local-repository>/lib/perl5/5.24.0:\
        <local-repository>/lib/perl5/site_perl/5.24.0:\
        <local-repository>/lib/perl5/site_perl 
  ```
  "Perl" should automatically prepend the architecture-specific directories to "@INC" if those exist.
  Finally, we can verify the value of the newly configured "@INC" by executing "perl -V".
