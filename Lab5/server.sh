  #!/bin/bash
sudo yum install nfs-utils -y
sudo mkdir -p /home/vagrant/share/upload
sudo chmod o+w /home/vagrant/share/upload
sudo echo '/home/vagrant/share/ *(rw)' >> /etc/exports
sudo exportfs -r
systemctl start nfs-server
sudo systemctl start firewalld
sudo firewall-cmd --add-service=nfs
sudo firewall-cmd --add-protocol=udp
sudo systemctl start nfs-server.service && systemctl enable nfs-server.service


