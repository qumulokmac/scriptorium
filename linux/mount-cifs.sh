    

    sudo mount -t cifs //${STOR_ACCT}.file.core.windows.net/${FILE_SHARE} /bench -o vers=3.1.1,username=${STOR_ACCT},password=${STORE_KEY},dir_mode=0777,file_mode=0777,serverino,actimeo=30