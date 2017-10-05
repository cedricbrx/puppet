node default { 
	include repository
	include apt
	include utilities
	include games
	include gnomeshell
	include multimedia
	include printers
	include hardware
	include thunderbird
	include libreoffice
	include synology
}

class repository {
	$mirror="deb http://lu.archive.ubuntu.com/ubuntu/"
	$security="deb http://security.ubuntu.com/ubuntu/"
	$packages="main restricted universe multiverse"
	file {'/etc/apt/trusted.gpg.d/brandenbourger.gpg':
		source         => 'https://github.com/cedricbrx/puppet/raw/master/etc/apt/trusted.gpg.d/brandenbourger.gpg',
		ensure         => present,
		checksum       => sha256,
		checksum_value => '1f36daf59e021d10d53d9aedb5d784db59ce2d73c01594352eb9c6b809a70161',
	}
	file {'/etc/apt/sources.list':
		ensure => present,
		owner   => root,
		group   => root,
		mode    => '644',
		content => "$mirror ${lsbdistcodename} $packages\n$security ${lsbdistcodename}-security $packages\n$mirror ${lsbdistcodename}-updates $packages",
	}
	#file {'/etc/apt/sources.list.d/brandenbourger.list':
	#	ensure  => present,
	#	owner   => root,
	#	group   => root,
	#	mode    => '644',
	#	require => File['/etc/apt/trusted.gpg.d/brandenbourger.gpg'],
	#	content => "deb https://raw.githubusercontent.com/cedricbrx/packages/master/ $lsbdistcodename main",
	#}
	package {'apt-transport-https':
		ensure => installed,
	}
}

class apt {
	require repository
	exec {"apt-update":
		command => "/usr/bin/apt-get update",
	}
	package{"unattended-upgrades":
		ensure  => installed,
		require => Exec["apt-update"],
	}
	file {'/etc/apt/apt.conf.d/99brandenbourger':
		ensure => present,
		owner   => root,
		group   => root,
		mode    => '644',
		require => Package["unattended-upgrades"],
		source => 'https://raw.githubusercontent.com/cedricbrx/puppet/master/etc/apt/apt.conf.d/99brandenbourger',
		checksum => sha256,
		checksum_value => 'acb63f0a4810573f88db892c6529ec3843a3f3273c47cd55187a07cb8b226a34',
	}
	package {"debconf-utils":
        	ensure  => installed,
		require => Exec["apt-update"],
	}
}

class firefox {
	#file {"/usr/bin/mozilla-extension-manager":
	#	source => 'https://raw.githubusercontent.com/NicolasBernaerts/ubuntu-scripts/master/mozilla/mozilla-extension-manager',
	#	ensure => present,
	#	owner  => root,
	#	group  => root,
	#	mode   => '755',
	#}
}

class thunderbird {
	package {"xul-ext-gdata-provider":
		ensure => installed,
	}
	package {"xul-ext-lightning":
		ensure => installed,
	}
	#exec {"/usr/bin/mozilla-extension-manager --update --system https://addons.mozilla.org/thunderbird/downloads/latest/gcontactsync/addon-8451-latest.xpi":
	#	user => root,
	#	require => File["/usr/bin/mozilla-extension-manager"],
	#}
}

class libreoffice {
	require apt
	file {"/usr/lib/libreoffice/share/registry/brandenbourger.xcd":
		owner  => root,
		group  => root,
		mode   => '644',
		source => "https://raw.githubusercontent.com/cedricbrx/puppet/master/usr/lib/libreoffice/share/registry/brandenbourger.xcd",
		checksum => sha256,
		checksum_value => 'a4ec0353d49f016a306af0002577bba7f1b40fdb2404985e510cfb49829fa648',
	}
}

class hardware {
	if $is_e6410 == 'true' {
		exec {"/bin/echo 2 | /usr/bin/tee /sys/devices/platform/dell-laptop/leds/dell::kbd_backlight/brightness":
			user => root,
			unless => "/bin/grep 2 /sys/devices/platform/dell-laptop/leds/dell::kbd_backlight/brightness",
		}
		file {'/etc/modprobe.d/wlan_brandenbourger.conf':
			content => 'options iwlwifi led_mode=1',
			backup  => false,
		}
	}
	if $cpu_vendor == 'amd'{
		package {"amd64-microcode":
			ensure => installed,
		}
		package {"intel-microcode":
			ensure => purged,
		}
	}
	else {
		package {"amd64-microcode":
			ensure => purged,
		}
		package {"intel-microcode":
			ensure => installed,
		}
	}
}

class printers {
	require apt
	package {"cups-browsed":
		ensure => purged,
	}
	package {"hplip-gui":
		ensure => installed,
	}
	if $mac_gateway == 'XXX'{
			notice ('printer')
	}
}

class multimedia {
	require apt
	exec {'accept-msttcorefonts-license':
		command => '/bin/sh -c "echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections"',
		unless  => '/usr/bin/debconf-get-selections | /bin/grep "msttcorefonts/accepted-mscorefonts-eula.*true"',
	}
	package {"ubuntu-restricted-extras":
		ensure => installed,
		require => Exec['accept-msttcorefonts-license'],
	}
	package {"rhythmbox":
		ensure => purged,
	}
	exec {'configure-libdvd-pkg':
		command => '/bin/sh -c "echo -e libdvd-pkg libdvd-pkg/post-invoke_hook-remove boolean false\nlibdvd-pkg libdvd-pkg/build boolean true | debconf-set-selections"',
		unless  => '/usr/bin/debconf-get-selections | /bin/grep "libdvd-pkg/post-invoke_hook-install"',
	}
	package {'libdvd-pkg':
		ensure  => installed,
		require => Exec['configure-libdvd-pkg'],
	}
	package {"youtube-dl":
		ensure => installed,
	}
	package { ["brasero", "nautilus-extension-brasero"]:
       		ensure => $cdrom_present ? {
            		'true'  => installed,
        		default => purged,
        	}
	}
	package {"gimp":
		ensure => installed,
	}
}

