# **Lab2: working with RAID**

## **Modify Vagrantfile** 

Add to vagrant file new sata disks

```
disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 250,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250, # Megabytes
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 250, # Megabytes
                        :port => 4
                },
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 250, # Megabytes
                        :port => 5
                },

```

Then connect to our vm:

```
vagrant ssh
```
and check our disks:
```
vagrant@otuslinux ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0  250M  0 disk 
```

## **Build Raid 5** 
Build our test RAID5

```
# sudo mdadm --create --verbose /dev/md0 --level=5  --raid-devices=5 /dev/sd[bcdef]

```

Let's check our raid 

```
# cat /proc/mdstat 
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
      
# sudo  mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sat May 28 13:44:51 2022
        Raid Level : raid5
        Array Size : 1015808 (992.00 MiB 1040.19 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Sat May 28 13:44:55 2022
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 08ebe0e9:15c97cf0:6bca38da:2bfd6b05
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf
      
```

## **Testing raid**

Now we test our raid for fail and repair functions.
Lets fail sdd:

```
# sudo su
# mdadm /dev/md0 --fail /dev/sdd
# mdadm: set /dev/sdd faulty in /dev/md0
# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2](F) sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UU_UU]
      
unused devices: <none>
sudo  mdadm -D /dev/md0
  Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf

       2       8       48        -      faulty   /dev/sdd


```
Let's deleting failty device and add it again:

```
# mdadm /dev/md0 --remove /dev/sdd

Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf

# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UU_UU]
      
# mdadm /dev/md0 --add /dev/sdd

# mdadm: added /dev/sdd

# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdd[6] sdf[5] sde[3] sdc[1] sdb[0]
      1015808 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]


```


## **Make mdadm.config**

Check raid devices: 

```
#  mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=08ebe0e9:15c97cf0:6bca38da:2bfd6b05
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf

```
Make mdadm.conf

```
# sudo su
# mkdir /etc/mdadm
#  echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```
Reboot VM and chek that raid is available

```
# reboot
# vagrant ssh

[root@otuslinux vagrant]# mdadm -D /dev/md0 
/dev/md0:
           Version : 1.2
     Creation Time : Sat May 28 13:44:51 2022
        Raid Level : raid5
        Array Size : 1015808 (992.00 MiB 1040.19 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Sat May 28 14:00:41 2022
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 08ebe0e9:15c97cf0:6bca38da:2bfd6b05
            Events : 40

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       6       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf


```


## **Build GPT and partition**

```
# parted -s /dev/md0 mklabel gpt
# parted /dev/md0 mkpart primary ext4 0% 20%
# parted /dev/md0 mkpart primary ext4 20% 40%
# parted /dev/md0 mkpart primary ext4 40% 60%
# parted /dev/md0 mkpart primary ext4 60% 80%
# parted /dev/md0 mkpart primary ext4 80% 100%
```
Create fs
```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```

Mount our partitions: 

```
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```

## **Change Vagrantfile**

```
box.vm.provision "shell", inline: <<-SHELL
	      mkdir -p ~root/.ssh
              cp ~vagrant/.ssh/auth* ~root/.ssh
	      yum install -y mdadm smartmontools hdparm gdisk
          mdadm --create --verbose /dev/md0 --level=5  --raid-devices=5 /dev/sd[bcdef]
          mkdir /etc/mdadm
          echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
          mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
          parted -s /dev/md0 mklabel gpt
          parted /dev/md0 mkpart primary ext4 0% 20%
          parted /dev/md0 mkpart primary ext4 20% 40%
          parted /dev/md0 mkpart primary ext4 40% 60%                                   
          parted /dev/md0 mkpart primary ext4 60% 80%
          parted /dev/md0 mkpart primary ext4 80% 100%
          for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
          mkdir -p /raid/part{1,2,3,4,5}
          for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done

```












