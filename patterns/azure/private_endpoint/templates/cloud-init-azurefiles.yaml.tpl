#cloud-config
package_update: true
packages:
  - cifs-utils
  - dnsutils
  - iputils-ping
  - traceroute
  - netcat-openbsd

write_files:
  - path: /etc/smbcredentials/${storage_account_name}.cred
    permissions: "0600"
    content: |
      username=${storage_account_name}
      password=${storage_account_key}

runcmd:
  - mkdir -p ${mount_path}

  - |
    set -e
    FQDN="${fqdn}"
    SHARE="${file_share_name}"
    MOUNT="${mount_path}"

    echo "Waiting for private DNS to resolve ${fqdn}..."
    for i in $(seq 1 60); do
      if nslookup "${fqdn}" >/dev/null 2>&1; then
        echo "DNS OK"
        break
      fi
      sleep 5
    done

    echo "Configuring fstab..."
    grep -q "${fqdn}/${file_share_name}" /etc/fstab || echo "//${fqdn}/${file_share_name} ${mount_path} cifs vers=3.0,credentials=/etc/smbcredentials/${storage_account_name}.cred,serverino,nofail,_netdev 0 0" >> /etc/fstab

    echo "Attempting mount..."
    for i in $(seq 1 60); do
      if mount -a; then
        echo "Mount OK"
        break
      fi
      sleep 5
    done

    echo "Writing proof file..."
    if mountpoint -q "${mount_path}"; then
      HOSTNAME="$(hostname)"
      date -Is > "${mount_path}/from-$HOSTNAME.txt"
      ls -la "${mount_path}" || true
      echo "OK: wrote ${mount_path}/from-$HOSTNAME.txt"
    else
      echo "ERROR: mount not available" >/var/log/azurefiles-mount-error.log
      exit 1
    fi
