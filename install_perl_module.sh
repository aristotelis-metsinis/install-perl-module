#!/bin/bash
#
# Install a "Perl" module into a non-standard directory.
#
# In practice, a standard "perl Makefile.PL" will be done to create the "Makefile", but this 
# time we will make use of non-standard "Perl" installation directory instead of the default one
# through an explicit declaration of all the "target" directories (parameters). 
#
# Script expects two input command line arguments (positional parameters) :
#   $1 : the path to the non-standard "Perl" installation directory (local repository).
#   $2 : the path to the "make-file" of the Perl "module" we're about to install.
#
# PREREQUISITE : "package" should be previously downloaded from the "CPAN" repository [ http://search.cpan.org/ ];
#   for example : $ wget http://www.cpan.org/modules/by-module/lib/local-lib-1.008004.tar.gz
#   Then we should unpack the "package" ( in our example : $ tar xzf local-lib-1.008004.tar.gz ), and 
#   finally we should change to the newly created directory of the Perl "module" we're about to install; 
#   i.e. the directory that contains the "make-file" ( Makefile.PL ); 
#   in our example : $ cd local-lib-1.008004/.
#
# IMPORTANT NOTE : running "perl Makefile.PL" may print out a (long) list of missing "CPAN" module's 
#   "dependencies"; failing to have the required modules (or the right versions thereof) will be fatal. 
#   Unfortunately, this script does not install all those "dependencies" automatically; you should 
#   carefully review "perl Makefile.PL" console output and (pre)install them - if necessary - manually. 
#   Alternatively, you should make use of tools like "CPAN", which installs "Perl" modules with a fairly 
#   simple interface, while it automatically confirms, downloads and installs any "dependencies".
#
# TROUBLESHOOTING : "Perl" searches the directories listed in "@INC", and because "@INC" contains 
#   only the default directories (plus the "." directory), it cannot find an already "locally" 
#   installed "prerequisite" package. In such a case, we should also define/change the "PERL5LIB" 
#   environment variable as follows for example:
#     % export PERL5LIB=<local-repository>/lib/perl5/5.24.0:\
#         <local-repository>/lib/perl5/site_perl/5.24.0:\
#         <local-repository>/lib/perl5/site_perl 
#   "Perl" should automatically prepend the architecture-specific directories to "@INC" if those exist.
#   Finally, we can verify the value of the newly configured "@INC" by executing "perl -V".
#

# Set fonts for help.
NORM=$(tput sgr0)
BOLD=$(tput bold)

# Script expects two input command line arguments (positional parameters) :
#   $1 : the path to the non-standard "Perl" installation directory (local repository).
#   $2 : the path to the "make-file" of the Perl "module" we're about to install.
if [ "$#" -ne 2 ]; then
    echo
	echo "  ${BOLD}Usage${NORM} : ./$(basename "$0") LOCAL_REPOSITORY MAKE_FILE"
	echo
	echo "  ${BOLD}Examples${NORM} :"
	echo "    ./$(basename "$0") lib/ SOAP-Lite-1.12/Makefile.PL"
	echo "    ./$(basename "$0") lib/ LWP-Protocol-https-6.06/Makefile.PL"
	echo
	exit 1
fi

# Make sure that the input "local repository" (directory) exists.
if [ ! -d "$1" ]
then
    echo
    echo "  ${BOLD}Error${NORM} : local repository '$1' does not exist."
	echo
	exit 1
fi

# Make sure that the input "make-file" exists.
if [ ! -f "$2" ]
then
    echo
    echo "  ${BOLD}Error${NORM} : make-file '$2' does not exist."
	echo
	exit 1
fi

#----------------------------------------------------------------------------------------------
# "Local repository" configurations :

# Input path of target "local repository" of Perl "modules".
local_repository="$1"
# Canonical file name of the given "local repository".
local_repository=$(readlink -f "$local_repository")

# Explicit declaration of all "target" (non-standard "Perl" installation) directories.
PREFIX="PREFIX=$local_repository"
INSTALLPRIVLIB="INSTALLPRIVLIB=$local_repository/lib/perl5"
INSTALLSCRIPT="INSTALLSCRIPT=$local_repository/bin"
INSTALLSITELIB="INSTALLSITELIB=$local_repository/lib/perl5/site_perl"
INSTALLBIN="INSTALLBIN=$local_repository/bin"
INSTALLMAN1DIR="INSTALLMAN1DIR=$local_repository/lib/perl5/man"
INSTALLMAN3DIR="INSTALLMAN3DIR=$local_repository/lib/perl5/man3"
# Use explicit "target" parameters based upon the above given declarations.
target_parameters=$(printf "%s \ %s \ %s \ %s \ %s \ %s \ %s" "$PREFIX" "$INSTALLPRIVLIB" "$INSTALLSCRIPT" "$INSTALLSITELIB" "$INSTALLBIN" "$INSTALLMAN1DIR" "$INSTALLMAN3DIR")

