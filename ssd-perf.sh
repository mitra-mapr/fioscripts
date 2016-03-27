#!/bin/sh
# mitra-mapr  vi: set ai et sw=3 tabstop=3: 03/26/2016

# This script needs to be run with root user.
[ $(id -u) -ne 0 ] && { echo This script must be run as root; exit 1; }

# fio utility is used to measure the SSD performances. Check to see if the fio is installed.
if [[ -z $(which fio)  ]] ; then
    echo " fio could not be found on this server. Please install fio."
    echo " If it is already installed Please update the PATH env variable."
    exit
fi

# Script Usage : ./script-name file-name-with-list-of-ssds
if [[ $# -ne 1 ]]
then
    echo "Usage : $0 disklist.txt"
    exit
fi

DISKLISTFILE=$1

if [[ ! -f ${DISKLISTFILE} ]]
then
        echo "Disklistile : ${DISKLISTFILE} doesn't exist"
        exit
fi


for disk in $(cat ${DISKLISTFILE})
do

    ## For each disk run sequential-read, sequential-write, random-read, and random-write.
    ## Block Sizes for each-type of the run :
    ## Sequential-read : 128 KB, Sequential-write: 128 KB
    ## Random-read : 4 KB, Random-write: 4 KB
    
    ( 
        OUTPUTFILE=`basename $disk`-fio.log
	rm -rf ${OUTPUTFILE}
        #seq-read
        fio --bs=131072 --ioengine=libaio --iodepth=32 --direct=1 --runtime=60 --rw=read --time_based --name=job --filename=${disk} --minimal |  awk -v bs=131072 -v runtype=read -F";" '{ print runtype", blk size - "bs/1024"k, bw - " $7/1024"MB/s, iops - " $8 }' >> ${OUTPUTFILE}

        #seq-write
        fio --bs=131072 --ioengine=libaio --iodepth=32 --direct=1 --runtime=60 --rw=write --time_based --name=job --filename=${disk} --minimal | awk -v bs=131072 -v runtype=write -F";" '{ print runtype", blk size - "bs/1024"k, bw - " $7/1024"MB/s, iops - " $8 }' >> ${OUTPUTFILE}

        #rand-read
        fio --bs=4096 --ioengine=libaio --iodepth=32 --direct=1 --runtime=60 --rw=randread --time_based --name=job --filename=${disk} --minimal | awk -v bs=4096 -v runtype=randread -F";" '{ print runtype", blk size - "bs/1024"k, bw - " $7/1024"MB/s, iops - " $8 }' >> ${OUTPUTFILE}

        #rand-write
        fio --bs=4096 --ioengine=libaio --iodepth=32 --direct=1 --runtime=60 --rw=randwrite --time_based --name=job --filename=${disk} --minimal | awk -v bs=4096 -v runtype=randwrite -F";" '{ print runtype", blk size - "bs/1024"k, bw - " $7/1024"MB/s, iops - " $8 }' >> ${OUTPUTFILE}

    ) &

done

echo "Waiting for fios to finish."
wait
echo
exit 0

