#!/usr/bin/env zsh
# this script prints a series of paragraphs:
# - each paragraph corresponds to an inotify instance
# - the first line prints the process owning that inotify instance
# - each line in the rest of the paragraph corresponds to a file being
#   watched by the inotify instance

workspace="./node_modules/"

# create an associative array of inodes to their paths in the workspace
typeset -A inode_map
# list all the files in the workspace, then pass all the paths to ls to obtain
# their corresponding inodes, then sort these lines to uniquify the inodes in case
# duplicate hard links are present; then for each line
find "$workspace" -exec ls -di {} + | sort -nu -k1,1 | while read line
do
  # split it into words by the word-separator, then initialize an array with these words
  line_arr=(${=line})
  # the first word is the inode, so assign it as the key, whereas the other words form the path
  inode_map[$line_arr[1]]="$line_arr[2,-1]"
done

# for each inotify instance (found through iterating through each
# file descriptor opened by each process and seeing if it is an
# inotify file descriptor)
find /proc/*/fd/* -type l -lname 'anon_inode:inotify' 2> /dev/null |
while read line
do
  # print the process name for later printing
  process=$(sed -e 's@^/proc/\([[:digit:]]*\)/fd/[[:digit:]]*@\1@' <<< $line)
  cat "/proc/${process}/cmdline"
  echo

  # for each path to the file descriptor
  echo $line |
  # modify it to a path to the file descriptor info file
  sed -e 's@/fd/@/fdinfo/@' |
  # and print its contents
  xargs cat |
  # filter for the lines containing information about the files
  # watched in this instance (one line corresponds to one watch)
  grep inotify |
  # extract the hex-encoded inode of the file being watched
  sed -e 's/^.*ino:\([[:xdigit:]]*\) .*$/0x\1/' |
  while read line
  do
    # if the inode corresponds to a file in the workspace
    if [[ $inode_map[$((line))] ]]
    then
      # echo the file path
      echo "$inode_map[$((line))]"
    fi
  done
  echo
done
