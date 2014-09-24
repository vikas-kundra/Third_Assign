str_iden="ashish_key"
dir_string="sudo ssh -i $str_iden agaur@10.33.1.230 '[ -d /home/agaur/temp1 ]'"
conn_string="ssh -i $str_iden agaur@10.33.1.230"

function NewFun(){


echo "Input the Remote Server Directory"
read DirPath
if (  $conn_string "[ -d $DirPath ]" ); then
    echo "Direcoty is present"
    echo "Enter The Local Directory Which Needs To be Mirrored"
    read InputDir
    echo "Value input is $InputDir"
    
    if [ -d $InputDir ]
    then
        echo "Directory is Present on Local System"
        dir_to_be_searched=$InputDir
        
    else
        dir_to_be_searched=$(pwd)
    fi

    echo "Value of Directory in local system is=$dir_to_be_searched"
    echo "Enter the patteren to be seached for in file Names"
    read pattern
    len_pattern=${#pattern}	

    if [[ $len_pattern -ne 0 ]]; then
    	($conn_string "cd $DirPath;touch serverFile;ls -ltr|grep $pattern>serverFile")
    else
        ($conn_string "cd $DirPath;touch serverFile;ls -ltr>serverFile")

    fi

    scp -i ashish_key agaur@10.33.1.230:$DirPath/serverFile $dir_to_be_searched
    copy_status=$?
    
    ##Removing Server File After It Has Been Copied Successfully From Server
    if [[ $copy_status -eq 0 ]]; then
        #statements
        $conn_string "cd $DirPath;rm serverFile"
    fi
    #echo "Remote Files are "
    #cat serverFile	
    cd $dir_to_be_searched
    touch Local_Files
    touch Server_Files
    cat serverFile|awk '{OFS=" "}{print $6,$7,$8,$9}'>Server_Files
    ls -ltr $dir_to_be_searched|awk '{OFS=" "}{print $6,$7,$8,$9}'>Local_Files
    #echo "###########Server Files are $server_files"
#echo $server_files>Server_Files


    file_Values=$(diff  Server_Files Local_Files |grep "<"|awk '{print $5}')
    #echo "Different Files are"
    touch file_to_be_copied
    for file in $file_Values
    do
    	
    	echo $file>>file_to_be_copied
    
    done


    touch file_to_be_deleted	
    outdated_files_check=$(cat serverFile|awk '{OFS="#@"}{print $6,$7,$8,$9}')
    echo "Value For Check is $outdated_files_check"
    for outdated_file in $outdated_files_check
    do
    	date_val=$(echo $outdated_file|awk -F '#@' '{print $1,$2,$3}')
        #echo "date Val is $date_val"
        diff=$(date -d "$date_val" +%s)
        #echo "Val is $diff"
        now_date=$(date +%s)
        #echo "Difference is $diff"
        #echo "Present time is $now_date"
        Actual_Diff=$((($now_date-$diff)/3600/24))
        #echo "Difference in days is $Actual_Diff"
        touch file_to_be_deleted
        if [[ $Actual_Diff -ge 10 ]]; then
        	echo $outdated_file|awk -F '#@' '{print $4}'>>file_to_be_deleted
        fi		


    done




    ###For Copying Files
    files_copied_collection=$(cat file_to_be_copied|tr '\n' ',' | sed 's/.$//')
    scp -v -i  ashish_key agaur@10.33.1.230:$DirPath/\{$files_copied_collection\}  .
    

    ###For Deleting Files
    value_del=$(cat file_to_be_deleted)
    val=$(echo $value_del)
    #echo "Value obtained is $val"
    $conn_string "cd $DirPath;rm $val"

else
	
	echo "Directory is not Present!!!Exiting The Program"

fi

}





NewFun






