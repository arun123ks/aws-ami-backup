#! /bin/bash
dat=$(date +"%Y%m%d")
######################################
conf=$HOME/amiscript/conf/$1amibkp.conf
amidir=`cat $conf|grep amidir | cut -d "=" -f 2`
logd=`cat $conf|grep logd | cut -d "=" -f 2`
inctanceid=`cat $conf|grep inctanceid | cut -d "=" -f 2`
imagenameprf=`cat $conf|grep imagenameprf | cut -d "=" -f 2`
logfile=$logd/$dat.txt
amifile=$amidir/$dat.txt
#MAILTOADDRS=`cat $conf|grep mailaddrs | cut -d "=" -f 2`
##MAILTOADDRS=`cat $conf|grep mailaddrs | cut -d "=" -f 2 | tr -d '"'`
MAILTOADDRS=`cat $HOME/amiscript/conf/emidlist.txt | grep mailaddrs | cut -d "=" -f 2 | tr -d '"'`
########### Checking conf file exists or not ##########################################

if [ -f "$conf" ]

 then 
     echo "Time: $(date) $conf found" 

 else 
     echo "Time: $(date) $conf not found" 
     SUBJ1="ERROR, $1 $imagenameprf AMI Create Script Exited with error for date $dat because AMI conf file not found"
     heirloom-mailx  -s "$SUBJ1"  "$MAILTOADDRS"

     exit 
fi



if [  ! -z "$amidir" ] ||  [ ! -z "$logd" ] || [ ! -z "$inctanceid" ] || [ ! -z "$imagenameprf" ]; 
 then  
     touch $logfile
     echo $amidir >> $logfile	 
     mkdir -p $logd
     mkdir -p $amidir
     echo "Time: $(date) all variable values found" >> $logfile 
 else 
     echo "Time: $(date) allaribales values are not found" >> $logfile 
     SUBJ2="ERROR, $1 $imagenameprf AMI Create Script Exited with error for date $dat because some parameter is empty in conf file"
     cat "$logfile" | heirloom-mailx -s "$SUBJ2"  "$MAILTOADDRS"
     exit
fi      


########Creating directory if not exists ##########################################


###################################################################################



if [ -f "$amifile" ]

 then 

      echo "Time: $(date) Script already excuted for $dat"  >> $logfile
      SUBJ3="ERROR, $1 $imagenameprf AMI Create Script Exited with error for date $dat because AMI crete script excuted for $dat already"
      cat "$logfile" | heirloom-mailx  -s "$SUBJ3"  "$MAILTOADDRS"
      exit 

 else 

touch $amifile

  if [ $? -eq 0 ]
        then
  

name=$imagenameprf$dat

aws ec2 create-image --instance-id $inctanceid --name "$name" --description "An AMI server" --no-reboot  > $amifile


      if [ $? -eq 0 ]
        then
            echo "Time: $(date) ami created sucsessfuly" >> $logfile
            SUBJ4=" $1 $imagenameprf AMI Created sucsessfuly for date $dat "
            cat "$logfile" | heirloom-mailx   -s "$SUBJ4"  "$MAILTOADDRS"
            exit
        else 
  
           echo "Time: $(date) unbale to create AMI" >> $logfile
           SUBJ5="ERROR, Unbale to create $1 $imagenameprf AMI $dat "
           cat "$logfile" | heirloom-mailx   -s "$SUBJ5"  "$MAILTOADDRS"
           exit
     fi     
 
   else  

      echo "Time: $(date) unbale to create $amifile" >> $logfile
      SUBJ6="ERROR, unbale to create $1 $imagenameprf AMI because $amifile couldn't create for date $dat "
      cat "$logfile" | heirloom-mailx   -s "$SUBJ6"  "$MAILTOADDRS"
      exit
 fi 

fi 


