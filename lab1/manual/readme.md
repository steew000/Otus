OS: LMDE 5 (elsie) x86_64
Kernel: 5.10.0-14-amd64 

# **Install software**

### **Vagrant**

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt update && sudo apt-get install vagrant

```

### **Packer**


```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt update
sudo apt install packer

```

### **Git**

```
sudo apt install git
```

### **VirtualBox**

```
$ wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  118  apt install virtualbox
```

# **Kernel update**

### **Fork OTUS lab**

Clone otus lab:

```
git clone git@github.com:steew000/Otus_Demo_manual_kernel_update.git

```

Copy project to my repo

```
$ mkdir lab1
$ cp -r manual /../Otus/lab1/manual
$ cp -r packer/ /../Otus/lab1/packer
$ cp Vagrantfile /../Otus/lab1/Vagrantfile
$ git add manual/
$ git add packer/
$ git add readme.md 
$ git add Vagrantfile 

```
Start VM: 

```
vagrant up

vagrant ssh

[vagrant@kernel-update ~]$ uname -r
3.10.0-1127.el7.x86_64


```

### **kernel update**

Add repo

```
sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```
Install kernel

```
sudo yum --enablerepo elrepo-kernel install kernel-ml -y

Installed:
  kernel-ml.x86_64 0:5.17.6-1.el7.elrepo                                                          

Complete!


```

### **grub update**

Grub config updating

```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

Set default boot with updating kernel and reboot VM

```
sudo grub2-set-default 0
sudo reboot
```

Check kernel version after reboot
```
[vagrant@kernel-update ~]$ uname -r
5.17.6-1.el7.elrepo.x86_64
```

---

# **Packer**

### **packer provision config**

Change variables:

```
    "artifact_description": "CentOS 7.7 with kernel 5.17.6-1",
    "artifact_version": "7.7.2009",
```


Change url in centos.json and hashsumm:

```
"iso_url": "https://mirror.yandex.ru/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso",
"iso_checksum": "07b94e6b1a0b0260b94c83d6bb76b26bf7a310dc78d7a9c7432809fb9bc6194a",
```


### **packer build**

```
packer build centos.json

1 error occurred:
	* Deprecated configuration key: 'iso_checksum_type'. Please call `packer fix`
against your template to update your template to be compatible with the current
version of Packer. Visit https://www.packer.io/docs/commands/fix/ for more
detail.


```

Let's fix json file


```
packer fix centos.json > centos2.json
```

and then try again

```
packer build centos2.json
Wait completed after 28 minutes 21 seconds

==> Builds finished. The artifacts of successful builds are:
--> centos-7.7: 'virtualbox' provider box: centos-7.7.1908-kernel-5-x86_64-Minimal.box

```

### **vagrant init (TEST)**
Let's test maked box. At first we import this box to vagrant

```
vagrant box add --name centos-7-5-2 centos-7.7.1908-kernel-5-x86_64-Minimal.box
==> box: Successfully added box 'centos-7-5-2' (v0) for 'virtualbox'!

```
Set
```
box_name => centos-7-5-2
```

in our Vagrantfile.  Then lets start our VM:

```
vagrant up
vagrant ssh

```
Let's check kernel version

```
[vagrant@kernel-update ~]$ uname -r
5.17.6-1.el7.elrepo.x86_64
```

Remove test VM

```
vagrant box remove centos-7-5-2
```

---
# **Vagrant cloud**

Upload our box in Vagrant cloud.

```
vagrant cloud auth login
Vagrant Cloud username or email: <user_email>
Password (will be hidden): 
Token description (Defaults to "Vagrant login from hardpro"):
You are now logged in.
vagrant cloud publish --release steew/centos-7-5 1.0 virtualbox centos-7.7.1908-kernel-5-x86_64-Minimal.box


```

https://app.vagrantup.com/steew/boxes/centos-7-5/versions/2.0


























