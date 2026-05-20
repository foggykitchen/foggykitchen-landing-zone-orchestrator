#cloud-config
runcmd:
  - sysctl -w net.ipv4.ip_forward=1
  - sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
  - echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
