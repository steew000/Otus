# **Lab4: ZFS**

## **1.Define best compression algorithm**

Cheking our blocks devises

```
lsblk 

NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   64G  0 disk
|-sda1   8:1    0  2.1G  0 part [SWAP]
`-sda2   8:2    0 61.9G  0 part /
sdb      8:16   0    1G  0 disk
sdc      8:32   0    1G  0 disk
sdd      8:48   0    1G  0 disk
sde      8:64   0    1G  0 disk
sdf      8:80   0    1G  0 disk
sdg      8:96   0    1G  0 disk

         
```
Let's create some mirrors zfs pools :


```
sudo su
zpool create mir1 mirror sdb sdc
zpool create mir2 mirror sdd sde
zpool create mir3 mirror sdf sdg

[root@server vagrant]# zpool status
  pool: mir1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        mir1        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: mir2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        mir2        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: mir3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        mir3        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

[root@server vagrant]# zpool list
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
mir1   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -
mir2   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -
mir3   960M   105K   960M        -         -     0%     0%  1.00x    ONLINE  -

```

Let's check mount point and create more datasets for zle and gzip cpmpression type:

```
[root@server vagrant]# mount -t zfs
mir1 on /mir1 type zfs (rw,seclabel,xattr,noacl)
mir2 on /mir2 type zfs (rw,seclabel,xattr,noacl)
mir3 on /mir3 type zfs (rw,seclabel,xattr,noacl)
[root@server vagrant]# zfs create mir3/gzip1
[root@server vagrant]# zfs create mir3/gzip2
[root@server vagrant]# zfs create mir3/gzip3
[root@server vagrant]# zfs create mir3/gzip4
[root@server vagrant]# zfs create mir3/gzip5
[root@server vagrant]# zfs create mir3/gzip6
[root@server vagrant]# zfs create mir3/gzip7
[root@server vagrant]# zfs create mir3/gzip8
[root@server vagrant]# zfs create mir3/gzip9
[root@server vagrant]# zfs create mir3/zle

```

Set compression type:

```
[root@server vagrant]# zfs set compression=lzjb mir1
[root@server vagrant]# zfs set compression=lz4 mir2
[root@server vagrant]# zfs set compression=zle mir3/zle
for i in {1..9}; do  zfs set compression=gzip-$i mir3/gzip$i; done
[root@server vagrant]#

```

Checking compression type

```
[root@server vagrant]# zfs get all | grep compression
mir1        compression           lzjb                   local
mir2        compression           lz4                    local
mir3        compression           off                    default
mir3/gzip1  compression           gzip-1                 local
mir3/gzip2  compression           gzip-2                 local
mir3/gzip3  compression           gzip-3                 local
mir3/gzip4  compression           gzip-4                 local
mir3/gzip5  compression           gzip-5                 local
mir3/gzip6  compression           gzip                   local
mir3/gzip7  compression           gzip-7                 local
mir3/gzip8  compression           gzip-8                 local
mir3/gzip9  compression           gzip-9                 local
mir3/zle    compression           zle                    local


