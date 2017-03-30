#/bin/sh
#install the package of depend
ROOTDIR=`pwd`
DATE=`date +%y%m%d`
JENKHOMEDIR=/home/jenkins/
function installdepend(){
    for package in wget gcc make curl
    do
        if [ `dpkg -l | grep $package | wc -l` = 0 ];
        then
            apt-get install -y $package
        else
            echo "package $package was installed!"
        fi
    done
}
#install the jdk
function installjdk(){
    if [ `which java | wc -l` -eq 0 ];
    then
        mkdir /usr/src/jenkins_soft
        cd /usr/src/jenkins_soft
        if [ `ls -l | grep jdk-8u121-linux-x64.tar.gz | wc -l` -eq 1 ];
        then
            echo "jdk is installing"
            rm -rf jdk1.8.0_121
            tar zxf jdk-8u121-linux-x64.tar.gz
            mv jdk1.8.0_121 /usr/jdk
            echo "export PATH=$PATH:/usr/jdk/bin" >> /etc/profile
            source /etc/profile
            echo "jdk has installed"
        else
            wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz
            tar zxf jdk-8u121-linux-x64.tar.gz
            mv jdk1.8.0_121 /usr/jdk
            echo "export PATH=$PATH:/usr/jdk/bin" >> /etc/profile
            source /etc/profile
        fi
    else
        echo "java is installed"
    fi
}
#add the user jenkins
function adduser(){
    if [ `cat /etc/passwd | grep jenkins | wc -l` -eq 0 ];
    then
        echo "create the user"
        useradd -m jenkins -d $JENKHOMEDIR
        echo jenkins:0 | chpasswd
        echo "modify the privilege of jenkins"
        echo "backup file:sudoers"
        cp -rf /etc/sudoers /etc/sudoers.bk$DATE
        echo "add the line to sudoer file"
        $ROOTDIR/append_user.sed /etc/sudoers > /etc/sudoers.bk
        mv /etc/sudoers.bk /etc/sudoers
        echo "complete!"
    else
        echo "user jenkins has installed!"
    fi
}
function keysgen(){
echo "生成ssh秘钥对:"
#生成脚本
cat>$JENKHOMEDIR/ssh-keysgen.sh <<EOF
#!/usr/bin/expect 
spawn ssh-keygen -t rsa
expect "Enter file in which to save the key*"
send "\n"
expect "Enter passphrase*"
send "\n"
expect "Enter same passphrase*"
send "\n\r"
expect eof
exit
EOF
chown jenkins:jenkins $JENKHOMEDIR/ssh-keysgen.sh
chmod +x $JENKHOMEDIR/ssh-keysgen.sh
#切换用户生成
su - jenkins <<EOF
$JENKHOMEDIR/ssh-keysgen.sh
exit
EOF
cat $JENKHOMEDIR/.ssh/id_rsa.pub > $JENKHOMEDIR/.ssh/authorized_keys
chmod 700 $JENKHOMEDIR/.ssh/authorized_keys
chown jenkins:jenkins $JENKHOMEDIR/.ssh/authorized_keys
cp -rf $JENKHOMEDIR/.ssh/id_rsa $ROOTDIR
rm -rf $JENKHOMEDIR/ssh-keysgen.sh
}
echo "-------------------------------------创建依赖-------------------------------------"
installdepend
echo "-------------------------------------安装jdk-------------------------------------"
installjdk
echo "-------------------------------------创建用户-------------------------------------"
adduser
echo "------------------------------------创建秘钥对------------------------------------"
keysgen
echo "-----------------jenkins node安装完成,请在jenkins服务器添加node-------------------"
