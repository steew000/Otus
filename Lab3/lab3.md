# **Lab3: LVM**

## **1.Resize / to 8G** 

Check our block devices and file type

```
lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde


root@lvm dev]# df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs        38G  826M   37G   3% /
devtmpfs                        devtmpfs  109M     0  109M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   63M  952M   7% /boot
tmpfs                           tmpfs      24M     0   24M   0% /run/user/1000
tmpfs                           tmpfs      24M     0   24M   0% /run/user/0
         
```

There we have xfs partition on LVM. So we cant easy resize root partition. let's install xfsdump

```
yum install lvm2 xfsdump
```

Then prepare temp partition

```
[root@lvm dev]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

[root@lvm dev]# vgcreate vg_tmp_root /dev/sdb
  Volume group "vg_tmp_root" successfully created

[root@lvm dev]# lvcreate -n lv_tmp_root -l +80%FREE /dev/vg_tmp_root
  Logical volume "lv_tmp_root" created.

mkfs.xfs /dev/vg_tmp_root/lv_tmp_root
meta-data=/dev/vg_tmp_root/lv_tmp_root isize=512    agcount=4, agsize=524032 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2096128, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm dev]# mount /dev/vg_tmp_root/lv_tmp_root /mnt

```

Make dump of our xfs to new dirrectory

```
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
Entering in chroot

```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

chroot /mnt/
```
Make new grub

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```
Refresh load image

```
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```

Change groob from lv=VolGroup00/LogVol00 to lv=vg_tmp_root/lv_tmp_root
```
nano /boot/grub2/grub.cfg
```
Then reload our vm: 
```
exit
shutdown -r now
```

We load from temp lv after reboot: 

```
[vagrant@lvm ~]$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    1G  0 part /boot
└─sda3                      8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00   253:2    0 37.5G  0 lvm  
sdb                         8:16   0   10G  0 disk 
└─vg_tmp_root-lv_tmp_root 253:0    0    8G  0 lvm  /
sdc                         8:32   0    2G  0 disk 
sdd                         8:48   0    1G  0 disk 
sde                         8:64   0    1G  0 disk  
```

Now root partition on sdb temp lvm. 
Delet old lvm: 

```
[vagrant@lvm ~]$ sudo lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```
Create new lvm with 8G size: 
```
[root@lvm vagrant]# lvcreate -n LogVol00 -L 8G VolGroup00 
  Logical volume "LogVol00" created.
```
Create file system: 
```
root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```
Mount our fs to temp dirretory: 
```
mount /dev/VolGroup00/LogVol00 /mnt
```
Make dump to LogVol00

```
xfsdump -J - /dev/vg_tmp_root/lv_tmp_root | xfsrestore -J - /mnt
```

Entering in chroot

```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
```
Create new Grub
```
grub2-mkconfig -o /boot/grub2/grub.cfg
```
Refresh load image
```
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```

Change grub from lv=vg_tmp_root/lv_tmp_root to lv=VolGroup00/LogVol00 

```
nano /boot/grub2/grub.cfg
```

Exit chroot and reboot 
```
exit

shutdown -r now
```

Check root dirrectory
```
root@lvm vagrant]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   40G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    1G  0 part /boot
└─sda3                      8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00   253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01   253:1    0  1.5G  0 lvm  [SWAP]
sdb                         8:16   0   10G  0 disk 
└─vg_tmp_root-lv_tmp_root 253:2    0    8G  0 lvm  
sdc                         8:32   0    2G  0 disk 
sdd                         8:48   0    1G  0 disk 
sde                         8:64   0    1G  0 disk 
```

Now we can delete temp lvm
```
[root@lvm vagrant]# lvremove /dev/vg_tmp_root/lv_tmp_root 
Do you really want to remove active logical volume vg_tmp_root/lv_tmp_root? [y/n]: y
  Logical volume "lv_tmp_root" successfully removed
[root@lvm vagrant]# vgremove vg_tmp_root 
  Volume group "vg_tmp_root" successfully removed
[root@lvm vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.

```
Check block devices

```
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```



## **2.Make partition for /home** 

Lets make another lvm for home

```
[root@lvm vagrant]# lvcreate -L 10G -n lv_home VolGroup00 
  Logical volume "lv_home" created.

```
let's make btrfs fs on it

