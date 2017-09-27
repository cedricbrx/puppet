Facter.add(:cdrom_present) do
  setcode do
    require 'facter/util/config'

    if Facter::Util::Config.is_windows?
      'windows'
    else
	    Facter::Core::Execution.exec("[ -e '/dev/sr0' ] && echo 'true' || echo 'false'")
    end
  end
end

Facter.add(:is_e6410) do
  setcode do
    require 'facter/util/config'

    if Facter::Util::Config.is_windows?
      'windows'
    else
	    Facter::Core::Execution.exec("grep -qi E6410 /sys/devices/virtual/dmi/id/product_name && echo 'true' || echo 'false'")
    end
  end
end

Facter.add(:cpu_vendor) do
  setcode do
    require 'facter/util/config'

    if Facter::Util::Config.is_windows?
      'windows'
    else
	    Facter::Core::Execution.exec("grep -qi AMD /proc/cpuinfo && echo 'amd' || echo 'intel'")
    end
  end
end

Facter.add(:mac_gateway) do
  setcode do
    require 'facter/util/config'

    if Facter::Util::Config.is_windows?
      'windows'
    else
	    Facter::Core::Execution.exec("ip neigh | grep $(ip -4 route list 0/0 | cut -d' ' -f3) | cut -d' ' -f5 | tr '[a-f]' '[A-F]'")
    end
  end
end
