if [ -e /dev/sr0 ]; then 
    echo cdrom_present=true
else 
    echo cdrom_present=false
fi

if grep -q -i E6410 /sys/devices/virtual/dmi/id/product_name; then
    echo is_e6410=true
else
    echo is_e6410=false
fi 