```

Download test file

```
[root@server vagrant]# wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8
--2022-08-22 06:42:16--  http://www.gutenberg.org/ebooks/2600.txt.utf-8
Resolving www.gutenberg.org (www.gutenberg.org)... 152.19.134.47
Connecting to www.gutenberg.org (www.gutenberg.org)|152.19.134.47|:80... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://www.gutenberg.org/ebooks/2600.txt.utf-8 [following]
--2022-08-22 06:42:17--  https://www.gutenberg.org/ebooks/2600.txt.utf-8
Connecting to www.gutenberg.org (www.gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://www.gutenberg.org/cache/epub/2600/pg2600.txt [following]
--2022-08-22 06:42:18--  https://www.gutenberg.org/cache/epub/2600/pg2600.txt
Reusing existing connection to www.gutenberg.org:443.
HTTP request sent, awaiting response... 200 OK
Length: 3359372 (3.2M) [text/plain]
Saving to: 'War_and_Peace.txt'

War_and_Peace.txt     100%[=========================>]   3.20M  2.34MB/s    in 1.4s

2022-08-22 06:42:19 (2.34 MB/s) - 'War_and_Peace.txt' saved [3359372/3359372]

```

Fill our pools with test file:

```
[root@server vagrant]# cp War_and_Peace.txt /mir1/
[root@server vagrant]# cp War_and_Peace.txt /mir2/
[root@server vagrant]# cp War_and_Peace.txt /mir3/zle/
[root@server vagrant]# for i in {1..9}; do cp War_and_Peace.txt /mir3/gzip$i/; done
```

Checking some datasets for file presence:

```
[root@server vagrant]# ls -lah /mir1/
total 2.4M
drwxr-xr-x.  2 root root    3 Aug 22 06:48 .
dr-xr-xr-x. 21 root root  275 Aug 22 06:17 ..
-rw-r--r--.  1 root root 3.3M Aug 22 06:48 War_and_Peace.txt
[root@server vagrant]# ls -lah /mir2/
total 2.0M
drwxr-xr-x.  2 root root    3 Aug 22 06:48 .
dr-xr-xr-x. 21 root root  275 Aug 22 06:17 ..
-rw-r--r--.  1 root root 3.3M Aug 22 06:48 War_and_Peace.txt
[root@server vagrant]# ls -lah /mir3/gzip1
total 1.5M
drwxr-xr-x.  2 root root    3 Aug 22 06:50 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 3.3M Aug 22 06:50 War_and_Peace.txt
[root@server vagrant]# ls -lah /mir3/gzip6
total 1.3M
drwxr-xr-x.  2 root root    3 Aug 22 06:50 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 3.3M Aug 22 06:50 War_and_Peace.txt

```


Let's check used size in our pools:
```
[root@server vagrant]# zfs list
NAME         USED  AVAIL     REFER  MOUNTPOINT
mir1        2.51M   829M     2.41M  /mir1
mir2        2.12M   830M     2.02M  /mir2
mir3        15.1M   817M       35K  /mir3
mir3/gzip1  1.44M   817M     1.44M  /mir3/gzip1
mir3/gzip2  1.39M   817M     1.39M  /mir3/gzip2
mir3/gzip3  1.34M   817M     1.34M  /mir3/gzip3
mir3/gzip4  1.30M   817M     1.30M  /mir3/gzip4
mir3/gzip5  1.26M   817M     1.26M  /mir3/gzip5
mir3/gzip6  1.24M   817M     1.24M  /mir3/gzip6
mir3/gzip7  1.23M   817M     1.23M  /mir3/gzip7
mir3/gzip8  1.23M   817M     1.23M  /mir3/gzip8
mir3/gzip9  1.23M   817M     1.23M  /mir3/gzip9
mir3/zle    3.23M   817M     3.23M  /mir3/zle
```

Check compression:

```
[root@server vagrant]# zfs get all | grep compressratio | grep -v ref
mir1        compressratio         1.35x                  -
mir2        compressratio         1.61x                  -
mir3        compressratio         2.20x                  -
mir3/gzip1  compressratio         2.28x                  -
mir3/gzip2  compressratio         2.37x                  -
mir3/gzip3  compressratio         2.47x                  -
mir3/gzip4  compressratio         2.54x                  -
mir3/gzip5  compressratio         2.62x                  -
mir3/gzip6  compressratio         2.67x                  -
mir3/gzip7  compressratio         2.67x                  -
mir3/gzip8  compressratio         2.67x                  -
mir3/gzip9  compressratio         2.67x                  -
mir3/zle    compressratio         1.01x                  -

```

So gzip from 6  to 9 is have the best compression value. Let's check gzip with more weight file:


```
[root@server vagrant]# wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso
--2022-08-22 08:19:56--  https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso
Resolving cdimage.debian.org (cdimage.debian.org)... 194.71.11.173, 194.71.11.163, 194.71.11.165
Connecting to cdimage.debian.org (cdimage.debian.org)|194.71.11.173|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://laotzu.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso [following]
--2022-08-22 08:19:57--  https://laotzu.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso
Resolving laotzu.ftp.acc.umu.se (laotzu.ftp.acc.umu.se)... 194.71.11.166
Connecting to laotzu.ftp.acc.umu.se (laotzu.ftp.acc.umu.se)|194.71.11.166|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 397410304 (379M) [application/x-iso9660-image]
Saving to: 'debian-11.4.0-amd64-netinst.iso'

debian-11.4.0-amd64-n 100%[=========================>] 379.00M  3.94MB/s    in 53s

2022-08-22 08:20:50 (7.15 MB/s) - 'debian-11.4.0-amd64-netinst.iso' saved [397410304/397410304]

[root@server vagrant]# ls -alh
total 383M
drwx------. 3 vagrant vagrant  159 Aug 22 08:19 .
drwxr-xr-x. 3 root    root      21 Dec 19  2021 ..
-rw-r--r--. 1 vagrant vagrant   18 Jul 27  2021 .bash_logout
-rw-r--r--. 1 vagrant vagrant  141 Jul 27  2021 .bash_profile
-rw-r--r--. 1 vagrant vagrant  376 Jul 27  2021 .bashrc
drwx------. 2 vagrant root      29 Aug 22 05:56 .ssh
-rw-r--r--. 1 vagrant vagrant    6 Dec 19  2021 .vbox_version
-rw-r--r--. 1 root    root    3.3M Aug  2 08:36 War_and_Peace.txt
-rw-r--r--. 1 root    root    379M Jul  9 11:55 debian-11.4.0-amd64-netinst.iso

```

Let's copied it to gzip6-9 and checked size and compression:

```
cp debian-11.4.0-amd64-netinst.iso /mir3/gzip6/
cp debian-11.4.0-amd64-netinst.iso /mir3/gzip7/
cp debian-11.4.0-amd64-netinst.iso /mir3/gzip8/
cp debian-11.4.0-amd64-netinst.iso /mir3/gzip9/
[root@server vagrant]# zfs list
NAME         USED  AVAIL     REFER  MOUNTPOINT

mir3/gzip6   370M   458M      370M  /mir3/gzip6
mir3/gzip7   370M  87.7M      370M  /mir3/gzip7
mir3/gzip8   370M  87.7M      370M  /mir3/gzip8
mir3/gzip9   370M  87.7M      370M  /mir3/gzip9

zfs get all | grep compressratio | grep -v ref
mir3/gzip6  compressratio         1.02x                  -
mir3/gzip7  compressratio         1.02x                  -
mir3/gzip8  compressratio         1.02x                  -
mir3/gzip9  compressratio         1.02x                  -

[root@server vagrant]# ls -lah /mir3/gzip6
total 371M
drwxr-xr-x.  2 root root    3 Aug 22 09:24 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 379M Aug 22 09:26 debian-11.4.0-amd64-netinst.iso
[root@server vagrant]# ls -lah /mir3/gzip7
total 371M
drwxr-xr-x.  2 root root    3 Aug 22 09:27 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 379M Aug 22 09:30 debian-11.4.0-amd64-netinst.iso
[root@server vagrant]# ls -lah /mir3/gzip8
total 371M
drwxr-xr-x.  2 root root    3 Aug 22 09:34 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 379M Aug 22 09:37 debian-11.4.0-amd64-netinst.iso
[root@server vagrant]# ls -lah /mir3/gzip9
total 371M
drwxr-xr-x.  2 root root    3 Aug 22 09:38 .
drwxr-xr-x. 12 root root   12 Aug 22 06:29 ..
-rw-r--r--.  1 root root 379M Aug 22 09:42 debian-11.4.0-amd64-netinst.iso


```

So there is no difference between gzip6 7 8 9 in compression and result size of file.






## **2.Define pool settings**





Download archive


```
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O zfs_task1.tar.gz

```

Let's unpack archive:

```
[root@server vagrant]# tar -xzvf zfs_task1.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

```
Import zpool:

```
zpool import -d zpoolexport
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE

zpool import -d zpoolexport/ otus

[root@server vagrant]# zpool status
  pool: otus
 state: ONLINE
status: Some supported features are not enabled on the pool. The pool can
        still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(5) for details.
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0


```
Pool type = mirror

Let's cheking pool settings. it's size:

```
[root@server vagrant]# zpool list
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus   480M  2.11M   478M        -         -     0%     0%  1.00x    ONLINE  -

```
Size equal 480M

It's recordsize:

```
[root@server vagrant]# zfs get all | grep rec
otus            recordsize            128K                   local
otus/hometask2  recordsize            128K                   inherited from otus

```
Compression type

```
[root@server vagrant]# zfs get all | grep compression
otus            compression           zle                    local
otus/hometask2  compression           zle                    inherited from otus
```
Checksum

```
[root@server vagrant]# zfs get all | grep check
otus            checksum              sha256                 local
otus/hometask2  checksum              sha256                 inherited from otus
```

## **3. Finde jedi message:))**

Download file:

```
 wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task2.file
--2022-08-22 13:15:05--  https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving docs.google.com (docs.google.com)... 74.125.131.194
Connecting to docs.google.com (docs.google.com)|74.125.131.194|:443... connected.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/4e6hbp7s6iklsj1v8g4clva94nfurf06/1661174100000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=43741a85-f3b4-4d73-b493-2b80b1ecdeb3 [following]
Warning: wildcards not supported in HTTP.
--2022-08-22 13:15:09--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/4e6hbp7s6iklsj1v8g4clva94nfurf06/1661174100000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=43741a85-f3b4-4d73-b493-2b80b1ecdeb3
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 216.58.210.129
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|216.58.210.129|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: 'otus_task2.file'

otus_task2.file       100%[=========================>]   5.18M  7.70MB/s    in 0.7s

2022-08-22 13:15:10 (7.70 MB/s) - 'otus_task2.file' saved [5432736/5432736]

```

Restore snapshot:

```
[root@server vagrant]# zfs create otus/data
[root@server vagrant]# zfs receive otus/data/snap < otus_task2.file
[root@server vagrant]# zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            4.98M   347M       25K  /otus
otus/data       2.85M   347M       25K  /otus/data
otus/data/snap  2.83M   347M     2.83M  /otus/data/snap
otus/hometask2  1.88M   347M     1.88M  /otus/hometask2

```
Let's finde and read secret message:

```
[root@server vagrant]# find /otus/data/snap/ -name "secret*"
/otus/data/snap/task1/file_mess/secret_message
[root@server vagrant]# cat /otus/data/snap/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome

```
Message is https://github.com/sindresorhus/awesome



















