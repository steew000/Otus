  #!/bin/bash
sudo yum install nfs-utils -y
sudo mkdir /mnt/share
sudo service nfs start
echo "192.168.50.10:/home/vagrant/share/ /mnt/share nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
sudo systemctl start firewalld
sudo firewall-cmd --add-service=nfs
sudo firewall-cmd --add-protocol=udp
sudo systemctl start nfs-server.service && systemctl enable nfs-server.service
