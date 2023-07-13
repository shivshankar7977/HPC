## Steps for the doing the nfs configuration on centos machine 
Requirement for doing the nfs configuration 

* VM-1 &nbsp; ---  master
* VM-2 &nbsp; --- client1
* VM-3 &nbsp; --- client2

```bash
VM 1 : NAT - 192.168.30.186
       Host- 192.168.45.151

VM 2 : NAT - 192.168.30.185
       Host- 192.168.45.152

VM 3 : NAT - 192.168.30.182
       Host- 192.168.45.153
```

All machines firewall and selinux should be off 

```bash
systemctl status firewalld.service
systemctl stop firewalld.service
systemctl disable firewalld.service
```
For  the disable Selinux.
```bash
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce

```
For the do the Passwordless ssh with host only ip address.
```bash
ssh-keygen
ssh-copy-id root@192.168.45.152
ssh-copy-id root@192.168.45.153
```
Now we try to take ssh of the client on the master machine

```bash
ssh root@192.168.45.152
ssh root@192.168.45.153
```
Now install the nfs-utis
```bash
yum install -y nfs-utils
```
Now start the nfs
```bash
systemctl start nfs-server rpcbind
systemctl enable nfs-server rpcbind
```
Then change the permission 
```bash
chmod 777 /home/
```
Now edit the vi /etc/exports file 

```bash
vim /etc/exports

/home 192.168.45.152(rw,sync,no_root_squash)
/home 192.168.45.153(rw,sync,no_root_squash)
```
now run the command 

```bash
exportfs -r
```


```bash
showmount -e
```
To show the Free space left on a file system.
```bash
df -Th
```

On client1 machine :

```bash
yum install -y nfs-utils
showmount -e 192.168.45.151
mount -t nfs 192.168.45.151:/home /home
df -hT
```

On client2 machine :

```bash
yum install -y nfs-utils
showmount -e 192.168.45.151
mount -t nfs 192.168.45.151:/home /home
df -hT
```
Edit the host files on master machine 

``` bash
vim /etc/hosts
192.168.45.151 master
192.168.45.152 client1
192.168.45.153 client2
```
Copy this edited hosts files from the master to the all clients using the rsync command.
```bash
rsync /etc/hosts root@192.168.45.152:/etc/hosts
rsync /etc/hosts root@192.168.45.153:/etc/hosts
```
Install the epel-release package
```bash
yum install epel-release
```
Install the Package for the munge service.
```bash
yum install munge munge-libs munge-devel
```
For list the munge key
```bash
ll /etc/munge
```
For checking the all packeges of munge
```bash
rpm -qa | grep munge
```
To generate the munge-key
```bash
/usr/sbin/create-munge-key -r
```
Munge key genarate in this directory
```bash
ll /etc/munge
```
To check the logs of the munge file
```bash 
ll /var/log/munge
```
Copy the munge key from master to both the clients

```bash
scp /etc/munge/munge.key client1:/etc/munge/
scp /etc/munge/munge.key client2:/etc/munge/
```

On Both client machine run the command for change the permission 
```bash
chown munge:munge /etc/munge/munge.key
```
Start the munge service on the all VMs 

```bash
systemctl status munge
systemctl start munge
systemctl enable munge
```
![Version Of Slurm](images/tar.PNG)
Download the tar file 
```bash
wget https://download.schedmd.com/slurm/slurm-20.11.9.tar.bz2
```
Install the Rpm build

```bash
yum install rpm-build
```
Install the packages pam-devel python3 readline-devel perl-ExtUtils-MakeMaker 

```bash
yum install pam-devel python3 readline-devel perl-ExtUtils-MakeMaker -y
yum install gcc
yum install mysql-devel -y
```
Now build the package using rpm build
```bash
rpmbuild -ta slurm-20.11.9.tar.bz2
```

On the both client machine install all packeges:
```bash
yum install pam-devel python3 readline-devel perl-ExtUtils-MakeMaker gcc mysql-devel -y
```
On all VMs :
```bash
export SLURMUSER=900 
```
Add the group
```bash
groupadd -g $SLURMUSER slurm
```

Now Useradd 

* -m modify
* -c comment
* -d directory
* -u user
* -g group 
* -s shell
```bash
useradd -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm -s /bin/bash slurm
```
On Master machine:

```bash
ls /root/rpmbuild/RPMS/x86_64/
mkdir /home/rpms
cd /root/rpmbuild/RPMS/x86_64/
ls
cp * /home/rpms/
cd /home/rpms/
ls
yum --nogpgcheck localinstall * -y
rpm -qa | grep slurm | wc -l
```
On client Machine 
```bash
cd /home/rpms/
ls
rm -rf slurm-slurmctld-20.11.9-1.el7.x86_64.rpm
rm -rf slurm-slurmdbd-20.11.9-1.el7.x86_64.rpm
yum --nogpgcheck localinstall * -y
rpm -qa | grep slurm | wc -l
```

On All VMs:
```bash
mkdir /var/spool/slurm
ll /var/spool/
chown slurm:slurm /var/spool/slurm/
chmod 755 /var/spool/slurm/
mkdir /var/log/slurm
chown -R slurm . /var/log/slurm/
```

On Master : 
```bash 
touch /var/log/slurm/slurmctld.log
chown slurm:slurm /var/log/slurm/slurmctld.log
touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
cp /etc/slurm/slurm.conf.example /etc/slurm/slurm.conf
slurmd -C         ------- to check configuration
```

```bash
vim /etc/slurm/slurm.conf

# See the slurm.conf man page for more information.
#
ClusterName=linux
ControlMachine=linux0

Replace above with following.

# See the slurm.conf man page for more information.
#
ClusterName=hpcsa              ---name for cluster.
ControlMachine=master          ---Hostname




# COMPUTE NODES
NodeName=linux[1-32] Procs=1 State=UNKNOWN
PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP



#COMPUTE NODES
#NodeName=linux[1-32] Procs=1 State=UNKNOWN
NodeName=client1 CPUs=4 Boards=1 SocketsPerBoard=4 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=3770 State=UNKNOWN
NodeName=client2 CPUs=4 Boards=1 SocketsPerBoard=4 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=3770
PartitionName=standard Nodes=ALL Default=YES MaxTime=INFINITE State=UP
```
Then Copy the edited file to the client using SCP command
```bash
scp /etc/slurm/slurm.conf client1:/etc/slurm/
scp /etc/slurm/slurm.conf client2:/etc/slurm/
systemctl start slurmctld.service
systemctl enable slurmctld.service
systemctl status slurmctld.service 
```

On Both the client machine:
```bash
systemctl start slurmd.service
systemctl enable slurmd.service
systemctl status slurmd.service
```
To check job ruuning 
```bash
sinfo
```