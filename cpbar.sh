#!/bin/bash -x

src=$1
dst=$2
barChar='='
fileList=0
fileCount=0
totalSize=0
progress=0
temp=0
declare -A sizesOfFiles

#Generates test file
#dd if=/dev/zero of=source count=400000 bs=1000 iflag=fullblock

progressbar(){
  readonly BAR_TOTAL_CHAR=25
  readonly local BAR_START=$'\033[1m[\033[32m'
  readonly local BAR_END=$'\033[0m]\033[0m'
  local progCharCount
  local percent=$1

  if [[ $percent -gt '100' ]]; then
    percent=100
  fi
  
    progCharCount=$((($percent*$BAR_TOTAL_CHAR)/100))
    string=$BAR_START$(printf '%*s' $progCharCount | tr ' ' $barChar)$(printf '%*s' $((BAR_TOTAL_CHAR - progCharCount)))$BAR_END
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

  if [ $? -eq 0 ]; then
    #smart way of calculating percentage
    tmp=$((200*${sizesOfFiles[$srcFile]}/$totalSize % 2 + 100*${sizesOfFiles[$srcFile]}/$totalSize))
    ((progress+=tmp))
    #echo $progress
    ((temp++))
    #echo $temp

    tput el1
    tput rc
    tput cuu1
    #echo "ok"
    printf '%s %s%% %u of %u\nFile: %s' "$(progressbar $progress)" "$progress" "$temp" "$fileCount" "${srcFile/#*'/'/''}"
  else
    echo "error"
    exit 1
  fi
done

tput el1
tput cuu1
printf '\nDone\n'

exit 0