```
[root@lvm vagrant]# mkfs.btrfs /dev/VolGroup00/lv_home 
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               3ffba22e-d108-4fe0-9d5d-18eeb96748f9
Node size:          16384
Sector size:        4096
Filesystem size:    10.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP               1.00GiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    10.00GiB  /dev/VolGroup00/lv_home

```

Sync home dirrectory to temp home

```
cd /var
mkdir ./home0
rsync -a --progress /home/ /var/home0
```
Mount it to /home
```
[root@lvm vagrant]# mount /dev/VolGroup00/lv_home /home

root@lvm home]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-lv_home  253:2    0   10G  0 lvm  /home
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 

```




## **3.Make mirror (RAID 1)partition for /var** 

1. Make raid1

Clean superblocks

```
[root@lvm home]# mdadm --zero-superblock --force /dev/sd{de}
mdadm: Couldn't open /dev/sd{de} for write - not zeroing

```
Clean metadata

```
wipefs --all --force /dev/sd{d,e}
```
Make raid
```
mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/sdd /dev/sde
```
Make config file
```
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```
 
2.Make fs:

```
mkfs.ext4 /dev/md0

```
3.Sync var dirrectory to temp dir

```
cd /home
mkdir ./var0
rsync -a --progress /var/ /home/var0
```
4.Mount new /var and sync it back then remove temp dir
```
mount /dev/md0 /var
rsync -a --progress /home/var0/ /var
rm -r /home/var0
```

5.Check mounted dir's

```
[root@lvm home]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda                       8:0    0   40G  0 disk  
├─sda1                    8:1    0    1M  0 part  
├─sda2                    8:2    0    1G  0 part  /boot
└─sda3                    8:3    0   39G  0 part  
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm   /
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm   [SWAP]
  └─VolGroup00-lv_home  253:2    0   10G  0 lvm   /home
sdb                       8:16   0   10G  0 disk  
sdc                       8:32   0    2G  0 disk  
sdd                       8:48   0    1G  0 disk  
└─md0                     9:0    0 1022M  0 raid1 /var
sde                       8:64   0    1G  0 disk  
└─md0                     9:0    0 1022M  0 raid1 /var
```


## **4.Make snap LVM for /home** 

```

[root@lvm home]# lvs
  LV       VG         Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao----  8.00g                                                    
  LogVol01 VolGroup00 -wi-ao----  1.50g                                                    
  lv_home  VolGroup00 -wi-ao---- 10.00g    

[root@lvm home]# lvcreate --size 5G --snapshot --name home_snap /dev/VolGroup00/lv_home
  Logical volume "home_snap" created.

[root@lvm home]# lvs
  LV        VG         Attr       LSize  Pool Origin  Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00  VolGroup00 -wi-ao----  8.00g                                                     
  LogVol01  VolGroup00 -wi-ao----  1.50g                                                     
  home_snap VolGroup00 swi-a-s---  5.00g      lv_home 0.00                                   
  lv_home   VolGroup00 owi-aos--- 10.00g         

```
## **5.Change fstab for mounted devices**

At first we must copy devices UUID

``` 
blkid

/dev/mapper/VolGroup00-LogVol00: UUID="6b6e38d6-2807-48c7-84bd-c2ff8eb2d45b" TYPE="xfs" 

....
/dev/md0: UUID="ee8e011b-fd78-4eb3-8500-f52daef41b3c" TYPE="ext4"
....
/dev/mapper/VolGroup00-lv_home: UUID="3ffba22e-d108-4fe0-9d5d-18eeb96748f9" UUID_SUB="8e70ba23-a655-48bd-ad16-ae3cfcde6fb6" TYPE="btrfs"
....
/dev/mapper/VolGroup00-LogVol01: UUID="c39c5bed-f37c-4263-bee8-aeb6a6659d7b" TYPE="swap" 
```

Backip fstab before editing

```
cp /etc/fstab /etc/fstab_b

```

Then edit fstab: 

```
nano /etc/fstab

UUID=6b6e38d6-2807-48c7-84bd-c2ff8eb2d45b /                       xfs     defaults        0 1
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
UUID=c39c5bed-f37c-4263-bee8-aeb6a6659d7b swap                    swap    defaults        0 0
UUID=ee8e011b-fd78-4eb3-8500-f52daef41b3c /var ext4 rw,auto,relatime,data=ordered 0 0
UUID=3ffba22e-d108-4fe0-9d5d-18eeb96748f9 /home btrfs defaults 0 0

```

Reload machine and check mounted devices

```

```


