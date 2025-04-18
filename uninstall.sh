#! /bin/bash

get_distro_id(){
	local RES
    RES=$(grep -i '^ID=' /etc/os-release)
    local ID_TMP="${RES:3}" #removing the 'ID='
    local ID="${ID_TMP,,}" # to lower
	echo "$ID"
}

DISTRO_ID=$(get_distro_id)


remove_hooks(){
	eval "rm -r /etc/libvirt/hooks"
	eval "rm -r /bin/vfio-startup.sh"
	eval "rm -r /bin/vfio-teardown.sh"
}


echo "About to remove /bin/vfio-startup.sh, /bin/vfio-teardown.sh!"
while true; do
    read -p "Do you wish to uninstall anyway? y/n " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

remove_hooks
echo "Uninstalled!"