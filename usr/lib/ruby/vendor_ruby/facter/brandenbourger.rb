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
	    Facter::Core::Execution.exec("grep -qi e6410 /sys/devices/virtual/dmi/id/product_name && echo 'true' || echo 'false'")
    end
  end
end


