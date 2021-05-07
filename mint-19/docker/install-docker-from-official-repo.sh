#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

numberOfIpAddresses=$(ip -oneline -4 addr|grep -Pv '^\d+:\s+lo\s+'|wc -l);
if [[ 1 != $numberOfIpAddresses ]]; then
	echo "E: The docker-ce package has a known issue when installing while connected to VPN.";
	echo "";
	echo "   It will incorrectly configure the docker.service which will cause it to fail";
	echo "   and generate errors during system startup and when running certain package";
	echo "   manager commands. For this reason the script will abort while connected to VPN";
	echo "";
	echo "   Note: This only applies *during* installation. Having VPN active *after* the";
	echo "   installation does NOT cause any issues with the docker service / its config.";
	echo "";
	echo "   See here for more:";
	echo "   https://github.com/docker/for-linux/issues/84";
	echo "";
	echo "   Please disconnect from VPN when safe to do so and run the script again.";
	exit -1;
fi

if [[ -z "${UBUNTU_CODENAME}" ]]; then
	MINT_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/lsb-release);
	MINT_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/lsb-release);
	UBUNTU_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/upstream-release/lsb-release);
	UBUNTU_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/upstream-release/lsb-release);
fi

case "$UBUNTU_CODENAME" in
	bionic) a=ok ;;
	*) a=FAIL ;;
esac

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# Instructions adapted from:
#	https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
#	https://stackoverflow.com/questions/41133455/docker-repository-does-not-have-a-release-file-on-running-apt-get-update-on-ubun
#	https://dev.to/d4vsanchez/install-docker-community-edition-in-linux-mint-2gl4

echo "Installing dependencies ...";
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common;

# add key
# From official instructions:
#	dockerKeyPath='/usr/share/keyrings/docker-archive-keyring.gpg'
#	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "${dockerKeyPath}";
# BUT
#	apt update gives the following warnings & errors:
#	Err:17 https://download.docker.com/linux/ubuntu bionic InRelease
#	  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 7EA0A9C3F273FCD8
#	W: GPG error: https://download.docker.com/linux/ubuntu bionic InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 7EA0A9C3F273FCD8
#	E: The repository 'https://download.docker.com/linux/ubuntu bionic InRelease' is not signed.

# add key
#	https://dev.to/d4vsanchez/install-docker-community-edition-in-linux-mint-2gl4
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;

# add repo
echo "Adding custom repo source ...";
# official way using dockerKeyPath had issues
#addAptCustomSource docker "deb [arch=amd64 signed-by=${dockerKeyPath}] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable";

# add repo
#	https://dev.to/d4vsanchez/install-docker-community-edition-in-linux-mint-2gl4
addAptCustomSource docker "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable";

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing package ...";
# docker-ce-cli & containerd.io don't create any issues even if on vpn when they are installed
# and they don't pull down docker-ce with them.
sudo apt-get install -y docker-ce-cli containerd.io;

# however, docker-ce adds dockerd and this daemon
# will throw errors DURING STARTUP and DURING APT INSTALLS if it cannot start,
# such as due to the following conditions:
#	1. System has multiple non-loopback ip addresses (such as from vpn connection; e.g. from eth0 and tun0)
#		https://github.com/docker/for-linux/issues/84#issuecomment-494521659
#	2. A a badly formatted /etc/docker/daemon.json
#		https://github.com/docker/for-linux/issues/84#issuecomment-526864492
#	3. ??? (possibly other unknown conditions: there were a LOT of reddit/stackoverflow posts with similar
#			errors that didn't mention vpn and likewise at least 5 issues reported on either docker or
#			its upstream project - moby - with similar error messages/issues but no mention of vpn)
#
sudo apt-get install -y docker-ce;

# putting this after docker-ce, bc not sure if it requires docker-ce as a dependency
# should i add any of the following?:
#		cockpit                                      - User interface for Linux servers
#		cockpit-docker                               - Cockpit user interface for Docker containers
#		docker-containerd                            - daemon to control runC (Docker's version)
#		docker-doc                                   - Linux container runtime -- documentation
#		docker.io                                    - Linux container runtime
#		docker-registry                              - Docker toolset to pack, ship, store, and deliver conte
#		docker-runc                                  - Open Container Project - runtime (Docker's version)
#		systemd-docker                               - wrapper for "docker run" to handle systemd quirks
#
sudo apt-get install -y docker-compose;

isCockpitInstalled=$(dpkg -l cockpit 2>/dev/null|grep -Pic '^ii\s+cockpit\b');
if [[ 1 == $isCockpitInstalled ]]; then
	sudo apt-get install -y cockpit-docker;
fi

# A group named 'docker' should have been created during the install.
# If not, create it now
if [[ 1 != $(getent group docker 2>/dev/null|grep -Pc '^docker:') ]]; then
	sudo groupadd --system docker;
fi

# Add current user to docker group
sudo usermod -aG docker $USER

# refresh group roles for current user's active session
# (otherwise a reboot would be required before user being added to group took effect)
newgrp docker;