#----------------------------------------------------------------------------------------------
# "Make-file" configurations :

# Input path of Perl module "make-file".
make_file="$2"
# Canonical file name of the given "make-file".
make_file=$(readlink -f "$make_file")
# Remove the (full) file path from input "make-file" file name; i.e. file "name" with any leading directory components removed.
make_file_filename=$(basename "$make_file")
# Strip non-directory suffix from input "make-file" file name and return the absolute path to the directory the "make-file" is located.
make_file_directory=$(dirname $(readlink -f "$make_file"))
# Fetch the package "NAME" - representing the distribution - from the given "make-file". 
# For example, "Test::More" or "ExtUtils::MakeMaker". In theory, any package distribution must have a "NAME".
package_name=$(grep "^[[:space:]]*[\'\"]*NAME[\'\"]*[[:space:]]*=>.*" $make_file| sed "s/^.*=> *['\"]\(.*\)['\"].*$/\1/")

#----------------------------------------------------------------------------------------------
# "Silent" module installation: to prevent this "script" from getting into an "interactive" mode during the 
# installation, we should try setting the following environment variable(s) before running it. In practice, 
# we are trying to "simulate" the behaviour of a "CPAN" client.                                                        

# If environment variable "PERL_MM_USE_DEFAULT" set to a "true" value then "ExtUtils::MakeMaker's prompt()" function will 
# always return the "default" without waiting for user input. We set this environment variable to a "true" 
# value by default; although its side effect on the installation process is not fully tested.
# Notes: * The following set-up makes "Perl" automatically answer "yes" when "CPAN" asks. 
#        * If "prompt()" detects that it is not running interactively and there is nothing on "STDIN" or if the
# 		   "PERL_MM_USE_DEFAULT" environment variable is set to true, the "$default" will be used without prompting. 
# 		   This prevents automated processes from blocking on user input. If no "$default" is provided an empty string 
#		   will be used instead.
#        * We might stick "export PERL_MM_USE_DEFAULT=1" in ".bashrc" (or equivalent for the preferred shell) to stop the 
#		   prompts generally.
export PERL_MM_USE_DEFAULT=1
# In theory the above configuration should be sufficient for a "silent" package installation. If not then the 
# following configurations of the corresponding environment variables could be also examined.

# When "CPAN" runs, it sets the environment variable "PERL5_CPAN_IS_RUNNING" to the "ID" of the running process.
# export PERL5_CPAN_IS_RUNNING=$$

# "CPAN" also sets "PERL5_CPANPLUS_IS_RUNNING" to the current process "ID" to prevent runaway processes, which could 
# happen with older versions of "Module::Install".
# export PERL5_CPANPLUS_IS_RUNNING=$$

# When running "perl Makefile.PL", the environment variable "PERL5_CPAN_IS_EXECUTING" is set to the full path of the
# "Makefile.PL" that is being executed. This prevents runaway processes with newer versions of "Module::Install".
# export PERL5_CPAN_IS_EXECUTING=$(readlink -f "$make_file")

# Set "PERL_CORE" environment variable only when "MakeMaker" is building the extensions of the "Perl" core distribution.
# export PERL_CORE=1

#----------------------------------------------------------------------------------------------
# Execute installation "task" (command); i.e. either "perl Makefile.PL" or "make" or "make test" or finally "make install".
# Function expects one of the above mentioned tasks as input argument. In case of error (non-zero exit status) 
# prints proper "error" message and exits immediately.

function execute()
{
	# Execute the input "shell" command, redirecting "stderr" to "stdout" and displaying "KEYWORDS" of command output in colour on the terminal.
	# The colours are defined by the environment variable "GREP_COLOR".
	# Note: each command in a "pipeline" is executed in its own sub-shell. By default, the "exit status" of a "pipeline" is the "exit status" 
	# 		of the last command in the "pipeline", unless the "pipefail" shell variable option is enabled (set -o pipefail). If "pipefail" is 
	# 		enabled, the pipeline’s return status is "the value of the last (rightmost) command to exit with a "non-zero status", or zero if 
	# 		all commands exit successfully"; this only works in "bash". The shell waits for all commands in the "pipeline" to terminate before 
	#		returning a value; if the "pipeline" is not executed asynchronously.
	KEYWORDS="^|WARNING: PREREQUISITE .* NOT FOUND.|RESULT: FAIL|ERROR|FAILED|RESULT: PASS|ALL TESTS SUCCESSFUL.|NO SUCH FILE OR DIRECTORY|NO RULE TO MAKE TARGET|WRITE PERMISSIONS|ERROR:  CAN'T LOCATE|COMMAND NOT FOUND|CAN'T LOCATE .* IN @INC|PERMISSION DENIED"
	set -o pipefail; $1 2>&1 | GREP_COLOR='01;36' egrep -i --color -E "$KEYWORDS"
	
	# Hold the "return status" of the previously run command.
	# Note: each update command in a "Makefile" rule (specifically) is probably executed in a separate "shell". 
	#       So "$?" might not contain the "exit" status of the previous "failed" command, 
	#       it might contain whatever the default value is for "$?" in a new "shell". 
	#       That's why a "[[ $? -eq 0 ]]" test might always succeed.
	local status=$?
	
	# In case of error print message and exit.
	if [[ $status -ne 0 ]]; then 
	{
		echo "${BOLD}"
		echo "  -------------------------------------------------------------------------"
		echo "  Error executing '$1'. Status = $status."
		echo "  Perl module '$package_name' installation failed."
		echo 
		echo "  Check console output - above - for errors such as : "
		echo "  missing package dependencies [ Warning: prerequisite <module> not found ],"
		echo "  write permissions, command, file or directory not found, etc."
		echo "  You may (also) need to : export PERL5LIB=\"<custom-library-path>\"."
		echo "${NORM}"
		
		exit $status
	}
	fi
}

