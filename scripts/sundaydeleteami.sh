#! /bin/bash

dat=$(date +"%Y%m%d")
daty=$(date -d "30 day ago" '+%Y%m%d')
DTIME_NOW=`date +%Y-%m-%d_%H-%M-%S`
######################################
conf=$HOME/amiscript/conf/$1amibkp.conf
amidir=`cat $conf|grep amidir | cut -d "=" -f 2`
logd=`cat $conf|grep logd | cut -d "=" -f 2`
logfile=$logd/$dat.txt
amifile=$amidir/$dat.txt
snapfile=$amidir/snap$DTIME_NOW.txt
yamifile=$amidir/$daty.txt
imagenameprf=`cat $conf|grep imagenameprf | cut -d "=" -f 2`
#MAILTOADDRS=`cat $conf|grep mailaddrs | cut -d "=" -f 2 | tr -d '"'`
MAILTOADDRS=`cat $HOME/amiscript/conf/emidlist.txt | grep mailaddrs | cut -d "=" -f 2 | tr -d '"'`
# Checking Conf File
if [ -f "$conf" ]
 then 
     echo "Time: $(date) $conf found" >> $logfile
 else 
     echo "Time: $(date) $conf not found" >> $logfile
     SUBJ1="ERROR, $1 $imagenameprf AMI Delete Script Exited with error for date $dat because AMI conf file not found"
     cat "$logfile" | heirloom-mailx  -s "$SUBJ1"  "$MAILTOADDRS"
     exit
fi

# Checking AMI  file for AMIID

if [ -f "$amifile" ]
 then 
      echo "Time: $(date) AMI Creation script excuted for $dat"  >> $logfile
      #echo "Seraching for $daty AMI" >> $logfile      
      echo "Time: $(date) Checking $dat AMI status" >> $logfile 
      amiid=`cat $amifile | grep ami | cut -d ":" -f 2 | tr -d "{ " | tr -d "} " | tr -d '" '` 
      amistat=`aws ec2 describe-images --image-ids  $amiid | grep "State" | cut -d ":" -f 2 | tr -d '^"' | tr -d ',' | tr -d '^ '`
      vov="available"
      if [ "$amistat" = "$vov" ];
      then 
              echo "Time: $(date) $dat AMI status is available" >> $logfile                
              echo "Time: $(date) Checking $daty AMI existenss" >> $logfile
              if [ -f "$yamifile" ]
              then
                 echo "Time: $(date) $daty AMIID found in $yamifile"  >> $logfile
                 oldamiid=`cat $yamifile | grep ami | cut -d ":" -f 2 | tr -d "{ " | tr -d "} " | tr -d '" '`
                 echo "Time: $(date) Checking $daty AMI status" >> $logfile
                 amiystat=`aws ec2 describe-images --image-ids  $oldamiid | grep "State" | cut -d ":" -f 2 | tr -d '^"' | tr -d ',' | tr -d '^ '` 
                 yov="available"
                 if [ "$amiystat" = "$yov" ];
                    then
                    echo "Time: $(date) $daty AMI status is available" >> $logfile
                    echo "Time: $(date) going to delete AMI and its related Snapshots" >> $logfile                             
                    echo "Time: $(date) Find snapshots associated with AMI for $daty AMI id $oldamiid"  >> $logfile 
                    #Find snapshots associated with AMI.
                    aws ec2 describe-images --image-ids $oldamiid | grep snap |  awk ' {print $2} ' | tr -d '"' | tr -d "," > $snapfile
                    echo  "Time: Following are the snapshots associated with it : `cat $snapfile`:\n " >> $logfile
                    if [ -s $snapfile ]
                        then
                        echo "Time: $(date) $snapfile is not empty" >> $logfile
                        echo  "Time: $(date) Starting the Deregister of AMI... \n" >> $logfile
                        #Deregistering the AMI 
                        aws ec2 deregister-image --image-id $oldamiid 2>&1 | tee >> $logfile
                        echo "Time: $(date) \nDeleting the associated snapshots.... \n" >> $logfile
                        #Deleting snapshots attached to AMI
                        for i in `cat $snapfile`;do aws ec2 delete-snapshot --snapshot-id $i ; done
                    else
                      echo "Time: $(date) $snapfile is empty, not deleting AMI. exiting" >> $logfile
                      SUBJ2="ERROR, $1 $imagenameprf AMI Delete Script Exited with error for date $dat because no snapshosts found for AMI"
                      cat "$logfile" | heirloom-mailx  -s "$SUBJ2"  "$MAILTOADDRS"
		      exit
                    fi            
                 else 
                     echo "Time: $(date) $daty AMI status is not available, exiting" >> $logfile
                     SUBJ3="ERROR, $1 $imagenameprf AMI Delete Script Exited with error for date $dat because $dat AMI status is not available"
                     cat "$logfile" | heirloom-mailx  -s "$SUBJ3"  "$MAILTOADDRS"
		     exit
                     fi 
              else 

                echo "Time: $(date) $daty AMI not found" >> $logfile 
                SUBJ4="ERROR, $1 $imagenameprf AMI Delete Script Exited with error for date $dat because $daty AMI not found"
                cat "$logfile" | heirloom-mailx  -s "$SUBJ4"  "$MAILTOADDRS"
		exit
             fi
     else 
               echo "Time: $(date) $dat AMI status is $amistat , Not Deleteing Yesterday AMI" >> $logfile
               exit
               SUBJ5="ERROR, $1 $imagenameprf AMI Delete Script Exited with error for date $dat because $dat AMI status is not available"
     cat "$logfile" | heirloom-mailx  -s "$SUBJ5"  "$MAILTOADDRS"
     fi 
 else 
      echo "Time: $(date) $dat AMI not found , check the AMI creation script log" >> $logfile
fi

SUBJ="$1 $imagenameprf AMI Delete Script Succsesfully Excuted for date $dat"

cat "$logfile" | heirloom-mailx  -s "$SUBJ"  "$MAILTOADDRS"
  
