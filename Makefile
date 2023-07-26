OUT_ZIP=SlackwareWSL2_multilib.zip
LNCR_EXE=Slackware.exe

DLR=curl
DLR_FLAGS=-L
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/23072600/icons.zip
LNCR_ZIP_EXE=Slackware.exe

all: $(OUT_ZIP)

zip: $(OUT_ZIP)
$(OUT_ZIP): ziproot
	@echo -e '\e[1;31mBuilding $(OUT_ZIP)\e[m'
	cd ziproot; bsdtar -a -cf ../$(OUT_ZIP) *

ziproot: Launcher.exe rootfs.tar.gz
	@echo -e '\e[1;31mBuilding ziproot...\e[m'
	mkdir ziproot
	cp Launcher.exe ziproot/${LNCR_EXE}
	cp rootfs.tar.gz ziproot/

exe: Launcher.exe
Launcher.exe: icons.zip
	@echo -e '\e[1;31mExtracting Launcher.exe...\e[m'
	unzip icons.zip $(LNCR_ZIP_EXE)
	mv $(LNCR_ZIP_EXE) Launcher.exe

icons.zip:
	@echo -e '\e[1;31mDownloading icons.zip...\e[m'
	$(DLR) $(DLR_FLAGS) $(LNCR_ZIP_URL) -o icons.zip

rootfs.tar.gz: rootfs
	@echo -e '\e[1;31mBuilding rootfs.tar.gz...\e[m'
	cd rootfs; sudo bsdtar -zcpf ../rootfs.tar.gz `sudo ls`
	sudo chown `id -un` rootfs.tar.gz

rootfs: base.tar
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo bsdtar -zxpf base.tar -C rootfs
	@echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf > /dev/null
	sudo cp wsl.conf rootfs/etc/wsl.conf
	sudo cp bash_profile rootfs/root/.bash_profile
	sudo cp bashrc rootfs/etc/skel/.bashrc
	sudo cp bashprofile rootfs/etc/skel/.bash_profile
	sudo cp slack_mirrortest rootfs/usr/local/bin/slack_mirrortest
	sudo chmod +x rootfs

base.tar:
	@echo -e '\e[1;31mExporting base.tar using docker...\e[m'
	docker run --net=host --name slackware aclemons/slackware:15.0 /bin/bash -c "sed -i '$ d' /etc/slackpkg/mirrors; echo "http://slackware.uk/slackware/slackware64-15.0/" | tee -a /etc/slackpkg/mirrors > /dev/null; wget --quiet --no-check-certificate https://slack.conraid.net/repository/slackware64-current/figlet/figlet-2.2.5-x86_64-1cf.txz; wget --quiet --no-check-certificate https://excellmedia.dl.sourceforge.net/project/slackpkgplus/slackpkg%2B-1.8.0-noarch-7mt.txz; installpkg figlet-2.2.5-x86_64-1cf.txz slackpkg+-1.8.0-noarch-7mt.txz; rm slackpkg+-1.8.0-noarch-7mt.txz figlet-2.2.5-x86_64-1cf.txz; sed -i 's/REPOPLUS=( slackpkgplus/REPOPLUS=( slackpkgplus multilib/g' /etc/slackpkg/slackpkgplus.conf; sed -i 's/#MIRRORPLUS\[\x27multilib\x27\]=https:\/\/slackware.nl\/people\/alien\/multilib\/15.0\//MIRRORPLUS\[\x27multilib\x27\]=http:\/\/slackware.uk\/people\/alien\/multilib\/15.0\//g' /etc/slackpkg/slackpkgplus.conf; echo 'YES' | slackpkg update gpg; slackpkg update; slackpkg upgrade slackpkg; slackpkg upgrade-all; slackpkg install acl acpid attr bash-completion bc bind binutils bison brotli btrfs-progs ca-certificates compat32-tools cpio curl cyrus-sasl dcron devs diffstat dosfstools ebtables ed elfutils elogind eudev exfatprogs f2fs-tools flex floppy gc git gcc gettext-tools glib glib2 glibc glibc-profile glibc-i18n glibc-zoneinfo gnutls gpm gptfdisk groff guile haveged hdparm hostname hwdata htop inih infozip inotify-tools iputils json-c kbd kmod lbzip2 less lftp libarchive libblockdev libbytesize libcap libgudev libmnl libnl libsodium libtool libunwind libusb libusb-compat libxml2 libuv libyaml lmdb logrotate lsof lvm2 lz4 lzip lzlib m4 make man mcelog minicom mlocate mtx nano ncompress ndctl neofetch network-scripts nghttp2 ntp oniguruma openssh openssl-solibs pam parted pciutils pcmciautils pcre pinentry perl pkg-config plzip readline reiserfsprogs rpm2tgz rsync ruby screen sdparm sharutils smartmontools splitvt squashfs-tools socat strace sudo sysklogd terminus-font texinfo udisks udisks2 unarj usb_modeswitch usbutils vim whois xxHash zlib zoo zstd; slackpkg upgrade multilib; slackpkg install multilib; mkdir temp && cd temp; wget --no-check-certificate https://github.com/busyloop/lolcat/archive/master.zip; unzip master.zip && cd lolcat-master/bin; gem install lolcat; cd && rm -rf temp; cd /var/log/packages; ls | rev | cut -f4- -d- | rev > ./package_list_multilib.txt"
	docker start slackware
	docker cp slackware:/var/log/packages/package_list_multilib.txt .
	docker exec slackware rm /var/log/packages/package_list_multilib.txt
	docker stop slackware
	docker export --output=base.tar slackware
	docker rm -f slackware

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar
	-rm package_list_multilib.txt
	-docker rmi -f aclemons/slackware:15.0
