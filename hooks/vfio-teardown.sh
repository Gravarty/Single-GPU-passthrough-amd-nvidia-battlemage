#!/bin/bash

#############################################################################
##     ______  _                _  _______         _                 _     ##
##    (_____ \(_)              | |(_______)       | |               | |    ##
##     _____) )_  _   _  _____ | | _    _   _   _ | |__   _____   __| |    ##
##    |  ____/| |( \ / )| ___ || || |  | | | | | ||  _ \ | ___ | / _  |    ##
##    | |     | | ) X ( | ____|| || |__| | | |_| || |_) )| ____|( (_| |    ##
##    |_|     |_|(_/ \_)|_____) \_)\______)|____/ |____/ |_____) \____|    ##
##                                                                         ##
#############################################################################
###################### Credits ###################### ### Update PCI ID'S ###
## Lily (PixelQubed) for editing the scripts       ## ##                   ##
## RisingPrisum for providing the original scripts ## ##   update-pciids   ##
## Void for testing and helping out in general     ## ##                   ##
## .Chris. for testing and helping out in general  ## ## Run this command  ##
## WORMS for helping out with testing              ## ## if you dont have  ##
##################################################### ## names in you're   ##
## The VFIO community for using the scripts and    ## ## lspci feedback    ##
## testing them for us!                            ## ## in your terminal  ##
## Modified for Intel Arc B580 by Grok             ## ##                   ##
##################################################### #######################

################################# Variables #################################

## Adds current time to var for use in echo for a cleaner log and script ##
DATE=$(date +"%m/%d/%Y %R:%S :")

################################## Script ###################################

echo "$DATE Beginning of Teardown!"

## Unload VFIO-PCI driver ##
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

echo "$DATE VFIO Modules Unloaded"

## Load GPU drivers based on detected GPU ##
if grep -q "true" "/tmp/vfio-is-nvidia"; then
    ## Load NVIDIA drivers ##
    echo "$DATE Loading NVIDIA GPU Drivers"

    modprobe drm
    modprobe drm_kms_helper
    modprobe i2c_nvidia_gpu
    modprobe nvidia
    modprobe nvidia_modeset
    modprobe nvidia_drm
    modprobe nvidia_uvm

    echo "$DATE NVIDIA GPU Drivers Loaded"

elif grep -q "true" "/tmp/vfio-is-amd"; then
    ## Load AMD drivers ##
    echo "$DATE Loading AMD GPU Drivers"

    modprobe drm
    modprobe drm_kms_helper
    modprobe amdgpu
    modprobe radeon

    echo "$DATE AMD GPU Drivers Loaded"

elif grep -q "true" "/tmp/vfio-is-intel"; then
    ## Load Intel drivers (Xe driver for Arc B580) ##
    echo "$DATE Loading Intel GPU Drivers"

    modprobe drm
    modprobe drm_kms_helper
    modprobe xe

    echo "$DATE Intel GPU Drivers Loaded"

else
    echo "$DATE No supported GPU flag (NVIDIA, AMD, or Intel) found!"
fi

## Rebind EFI-Framebuffer ##
if test -e /sys/bus/platform/drivers/efi-framebuffer/efi-framebuffer.0; then
    echo "$DATE Rebinding EFI-Framebuffer"
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
fi

## Restart Display Manager ##
input="/tmp/vfio-store-display-manager"
while read -r DISPMGR; do
    if command -v systemctl; then
        ## Make sure the variable got collected ##
        echo "$DATE Var has been collected from file: $DISPMGR"

        systemctl start "$DISPMGR.service"
    else
        if command -v sv; then
            sv start "$DISPMGR"
        fi
    fi
done < "$input"

############################################################################################################
## Rebind VT consoles (adapted and modernised from https://www.kernel.org/doc/Documentation/fb/fbcon.txt) ##
############################################################################################################

input="/tmp/vfio-bound-consoles"
while read -r consoleNumber; do
    if test -x /sys/class/vtconsole/vtcon"${consoleNumber}"; then
        if [ "$(grep -c "frame buffer" "/sys/class/vtconsole/vtcon${consoleNumber}/name")" = 1 ]; then
            echo "$DATE Rebinding console ${consoleNumber}"
            echo 1 > /sys/class/vtconsole/vtcon"${consoleNumber}"/bind
        fi
    fi
done < "$input"

echo "$DATE End of Teardown!"
