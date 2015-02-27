#!/bin/bash
# The MIT License (MIT)
#
#Copyright (c) 2015 JP Senior jp.senior@gmail.com
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#Super cool file copy thing by JP
#instructions
#put the 'master data' in the location $master points to
#set the $devices variable to a list of valid USB devices [trial and error]
#run!

#requires lsscsi binary for convenience
#
# I have had a few cases where I have needed to quickly copy a bunch of data to a number of
# usb devices really fast.
# To use:
# a) Copy master data to /mnt/master
# b) plug in USB flash drive(s)
# c) Run script -- press 'enter' when all of the copying is done, and keep going.

master="/mnt/master"

## Do not edit below this line

makeit ()
{
  if [ -b /dev/$1 ]
  then
    echo "Formatting /dev/$1"
    umount -f /dev/$1 > /dev/null 2>&1
    rm -rf /mnt/$1
    sleep 2
    mkdosfs -F 32 -I /dev/$1
    sleep 2
    mkdir -p /mnt/$1
    mount /dev/$1 /mnt/$1
    if [ $? -eq 0 ]
    then
      sleep 2
      cp -vr $master/. /mnt/$1/
    else
      echo "Experienced an error $?"
    fi
    sleep 2
  else
    echo "Something may be missing for /dev/$1"
  fi


}


while [ 1 -eq 1 ]
do

devices=$(lsscsi | egrep "UDisk" | awk -F"/" '{print $3}')
count=$(echo $devices | wc -w )
echo $count
n=0
for i in $devices

do
  n=$((n+1))
  #checking
  #Create the mount point, why not. :)
  mkdir -p /mnt/$i
  #check md5
  #empty string
  nullmd5=$(md5sum /dev/null | awk '{ print $1 }')
  #master copy of files
  md5master=$(find $master -type f -exec md5sum {} + | awk '{ print $1 }' | sort | md5sum | awk '{ print $1 }')
  #unmount it...
  umount -f /dev/$i > /dev/null 2>&1
  #Attempt to mount the device
  mount /dev/$i /mnt/$i
  if [ $? -eq 0 ]
  then
    #echo "Mount OK"
    md5=$(find /mnt/$i -type f -exec md5sum {} + | awk '{ print $1 }' | sort | md5sum | awk '{ print $1 }')
    if [ $md5 = $md5master ]
    then
      echo "***GOOD***  $i is good $n"
    else
      echo "Copy NOT good on $i $n"
      makeit $i &
    fi
    #clean up silently
    umount -f /dev/$i > /dev/null 2>&1
  else
    echo "Copy NOT good on $i $n"
    makeit $i &
  fi
  #cleanup
  umount -f /dev/$i > /dev/null 2>&1
  rm -rf /mnt/$i
done

read -n1 -p "Hit a key dude" key
done
