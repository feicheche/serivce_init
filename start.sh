#!/bin/bash

#===============================================================
# Name   : start.sh
# Version: 1.0
# Writer : Gufeng
# Date   : 2017.10.15
# Modify : 
# Info   : ��������ʼ�����ýű������������������𡢽��ò���Ҫ��������
#          ��װ�ر����������yumԴ�ȵȡ�����
# History: 
#	   �μ� ChangeLog.log
#===============================================================
. /etc/profile

export black='\e[0m\c'
export boldblack='\e[1;0m\c'
export red='\e[31m\c'
export boldred='\e[1;31m\c'
export green='\e[32m\c'
export boldgreen='\e[1;32m\c'
export yellow='\e[33m\c'
export boldyellow='\e[1;33m\c'
export blue='\e[34m\c'
export boldblue='\e[1;34m\c'
export magenta='\e[35m\c'
export boldmagenta='\e[1;35m\c'
export cyan='\e[36m\c'
export boldcyan='\e[1;36m\c'
export white='\e[37m\c'
export boldwhite='\e[1;37m\c'

# echo �Ĳ�ɫ��ʾ�汾
cecho ()		
{
local default_msg="No message passed."
message=${1:-$default_msg}	# Defaults to default message.
color=${2:-$black}		# Defaults to black, if not specified.

if [ "$3" == "NOLF" ];then
{
  echo -ne "$color"
  echo -ne "$message"
  tput sgr0                     # Reset to normal.
  echo -ne "$black"
}
else
{
  echo -e "$color"
  echo -e "$message"
  tput sgr0			# Reset to normal.
  echo -e "$black"
}
fi

  return

}


