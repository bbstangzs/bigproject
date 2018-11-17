#!/bin/bash

##--系统配置文件模板，请勿修改，相关配置内容将会由以下内容导出生成--##
#<domain type='kvm'>
#  <name>node</name>
#  <memory unit='KB'>2097152</memory>
#  <currentMemory unit='KB'>2097152</currentMemory>
#  <vcpu placement='static'>2</vcpu>
#  <os>
#    <type arch='x86_64' machine='pc'>hvm</type>
#    <boot dev='hd'/>
#    <bootmenu enable='yes'/>
#    <bios useserial='yes'/>
#  </os>
#  <features>
#    <acpi/>
#    <apic/>
#  </features>
#  <cpu mode='host-passthrough'>
#  </cpu>
#  <clock offset='localtime'/>
#  <on_poweroff>destroy</on_poweroff>
#  <on_reboot>restart</on_reboot>
#  <on_crash>restart</on_crash>
#  <devices>
#    <emulator>/usr/libexec/qemu-kvm</emulator>
#    <disk type='file' device='disk'>
#      <driver name='qemu' type='qcow2'/>
#      <source file='/var/lib/libvirt/images/node.img'/>
#      <target dev='vda' bus='virtio'/>
#    </disk>
#    <interface type='bridge'>
#      <source bridge='vbr'/>
#      <model type='virtio'/>
#    </interface>
#    <channel type='unix'>
#      <target type='virtio' name='org.qemu.guest_agent.0'/>
#    </channel>
#    <serial type='pty'></serial>
#    <console type='pty'>
#      <target type='serial'/>
#    </console>
#    <memballoon model='virtio'></memballoon>
#  </devices>
#</domain>

##--虚拟交换机配置文件模板，请勿修改，配置内容将会由以下内容导出生成--##
#<network>
#  <name>vbr</name>
#  <forward mode='nat'/>
#  <bridge name='vbr' stp='on' delay='0'/>
#  <domain name='vbr'/>
#  <ip address='192.168.1.254' netmask='255.255.255.0'>
#    <dhcp>
#      <range start='192.168.1.100' end='192.168.1.200'/>
#    </dhcp>
#  </ip>
#</network>


vm_dir=/etc/libvirt/qemu/
im_dir=/var/lib/libvirt/images/
mem=`free -g | awk 'NR==2{print $2}'`
cpu=`lscpu | awk 'NR==4{print $2}'`

####确定主机相关信息：1、主机名 2、主机磁盘 3、主机内存 4、主机核心数 5、ip地址
while :
do
	read -p '请输入你想创建的主机名：' name
	if [ -z $name ];then
		continue
	elif [ -f ${vm_dir}${name}.xml ];then
		echo "${name}主机已存在!"
	else
		break
	fi
done
while :
do
	read -p "主机的硬盘大小(请输入50到1000,单位G):(默认50G)" size
	size=${size:-50}
	if [ $size -lt 50 ]||[ $size -gt 1000 ];then
		echo "硬盘尺寸错误，请重新输入!"
	else
		break
	fi
done
while :
do
	read -p "主机的内存大小(请输入1到${mem},单位G):(默认4G)" vmem
	vmem=${vmem:-4}
	if [ $vmem -le 0 ];then
		echo "内存错误,请重新输入!"
	elif [ $vmem -ge $mem ];then
		echo "内存超出物理机真实内存,请重新输入!"
	else
		break
	fi
done
while :
do
	read -p "主机CPU个数(物理机CPU个数为${cpu}):(默认2个)" vcpu
	vcpu=${vcpu:-2}
	if [ $vcpu -le 0 ]||[ $vcpu -ge $cpu ];then
		echo "CPU个数超过限制，请重新输入!"
	else
		break
	fi
done

echo "请输入虚拟机的ip地址(会自动创建该网段的虚拟交换机)"
read -p "默认为dhcp自动分配（默认网段为192.168.1.0/24）:" ipad

