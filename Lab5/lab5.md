# **Lab5: NFS**

## **1.Create 2 vm's : client and server by vagrant**

Vagrant code:

```
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

#  config.vm.provision "ansible" do |ansible|
#    ansible.verbose = "vvv"
#    ansible.playbook = "playbook.yml"
#    ansible.become = "true"
#  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
  end

  config.vm.define "nfss" do |nfss|
    nfss.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "net1"
    nfss.vm.hostname = "nfss"
    nfss.vm.provision "shell", path: "server.sh"
  end

  config.vm.define "nfsc" do |nfsc|
    nfsc.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "net1"
    nfsc.vm.hostname = "nfsc"
    nfsc.vm.provision "shell", path: "clinet.sh"
  end

end

         
```

## **2.Share directory on server**

Make directory

```
sudo mkdir /home/vagrant/share
```

Share directory

```
sudo cat >/etc/exports<<__EOF
/home/vagrant/share *(rw)
__EOF
```

reload exports config and restart nfs server

```
sudo exportfs -r
sudo systemctl start nfs-server
```



## **3.Mount directory on client**

Make directory

```
sudo mkdir /mnt/share
```

Start nfs services

```
sudo service nfs start
```

Make mount in fstab

```
echo "192.168.50.10:/home/vagrant/share/ /mnt/share nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
```


## **4.Make upload dir with rw rihgts**

```
sudo mkdir /home/vagrant/share/upload
sudo chmod o+w /home/vagrant/share/upload
```

Check on client:

```
cd /mnt/share/upload
touch test
ls -alh
total 0
drwxr-xrwx. 2 root      root      31 Sep 11 14:02 .
drwxr-xr-x. 3 root      root      20 Sep 11 13:48 ..
-rw-r--r--. 1 nfsnobody nfsnobody  0 Sep 11 14:01 test

```
## **5.NFS v3 over UDP with firewall **
On server:

```
sudo systemctl start firewalld
sudo firewall-cmd --add-service=nfs
sudo firewall-cmd --add-protocol=udp
sudo systemctl start nfs-server.service && systemctl enable nfs-server.service

```

The same on client
==



Let's check connection on client
```
nfsstat -m
/mnt/share from 192.168.50.10:/home/vagrant/share/
 Flags: rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10
```