# �����û���¼��Ϣ
SETINFO()
{
HASSYSINFO=`cat ~/.bashrc | grep Cooper`
if [ "$HASSYSINFO" == "" ];then
cat >> ~/.bashrc << END
IPADDRESS=\`ifconfig eth0 | grep 'inet addr' | sed 's/[ ][ ]*/ /g' | sed 's/^\ //' | cut -d ' ' -f 2 | cut -d ':' -f 2\`
echo 
echo -e "\e[1;37mDate Time\e[0m : \e[1;33m\`date '+%F %H:%M'\`\e[0m"
echo -e "\e[1;37mHost Name\e[0m : \e[1;32m\$HOSTNAME\e[0m\t\t \e[1;37mIp Address\e[0m : \e[1;32m\$IPADDRESS\e[0m"
echo 
# Cooper shell modifyed
END
fi
}

function Init()
{

# ��ȡ�����ļ�������ֵ����
while read NAME TYPE
do
if [ "$NAME" == "" ] || [ "`echo $NAME$TYPE| grep '#'`" != "" ] ;then 
continue
else
eval `echo "${NAME}=${TYPE}"`
fi
done <config.shc


# ����ϵͳ���� 32bit or 64bit 
SysPlatform=`$UnameBin -i`

# ��������ļ���
if [ ! -e /data/soft ];then
{
    # soft
    mkdir -p /data/soft/{tar,src,iso}
	
    # cache
    [ ! -e /cache ] && ln -s /dev/shm /cache
}
fi
}


# ����û�õķ���
SETUPSERVICE()
{
echo "========================"
echo "|    disable services  |"
echo "========================"
sleep 0.1
for ser in $SERVICES
do
[ -e "$SERPATH$ser" ] && echo -e "[ "$ser "] disabled..." && chkconfig $ser off 
sleep 0.1
done
cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

# ������״̬
CHECKSTATUS()
{
echo "=========================="
echo "| check services result  |"
echo "=========================="
for ser in $SERVICES
do
[ -e "$SERPATH$ser" ] && chkconfig --list $ser 
done
cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

# ���÷���ǽ
CONFIGUREFIREWALL()
{
cecho "=========================="  $boldwhite
cecho "| clear firewall config  |"  $boldwhite
cecho "==========================" $boldwhite
iptables -X
iptables -F
iptables -Z
service iptables save
service iptables restart
iptables -L -nv 
cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

# ��װ�����ر��ĳ���
ConfigYum()
{
cecho "==========================" $boldwhite
cecho "|     configure yum      |" $boldwhite
cecho "==========================" $boldwhite

[ ! -e /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag ] && cp ./conf/RPM-GPG-KEY-rpmforge-dag /etc/pki/rpm-gpg/
[ ! -e /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL ] && cp ./conf/RPM-GPG-KEY-EPEL /etc/pki/rpm-gpg/

# �����úõ�yum�����ļ����Ƶ���ӦĿ¼
for repofile in $RepoList
do
if [ -e /etc/yum.repos.d/$repofile ] ;then
{ 
    mv /etc/yum.repos.d/$repofile /etc/yum.repos.d/$repofile.`date +%Y%m%d` && \
    cp ./conf/$repofile /etc/yum.repos.d/
}
else
{
    cp ./conf/$repofile /etc/yum.repos.d/
}
fi
done


yum install $SOFTINSTALL -y
cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

# ����yum����ʱ��ϳ��������������İ���Ctrl+C�л�����վ�㣬����Ctrl+Cȡ������
UPDATEYUM()
{
echo -ne "�Ƿ�Ҫ ���� rpm����(y/n)��"
read MONITOR
MONITOR=`echo $MONITOR |tr 'A-Z' 'a-z'`
if [ "$MONITOR" == "y" ];then
yum remove -y xdelta subversion
yum update -y
yum install -y xdelta subversion
fi
cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

OTHERCONFIGURE()
{
# �޸�����ѡ���½������̨����
echo  -ne "set runlevel to 3 (console startup):"
sed -i "18 s/id:5:initdefault:/id:3:initdefault:/" $INITTAB && sleep 0.1 && echo " ok "

# �޸�root�û���bashrcѡ�����vi=vim�������
echo -ne "write [ alias vi=vim ] to ~/.bashrc :"
sed -i "8 i # auto configure shell process\nalias vi='vim'" $BASHRC  && sleep 0.1 && echo " ok "

# �޸�ll����
echo -ne "write alias ll command to /etc/bashrc:\n"
sleep 0.1
llBin=`grep 'alias ll' $SysBashrc`
if [ "$llBin" == "" ];then
echo "alias ll='ls -lh --color=tty --time-style=long-iso'" >>$SysBashrc 
else
cecho "already modify!!!" $boldred LF
fi

#===========================#
# ����Vim �� NERD Tree ��� #
#===========================#
cecho "�Ƿ�Ϊvim��װNERD Tree���?(y|n):" $boldmagenta NOLF
read input
if [ `echo $input | tr 'A-Z' 'a-z'` == "y" ];then
{
[ ! -e ~/.vim ] && mkdir -p ~/.vim
cp -rp $VimPluginsPath/$VimNERDPlugins/* ~/.vim/
}
fi

#====================================#
# crontab �ƻ����������ʱ��У������ #
#====================================#
cecho "�Ƿ�����Զ���ʱ�ƻ������yum makecache����?(y|n)" $boldmagenta NOLF
read input
if [ `echo $input | tr 'A-Z' 'a-z'` == "y" ];then
{
cat >>$CRONTABROOT <<END
# Info  : ʱ��ͬ��
# Author: zhouyq
# CTime : 2011.02.24
*/50 * * * * /usr/sbin/ntpdate ntp.api.bz time-a.nist.gov time-b.nist.gov 132.163.4.103 2>&1 >/dev/null ;/sbin/hwclock --systohc
END
cecho "done!" $boldmagenta

cecho "modify crontab add yum makecache" $boldmagenta NOLF
cat >> $CRONTABROOT <<END
# Info  : yum makecache
# Author: zhouyq
# CTime : 2011.03.30
9 */7 * * * /usr/bin/yum makecache & 2>&1 >/dev/null
END
cecho "done!" $boldmagenta
}
fi

# �������Ի���
cecho "�Ƿ��������Ի���Ϊ zh_CN.GB18030 (y|n)" $boldmagenta NOLF
read inlang
if [ `echo $inlang | tr 'A-Z' 'a-z'` == "y" ];then
{
mv /etc/sysconfig/i18n /etc/sysconfig/i18n.`date +%Y%m%d%H%M%S`
cat >>/etc/sysconfig/i18n <<END
#LANG="en_US.UTF-8"
LANG="zh_CN.GB18030"
SYSFONT="latarcyrheb-sun16"
END
cecho "done!" $boldmagenta
}
fi

# ����SelinuxΪ disabled
cecho "make selinux disable " $boldmagenta NOLF
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' $SelinuxConf
cecho "done!" $boldmagenta

# ����ssh�˿ڣ��Լ���������
echo -ne "configure ssh serivce:"
sed -i -e "13 s/#Port\ 22/Port\ 9922/" -e "74 s/GSSAPIAuthentication\ yes/GSSAPIAuthentication\ no/" \
-e "76 s/GSSAPICleanupCredentials\ yes/GSSAPICleanupCredentials\ no/" \
-e "109 s/#UseDNS yes/UseDNS no/" $SSHDCONF && sed -i -e "35 s/#   Port 22/Port 9922/g" $SSHCONF \
&& service sshd restart

# ����vim tab ���
cecho "�Ƿ�����vim tab�����?(y|n)" $boldmagenta NOLF
read input
if [ `echo $input | tr 'A-Z' 'a-z'` == "y" ];then
{
echo "set softtabstop=4" >> /etc/vimrc && cecho "done!" $boldgreen
}
fi

# ����vim ��nginx�������ļ��и���֧��
cecho "�Ƿ�����vim nginx�������ļ�����֧��?(y|n)" $boldmagenta NOLF
read input
if [ `echo $input | tr 'A-Z' 'a-z'` == "y" ];then
{
mkdir -p ~/.vim/syntax
cp ./conf/nginx.vim ~/.vim/syntax
echo "au BufRead,BufNewFile /usr/local/nginx/conf/* set ft=nginx" >> ~/.vim/filetype.vim
}
fi
cecho "done" $boldgreen 
#==================================

# ���� ����ļ�������
IsModifyLimit=`grep Cooper $LimitConf`
if [ "$IsModifyLimit" == "" ];then
cecho  "configure ulimit open files number:" $boldmagenta NOLF
cat >> /etc/security/limits.conf <<END
*       hard    nofile          102400
*       soft    nofile          102400
# Modify by Cooper
END
cecho "done!" $boldmagenta LF
fi

cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}
# Num.5
ConfigHosts()
{
# ���time.jobkoo.com,mirrors.jobkoo.com��hosts�ļ�
cecho "�Ƿ�time.jobkoo.com,mirrors.jobkoo.com������ӵ�hosts�ļ�?(y|n)" $boldmagenta NOLF
read input
if [ `echo $input | tr 'A-Z' 'a-z'` == "y" ];then
{
cat >> /etc/hosts <<END

# for yum update
192.168.99.91   mirrors.jobkoo.com

# jobkoo time server
192.168.99.91   time.jobkoo.com

# for nfs
192.168.99.91   opt001
END
}
fi

cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
read KEY
}

# Num.4
ConfigSnmpd()
{
    cecho "��������snmpd����..." $boldmagenta NOLF
    sleep 1
    chkconfig snmpd on
    [ -e /etc/snmp/snmpd.conf ] && mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.`date +%Y%m%d`
    cp ./conf/snmpd.conf /etc/snmp/
    service snmpd restart
    
    cecho "Please Enter to Return,Ctrl+C Exit..." $boldgreen NOLF
    read KEY
}

# Num.8
DELLOMSA()
{
wget -q -O - http://linux.dell.com/repo/hardware/latest/bootstrap.cgi | bash

yum install srvadmin-all -y

cecho "ΪOMSA���ÿ�������..." $boldmagenta NOLF
/opt/dell/srvadmin/sbin/srvadmin-services.sh enable
cecho "����OMSA..." $boldmagenta NOLF
/opt/dell/srvadmin/sbin/srvadmin-services.sh start
}

# ��ʾ ���˵�
SHOWMAIN()
{
clear
echo "+--------------------------+"
cecho "|  1.Disable services      |" $boldwhite
echo "+--------------------------+"
cecho "|  2.check service status  |" $boldwhite
echo "+--------------------------+"
cecho "|  3.clear firewall rule   |" $boldwhite
echo "+--------------------------+"
cecho "|  4.Configure yum         |" $boldwhite
echo "+--------------------------+"
cecho "|  5.Configure snmp        |" $boldwhite
echo "+--------------------------+"
cecho "|  6.yum update rpms       |" $boldwhite
echo "+--------------------------+"
cecho "|  7.other configure       |" $boldwhite
echo "+--------------------------+"
cecho "|  8.Install Dell OMSA     |" $boldwhite
echo "+--------------------------+"
cecho "|    Select number to run  |" $boldwhite
cecho "|       Ctrl+C Abort       |" $boldred
echo "+--------------------------+"
cecho "Please Select number(1-8):" $boldgreen NOLF
read SELECT
	case "$SELECT" in
	"1")
		SETUPSERVICE
	;;
	"2")
		CHECKSTATUS
	;;
	"3")
		CONFIGUREFIREWALL
	;;
        "4")
		ConfigYum
        ;;
	"5")
        	ConfigSnmpd
	;;
	"6")
		UPDATEYUM
	;;
	"7")
		OTHERCONFIGURE
	;;
	"8")
		DELLOMSA
	;;
	*)
	cecho "Please input number (1~7)" $boldgreen LF
	;;
	esac
}

clear

# ��ʼ������
Init

# ��ʾ�˵� 
while [ 1 ]
do
SHOWMAIN
done
