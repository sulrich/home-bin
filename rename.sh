#!/bin/sh
# Rename multiple files.   Invoked as 
#       rename regexp replacement [ filenames ]
# If the third argument is omitted, works on all files in the 
# current directory that match the first (regexp) argument.
# Some gotchas:  
#   1.  a command like "rename txt ms" will rename txtfile.txt as
#       msfile.txt UNLESS you 'anchor' the regexp (with $ or ^)
#   2.  Unless you understand how the shell interprets the command
#       line, it's safest put single quotes (') around the regexp.
#   3.  the regexp must ONLY match the part of the name you want
#       to replace. 
#   4.  Make sure to quote dots when changing extensions.
#       rename '.c' .h will often do the wrong thing.
#       rename '\.c' .h   usually works.
#       rename '\.c$' .h  is even better.
myname=`basename $0`
# In this implementation, we'll query whenever a replacement
# would overwrite a file.  The brave at heart (or foolish)
# will change this to mv -f.
move="/bin/mv -i"
# Figure out what files we want to work with
case "$#" in
0|1)    echo "Usage: $myname regexp replacement [ filenames ]" 1>&2; exit 1;;
*)      regexp="$1"; replace="$2"
        shift; shift
        ;;
esac
# If no filenames on command line, use all files.
# The set x and shift stop errors if first filename starts with a "-"
case "$#" in
0)      set x *; shift ;;
esac
# rename files, one at a time
for file
do
        # generate the new filename with sed
        newname=`echo $file | sed -e "s/$regexp/$replace/"`
        # Make sure that a match and replacement actually occurred.
        # (If not, we'll just skip to the next iteration, rather
        # than let 'mv' catch the error)
        if [ "$file" = "$newname" ]
        then
                echo "$myname: skipping $file; would have same name." 1>&2
                continue
        fi
        # Make sure the move actually took place without error.
        if $move "$file" "$newname"
        then :
        else echo "$myname: '$move $file $newname' failed?" 1>&2
        fi
done
