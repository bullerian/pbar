#!/bin/bash

src=$1
dst=$2
barChar='='
fileList=0
totalSize=0
terminalWidth=$(tput cols)
declare -A sizesOfFiles

#Generates test file
#dd if=/dev/zero of=source count=400000 bs=1000 iflag=fullblock

progressbar(){
  readonly local BAR_START=$'\033[1m[\033[32m'
  readonly local BAR_END=$'\033[0m]\033[0m'
  local progCharCount
  local percent=$1
  # reserve 15 chars for progress info string in form
  # YYY%_XXX_of_ZZZ
  readonly local RESERV_SYMB_COUNT=15
  local barMaxLen=$((terminalWidth-RESERV_SYMB_COUNT))

  #trim param larger then 100 to 100
  if [[ $percent -gt '100' ]]; then
    percent=100
  fi

  progCharCount=$((($percent*$barMaxLen)/100))
  string=$BAR_START$(printf '%*s' $progCharCount | tr ' ' $barChar)$(printf '%*s' $((barMaxLen - progCharCount)))$BAR_END
  echo "$string"
}

#Check if both args are folders
if [[ ! -d $src || ! -d $dst ]]; then
  echo "Source or destination is not a directory" >&2
  exit 1
fi

#get list of full file paths
fileList=$( find $src -maxdepth 1 -type f )

#associate files with their sizes
#calc total size of files in kb
for i in $fileList; do
  # unquoted echo removes tab symbols
  # so size can be properly extracted
  tmp=$(echo $(du "$i"))
  #the drawback of hash list is that it is unordered
  sizesOfFiles["$i"]=${tmp%% *}
  ((totalSize+=${sizesOfFiles["$i"]}))
done

#get total number of files in source folder
fileCount=${#sizesOfFiles[@]}

printf '\n'
#save cursor location
tput sc

#main loop
progress=0
for srcFile in "${!sizesOfFiles[@]}"; do
  cp "$srcFile" "$dst"

  # check retval of cp command
  # display progress bar on success
  # else display eror code
  if [ $? -eq 0 ]; then
    #smart way of calculating percentage
    ((progress+=$((200*${sizesOfFiles[$srcFile]}/$totalSize % 2 + 100*${sizesOfFiles[$srcFile]}/$totalSize))))
    #increment copied files counter
    ((temp++))

    tput el1
    tput rc
    tput cuu1

    # removing percentage rounding error in final result
    if [[ $temp -eq $fileCount ]]; then
      progress=100
    fi

    printf '%s %s%% %u of %u\nFile: %s' "$(progressbar $progress)" "$progress" "$temp" "$fileCount" "${srcFile/#*'/'/''}"
  else
    echo "Error code: $?"
    exit 1
  fi
done

tput el1
tput cuu1
printf '\nDone. %s bytes copied\n' "$totalSize"

exit 0