#----------------------------------------------------------------------------------------------
# Install Perl "module" (package). 

# Prerequisite : "package" should be previously downloaded from the "CPAN" repository [ http://search.cpan.org/ ];
# for example : $ wget http://www.cpan.org/modules/by-module/lib/local-lib-1.008004.tar.gz
# Then we should unpack the "package" ( in our example : $ tar xzf local-lib-1.008004.tar.gz ), and finally we should 
# change to the newly created directory of the Perl "module" we're about to install; i.e. the directory that contains the
# "make-file" ( Makefile.PL ); for example in our example : $ cd local-lib-1.008004/.
cd "$make_file_directory"

# Create the "Makefile" by making use of non-standard "Perl" installation directory instead of the default one through
# an explicit declaration of all the "target" directories (parameters).
# Note : let's assume the following scenario. 
#   - We have installed package "A" in our "local repository". 
#   - Now, we want to install another "module" and it has "A" listed in its prerequisites list. 
#   - We know that we have "A" installed, but when we run "perl Makefile.PL" for the "module" we're about to install, 
#     we're told that we don't have "A" installed.
#   - "Perl" searches the directories listed in "@INC", and because "@INC" contains only the default directories (plus the "." directory), 
#     it cannot find the locally installed "A" package. 
#   - In such a case, we should also define/change the "PERL5LIB" environment variable as follows for example:
#       % export PERL5LIB=<local-repository>/lib/perl5/5.24.0:\
#       <local-repository>/lib/perl5/site_perl/5.24.0:\
#       <local-repository>/lib/perl5/site_perl 
#   - "Perl" should automatically prepend the architecture-specific directories to "@INC" if those exist.
#   - Finally, we can verify the value of the newly configured "@INC" by executing "perl -V".
execute "$( printf "%s %s %s" "perl" "$make_file_filename" "$( printf "%s\n" "$target_parameters" )" )"
# IMPORTANT NOTE : running "perl Makefile.PL" may print out a (long) list of missing "CPAN" module's dependencies; 
# failing to have the required modules (or the right versions thereof) will be fatal. Unfortunately, this script 
# does not install all those dependencies automatically; you should carefully review "perl Makefile.PL" console output 
# and (pre)install them - if necessary - manually. 
# For example, if we like to install "SOAP-Lite-1.20" module, "perl Makefile.PL" prints out the following list of "prerequisites" :
#   $ perl Makefile.PL
#   Warning: prerequisite Class::Inspector 0 not found.
#   Warning: prerequisite IO::SessionData 1.03 not found.
#   Warning: prerequisite LWP::Protocol::https 0 not found.
#   Warning: prerequisite Task::Weaken 0 not found.
#   Warning: prerequisite XML::Parser::Lite 0.715 not found.
#   	:
#   	:

# "make"; i.e. business as usual.
execute "make"
execute "make test"

# "make install" installs all the files in the private "repository". Note that all the missing 
# directories are created automatically.
execute "make install"

#----------------------------------------------------------------------------------------------
# At this point, we should assume that installation was finally successful.

msg="Perl module '$package_name' successfully installed."
# A separator line. The line length will be equal to the length "${#msg}" of the above "msg".
# The "--" is for indication of the end of options for "printf"; because the
# leading "-" in "format" string can confuse "printf" - make it think that’s an option.
# The "%.s" results in a "zero-length" string; with "-" leading, that results "-" as the output.
# "Brace Expansion" precedes "Parameter Expansion". So "{1..${#msg}}" does not work
# as we would like in practice; we have to also use "eval".
# So, the specified "format" is actually being used "${#msg}" times, i.e. "${#msg}" dashes.
separator=$(eval printf -- '-%.s' {1..${#msg}})	  

echo "${BOLD}"
echo "  $separator"	 
echo "  $msg"
echo "${NORM}"

exit 0
