


#remove root password
sed -i 's|$2b$10$qS3/zFLn/6wTQrjNhAddEepvKw.XculyRsXH60FLXjcj5fQeZzIQu||' /etc/master.passwd
pwd_mkdb -p /etc/master.passwd


#enable autologin with root in the console
#echo "su - root" >>/etc/rc.local