#检测输入的ip地址是否合法
while :
do
	ipad=${ipad:-192.168.1.1}
	ipad1=`echo "${ipad}" | awk -F'.' '{print $1}'`
	ipad2=`echo "${ipad}" | awk -F'.' '{print $2}'`
	ipad3=`echo "${ipad}" | awk -F'.' '{print $3}'`
	ipad4=`echo "${ipad}" | awk -F'.' '{print $4}'`
	ipad11=`echo ${ipad1:-300}`
	ipad22=`echo ${ipad2:-300}`
	ipad33=`echo ${ipad3:-300}`
	ipad44=`echo ${ipad4:-300}`
	if [ $ipad11 -gt 0 ]&&[ $ipad11 -lt 255 ]&&[ $ipad22 -ge 0 ]&&[ $ipad22 -le 255 ]&&[ $ipad33 -ge 0 ]&&[ $ipad33 -le 255 ]&&[ $ipad44 -gt 0 ]&&[ $ipad44 -lt 255 ];then
		break
	else
		read -p "ip地址非法，请重新输入：" ipad
	fi
done




netfile=${vm_dir}networks/${name}.xml
#生成虚拟交换机配置文件
bsw(){
        sed -n "48,58p" $1 > $netfile
        sed -i "s/#//" $netfile
        sed -i "s/vbr/${name}/" $netfile
}
#启动虚拟交换机
ssw(){
        virsh net-define $netfile
        virsh net-start $name
        virsh net-autostart $name
}
#关闭已存在的同网段虚拟交换机
stsw(){
        bdg=`ip a s | grep $1 | awk '{print $NF}'`
        virsh net-destroy $bdg &> /dev/null
        virsh net-autostart --disable $bdg &> /dev/null
}

#创建并启动虚拟交换机 
if [ -z $ipad ]&&[ -f $netfile ];then
	ssw
elif [ -z $ipad ]&&[ ! -f $netfile];then
	bsw $0
	stsw 192.168.1.254
	ssw
elif [ -n $ipad ]&&[ ! -f $netfile ];then
	ipnet=${ipad%.*}
	stsw ${ipnet}\\.
	bsw $0
	sed -i "s/192.168.1.254/${ipnet}.254/" $netfile
	sed -i "7,9d" $netfile
	ssw
else
        ipnet=${ipad%.*}
	stsw ${ipnet}\\.
	sed -i "s/192.168.1.254/${ipnet}.254/" $netfile
	sed -i "7,9d" $netfile
	ssw
fi


######开始创建虚拟机
echo "开始创建虚拟机，请耐心等待..."

#生成初始配置文件
vmfile=${vm_dir}${name}.xml
sed -n '4,45p' $0 > $vmfile
sed -i 's/#//' $vmfile


#创建前端盘镜像文件
qemu-img create -b ${im_dir}zhangsi.qcow2 -f qcow2 ${im_dir}${name}.img ${size}G &>/dev/null

#指定镜像文件与主机名
sed -i "s/node/${name}/" $vmfile

#修改内存大小
kmem=$[vmem*1024*1024]
sed -i "s/2097152/${kmem}/" $vmfile

#修改CPU个数
sed -i "5s/2/${vcpu}/" $vmfile

#修改网卡接口
sed -i "s/vbr/${name}/" $vmfile

#修改虚拟机ip地址
guestmount -a ${im_dir}${name}.img -i /mnt
echo "DEVICE=\"eth0\"
NAME=\"eth0\"
ONBOOT=yes
BOOTPROTO=static
TYPE=Ethernet
IPADDR=\"${ipad}\"
NETMASK=\"255.255.255.0\"
GATEWAY=\"${ipnet}.254\"">/mnt/etc/sysconfig/network-scripts/ifcfg-eth0
umount /mnt

#定义虚拟机
virsh define $vmfile

read -p "虚拟机创建成功，是否启动？(默认不启动)(y/N)" boot
boot=${boot:-N}
if [ $boot == y ];then
	virsh start $name
fi











			
			
