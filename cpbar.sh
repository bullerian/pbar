#!/bin/bash

src=$1
dst=$2
barChar='='
fileList=0
fileCount=0
totalSize=0
progress=0
temp=0
declare -A sizesOfFiles

#Genereates test file
#dd if=/dev/zero of=source count=400000 bs=1000 iflag=fullblock

progressbar(){
  readonly BAR_TOTAL_CHAR=25
  readonly local BAR_START=$'\033[1m[\033[32m'
  readonly local BAR_END=$'\033[0m]\033[0m'
  local progCharCount

  if [[ $1 -le "100" && $1 -ge "0" ]]; then
    progCharCount=$((($1*$BAR_TOTAL_CHAR)/100))
    string=$BAR_START$(printf '%*s' $progCharCount | tr ' ' $barChar)$(printf '%*s' $((BAR_TOTAL_CHAR - progCharCount)))$BAR_END
    echo "$string"
  fi
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
  tmp=$(echo $(du "$i"))
  sizesOfFiles["$i"]=${tmp%% *}
  ((totalSize+=${sizesOfFiles["$i"]}))
done

#get total number of files in source folder
fileCount=${#sizesOfFiles[@]}

printf '\n'
tput sc

#main loop
for srcFile in "${!sizesOfFiles[@]}"; do
  cp "$srcFile" "$dst"

  if [ $? -eq 0 ]; then
    currProgress=0
    currProgress=$(bc -l <<< "scale=2; ${sizesOfFiles[$srcFile]} / $totalSize * 100")
    ((progress+= ${currProgress/.*/''}))
    ((temp++))

    tput el1
    tput rc
    tput cuu1

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