class gnomeshell {
	require apt
	package {"gnome-power-manager":
		ensure => purged,
	}
	package {["gnome-shell-extensions","gnome-shell-extension-remove-dropdown-arrows","gnome-shell-extension-better-volume"]:
		ensure => installed,
	}
	file {"/etc/dconf/profile/user":
    		content => "user-db:user\nsystem-db:brandenbourger",
		require => Package["gnome-shell-extensions"],
	}
	file {["/etc/dconf/db/brandenbourger.d", "/etc/dconf/db/brandenbourger.d/locks"]:
		ensure  => directory,
		require => File["/etc/dconf/profile/brandenbourger"],
	}
	file {"/etc/dconf/db/brandenbourger.d/00_brandenbourger":
		source         => "https://raw.githubusercontent.com/cedricbrx/puppet/master/etc/dconf/db/brandenbourger.d/00_brandenbourger",
		require        => File["/etc/dconf/db/brandenbourger.d"],
		ensure         => present,
       		checksum       => sha256,
       		checksum_value => '9213980f2e3cb4a69c9d7edb2e9b9b21f7b4b64ce25fadfa6681f2f6513b40a2',
	}
	file {"/etc/dconf/db/brandenbourger.d/locks/00_brandenbourger":
		source         => "https://raw.githubusercontent.com/cedricbrx/puppet/master/etc/dconf/db/brandenbourger.d/locks/00_brandenbourger",
		require        => File["/etc/dconf/db/brandenbourger.d"],
		ensure         => present,
       		checksum       => sha256,
       		checksum_value => 'e29cb7ff09e5b6c706a11b5feb9a5a1b0059cd58f4d7afc5658ff38ea4e418c4',
	}
}

class utilities {
	require apt
	package {"deja-dup":
		ensure => $pc_owner ? {
            		'alex'  => installed,
        		default => purged,
        	}
	}
	package {"remmina":
		ensure => purged,
	}
	package {"yelp":
		ensure => purged,
	}
	package {"xdiagnose":
		ensure => purged,
	}
	package {"transmission-common":
		ensure => purged,
	}
	package {"onboard-common":
		ensure => purged,
	}
	package {"ubuntu-web-launchers":
		ensure => purged,
	}
	package {"keepassx":
		ensure => installed,
	}
	package {"fdupes":
		ensure => installed,	
	}
	package {"fslint":
		ensure => installed,
	}
	package {"unrar":
		ensure => installed,
	}
	package {"lshw":
		ensure => installed,
	}
	package {"mlocate":
		ensure => installed,
	}
	package {"vim":
		ensure => installed,
	}
	package {"hfsprogs":
		ensure => installed,
	}
	package {"curl":
		ensure => installed,
	}
}

class synology {
    require apt
    $quickconnect_URL = $pc_owner ? {
	brand10 => 'https://brandenbourger.quickconnect.to',
	anne04  => 'https://brandenbourger.quickconnect.to',
	default => 'https://brandenbourg.quickconnect.to',
    }
    $prefix="[Desktop Entry]\nTerminal=false\nType=Application\nIcon=/usr/share/icons/hicolor/64x64/apps/synology_"
    $title_df='[Desktop Entry]'
    $terminal_df='Terminal=false'
    $type_df='Type=Application'
    $icon_df='Icon=/usr/share/icons/hicolor/64x64/apps/synology_'
    $name_df='Name=Brandenbourger'
    $exec_df='Exec=xdg-open'
    $syn_video="${prefix}videos.png\n$name_df Videos\n$exec_df $quickconnect_URL/video"
    #$syn_video="$title_df\n$terminal_df\n$type_df\n${icon_df}videos.png\n$name_df Videos\n$exec_df $quickconnect_URL/video"
    $syn_photo="$title_df\n$terminal_df\n$type_df\n${icon_df}photos.png\n$name_df Photos\n$exec_df $quickconnect_URL/photo"
    #package {"synology-cloud-station":
    #    ensure => installed,
    #}
    #package {"synology-assistant":
    #    ensure => installed,
    #}
    file {"/usr/share/applications/brandenbourger-photos.desktop":
        content => "$syn_photo",
    }
    file {"/usr/share/applications/brandenbourger-videos.desktop":
        content => "$syn_video",
    }
    file {"/usr/share/icons/hicolor/64x64/apps/synology_videos.png":
        source         => "https://raw.githubusercontent.com/cedricbrx/puppet/master/usr/share/icons/hicolor/64x64/apps/synology_videos.png",
        ensure         => present,
        checksum       => md5,
        checksum_value => '998653e5331a38c68f3164705e6021bd',
    }
    file {"/usr/share/icons/hicolor/64x64/apps/synology_photos.png":
        source         => "https://raw.githubusercontent.com/cedricbrx/puppet/master/usr/share/icons/hicolor/64x64/apps/synology_photos.png",
        ensure         => present,
        checksum       => md5,
        checksum_value => '1acddd4b3da197f666451c60bf5f909c',
    }
}     

class games {
	require apt
	package {"gnome-mines":
		ensure => purged,
	}
	package {"aisleriot":
		ensure => purged,
	}
	package {"gnome-mahjongg":
		ensure => purged,
	}
	package {"gnome-sudoku":
		ensure => purged,
	}
}
