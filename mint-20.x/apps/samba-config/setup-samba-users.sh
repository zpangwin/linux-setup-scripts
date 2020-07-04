#!/bin/bash

SMB_GROUP_NAME="smbgroup";
SMB_USERS_TO_SETUP="smbadmin smbuser";

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# Make backups
echo 'Backing up samba config files ...';
if [[ -e /etc/lightdm/users.conf ]]; then
	if [[ ! -e /etc/lightdm/users.conf.orig ]]; then
		sudo cp -a /etc/lightdm/users.conf /etc/lightdm/users.conf.orig;
	fi
fi
if [[ -e /etc/samba/smb.conf.orig ]]; then
	sudo cp -a /etc/samba/smb.conf /etc/samba/smb.conf.orig;
fi
if [[ -e /etc/samba/smbusers.orig ]]; then
	sudo cp -a /etc/samba/smbusers /etc/samba/smbusers.orig;
fi

# make sure group exists
echo 'Checking that samba group exists ...';
smb_group_exists=$(getent group {1000..60000}|grep -P "^${SMB_GROUP_NAME}:"|wc -l);
if [[ "0" == "${smb_group_exists}" ]]; then
	sudo groupadd "${SMB_GROUP_NAME}";
fi

if [[ -e /var/lib/AccountsService ]]; then
	if [[ ! -e /var/lib/AccountsService/users ]]; then
		sudo mkdir /var/lib/AccountsService/users;
	fi
fi

# setup samba users
echo 'Checking that samba users exist ...';
for smb_user_name in $(echo "${SMB_USERS_TO_SETUP}"); do
	smb_user_exists=$(getent passwd|grep -P "^${smb_user_name}:"|wc -l);
	if [[ "0" == "${smb_user_exists}" ]]; then
		sudo adduser --gecos "" --no-create-home --disabled-login --shell /bin/false "${smb_user_name}";
	fi
	if [[ -e /etc/lightdm/users.conf ]]; then
		sudo sed -i -E "s/^(hidden\\-users=.*)/\\1 ${smb_user_name}/" /etc/lightdm/users.conf;
	fi
	if [[ -e /var/lib/AccountsService/users ]]; then
		acct_services_file="/var/lib/AccountsService/users/${smb_user_name}";
		is_user_section_def="0";
		is_sys_acct_def="0";
		if [[ -e "${acct_services_file}" ]]; then
			sudo cp -a "${acct_services_file}" "${acct_services_file}.bak";
			is_user_section_def=$(grep -P '^\[User\]' "${acct_services_file}"|wc -l);
			if [[ "1" == "${is_user_section_def}" ]]; then
				is_sys_acct_def=$(grep -P '^SystemAccount=' "${acct_services_file}"|wc -l);
			fi
		fi
		if [[ "1" != "${is_user_section_def}" ]]; then
			echo -e '[User]\nSystemAccount=true'|sudo tee -a "${acct_services_file}" >/dev/null;

		elif [[ "1" == "${is_user_section_def}" && "1" != "${is_sys_acct_def}" ]]; then
			echo -e 'SystemAccount=true'|sudo tee -a "${acct_services_file}" >/dev/null;

		elif [[ "1" == "${is_sys_acct_def}" ]]; then
			sudo sed -i -E 's/^(SystemAccount)=.*$/\1=true/g' "${acct_services_file}" >/dev/null;
		fi
	fi
	is_user_defined_in_samba=$(grep -P "^${smb_user_name}\s*=\s*${smb_user_name}" /etc/samba/smbusers|wc -l);
	if [[ "0" == "${is_user_defined_in_samba}" ]]; then
		echo "${smb_user_name} = ${smb_user_name}"|sudo tee -a /etc/samba/smbusers >/dev/null;
	fi

	# Make sure user has been added to group
	smb_user_in_group=$(getent group {1000..60000}|grep -P "^${SMB_GROUP_NAME}:.*[:,]${smb_user_name}(?:,.*)?$"|wc -l);
	if [[ "0" == "${smb_user_in_group}" ]]; then
		sudo usermod -a -G "${SMB_GROUP_NAME}" "${smb_user_name}";
	fi
done

# Get default user
default_user=$(getent group {1000..1000}|awk -F: '{print $1}');

echo 'Checking that users are in samba group ...';

# If the default user is not in the smb group, then add them
def_user_in_group=$(getent group {1000..60000}|grep -P "^${SMB_GROUP_NAME}:.*[:,]${default_user}(?:,.*)?$"|wc -l);
if [[ "0" == "${def_user_in_group}" ]]; then
	sudo usermod -a -G "${SMB_GROUP_NAME}" "${default_user}";
fi

echo -e "\n\nPlease complete setup with the following commands:";
for smb_user_name in $(echo "${SMB_USERS_TO_SETUP}"); do
	echo "sudo passwd ${smb_user_name}";
	echo "sudo smbpasswd -a \"${smb_user_name}\"";
done
echo "";
echo "Confirm smbaccounts have been added with:";
echo "sudo pdbedit -L -v|grep Unix";
echo "";