# Afterwards, I ran into a problem with error messages about docker when running apt-get install commands or
# sudo dpkg --configure -a
#==========================================================================================================
#	Job for docker.service failed because the control process exited with error code.
#	See "systemctl status docker.service" and "journalctl -xe" for details.
#	invoke-rc.d: initscript docker, action "start" failed.
#		docker.service - Docker Application Container Engine
#			Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
#			Active: activating (auto-restart) (Result: exit-code) since Wed 2021-03-03 16:49:44 EST; 6ms ago
#			Docs: https://docs.docker.com
#			Process: 15036 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock (code=exited, status=1/FAILURE)
#			Main PID: 15036 (code=exited, status=1/FAILURE)
#
#	dpkg: error processing package docker-ce (--configure):
#		installed docker-ce package post-installation script subprocess returned error exit status 1
#	Setting up libpwquality-tools (1.4.0-2) ...
#	Setting up libbytesize1 (1.2-3) ...
#	dpkg: dependency problems prevent configuration of docker-ce-rootless-extras:
#		docker-ce-rootless-extras depends on docker-ce; however:
#		Package docker-ce is not configured yet.
#
#	dpkg: error processing package docker-ce-rootless-extras (--configure):
#		dependency problems - leaving unconfigured
#
#	Errors were encountered while processing:
#		docker-ce
#		docker-ce-rootless-extras
#
# [...]
#
#	E: Sub-process /usr/bin/dpkg returned an error code (1)
#==========================================================================================================
#$ sudo journalctl -f -u docker
#[sudo] password for testbox:
#-- Logs begin at Fri 2019-05-03 11:46:47 EDT. --
#Mar 03 17:08:53 testbox dockerd[4130]: failed to start daemon:
#	Error initializing network controller: list bridge addresses failed:
#	PredefinedLocalScopeDefaultNetworks List: [172.17.0.0/16 172.18.0.0/16 172.19.0.0/16 172.20.0.0/16
#	172.21.0.0/16 172.22.0.0/16 172.23.0.0/16 172.24.0.0/16 172.25.0.0/16 172.26.0.0/16 172.27.0.0/16
#	172.28.0.0/16 172.29.0.0/16 172.30.0.0/16 172.31.0.0/16 192.168.0.0/20 192.168.16.0/20
#	192.168.32.0/20 192.168.48.0/20 192.168.64.0/20 192.168.80.0/20 192.168.96.0/20 192.168.112.0/20
#	192.168.128.0/20 192.168.144.0/20 192.168.160.0/20 192.168.176.0/20 192.168.192.0/20 192.168.208.0/20
#	192.168.224.0/20 192.168.240.0/20]: no available network
#
#Mar 03 17:08:53 testbox systemd[1]: docker.service: Main process exited, code=exited, status=1/FAILURE
#Mar 03 17:08:53 testbox systemd[1]: docker.service: Failed with result 'exit-code'.
#Mar 03 17:08:53 testbox systemd[1]: Failed to start Docker Application Container Engine.
#Mar 03 17:08:55 testbox systemd[1]: docker.service: Service hold-off time over, scheduling restart.
#Mar 03 17:08:55 testbox systemd[1]: docker.service: Scheduled restart job, restart counter is at 3.
#Mar 03 17:08:55 testbox systemd[1]: Stopped Docker Application Container Engine.
#Mar 03 17:08:55 testbox systemd[1]: docker.service: Start request repeated too quickly.
#Mar 03 17:08:55 testbox systemd[1]: docker.service: Failed with result 'exit-code'.
#Mar 03 17:08:55 testbox systemd[1]: Failed to start Docker Application Container Engine.
#
#-> It this because I installed while connected to PIA?
#==========================================================================================================
#	https://stackoverflow.com/questions/39617387/docker-daemon-cant-initialize-network-controller
#
#	This was related to the machine having several network cards (can also happen in machines with VPN,
#	you can also temporarily stop it, start docker and restart the vpn OR apply the below workaround)
#
#	To me, the solution was to start manually docker like this:
#		/usr/bin/docker daemon --debug --bip=192.168.y.x/24
#
#	where the 192.168.y.x is the MAIN machine IP and /24 that ip netmask. Docker will use this network
#	range for building the bridge and firewall riles. The --debug is not really needed, but might help
#	if something else fails
#
#	After starting once, you can kill the docker and start as usual. AFAIK, docker have created a
#	cache config for that --bip and should work now without it. Of course, if you clean the docker
#	cache, you may need to do this again.
#
#==========================================================================================================
#
# looking into this I found:
#	https://askubuntu.com/questions/940627/problems-installing-docker-on-16-04-failed-to-start-docker-application-contain
#	> Based on this link I used the following steps:
#		https://github.com/moby/moby/issues/22371#issuecomment-215254534
#		rm -rf /var/lib/docker  - this will remove all existing containers and images.
#		edit /etc/default/docker file and add the option: DOCKER_OPTS="-s overlay"
#		systemctl restart docker.service
#
#	https://github.com/docker/for-linux/issues/820
#	> Yep, so you must be on a more recent kernel version.
#
#	https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=939539
#	> In order to override the systemd ExecStart command I did:
#		To make sure it was a clean installation:
#		sudo apt remove --purge docker.io
#		rm -rf /var/lib/docker
#		sudo apt install docker.io
#
#		sudo systemctl edit docker.service
#		and put the following lines in the file:
#			[Service]
#			ExecStart=
#			ExecStart=/usr/sbin/dockerd -H unix:// $DOCKER_OPTS
#
#		sudo systemctl daemon-reload
#		sudo systemctl restart docker.service
#
#	https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=939539
#	> I found two things to solve this issue:
#		1) edit /etc/default/grub and edit the line GRUB_CMDLINE_LINUX to contain:
#			GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
#		2) Run the following script:
#			https://github.com/moby/moby/issues/8791#issuecomment-60874893
#
#	> To compare [...] The important point, as you noted, is the cgroup part
#	> Just to finalize, it was NOT necessary to modify the GRUB_CMDLINE_LINUX
#		value in /etc/default/grub but it IS necessary to manually run the
#		script from here after each reboot:
#		https://github.com/moby/moby/issues/8791#issuecomment-60874893
#
#		It appears that even though cgroupfs-mount is required by the docker.io
#		package, either the cgroupfs-mount package or else the docker.io package
#		is not setting things up properly with the cgroup system mounts and they
#		are not getting mounted at boot time.
#
#
#
#
