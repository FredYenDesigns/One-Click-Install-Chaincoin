#!/bin/sh
#Version 0.16.4
#Info: Installs Chaincoind daemon, Masternode based on privkey, and a simple web monitor.
#Chaincoin Version 0.9.3 or above
#Tested OS: Ubuntu 17.04, 16.04, and 14.04
#TODO: make script less "ubuntu" or add other linux flavors
#TODO: remove dependency on sudo user account to run script (i.e. run as root and specifiy chaincoin user so chaincoin user does not require sudo privileges)
#TODO: add specific dependencies depending on build option (i.e. gui requires QT4)

noflags() {
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    echo "Usage: install-chc"
    echo "Example: install-chc"
    echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
    exit 1
}

message() {
	echo "╒════════════════════════════════════════════════════════════════════════════════>>"
	echo "| $1"
	echo "╘════════════════════════════════════════════<<<"
}

error() {
	message "An error occured, you must fix it to continue!"
	exit 1
}


prepdependencies() { #TODO: add error detection
	message "Installing CHC Dependencies..."
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt-get install build-essential -y
	sudo apt-get install libtool -y
	sudo apt-get install autotools-dev -y
	sudo apt-get install automake -y
	sudo apt-get install autoconf -y
	sudo apt-get install pkg-config -y
	sudo apt-get install libssl-dev -y
	sudo apt-get install libevent-dev -y
	sudo apt-get install bsdmainutils -y
	sudo apt-get install libboost-system-dev -y
	sudo apt-get install libboost-filesystem-dev -y
	sudo apt-get install libboost-chrono-dev -y
	sudo apt-get install libboost-program-options-dev -y
	sudo apt-get install libboost-test-dev -y
	sudo apt-get install libboost-thread-dev -y
	sudo apt-get install libminiupnpc-dev -y
	sudo apt-get install libzmq3-dev -y
	sudo apt-get install software-properties-common -y
	sudo add-apt-repository ppa:bitcoin/bitcoin -y
	sudo apt-get update
	sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}

createswap() { #TODO: add error detection
	message "Chill Bro, Creating 2GB Swap File..."
	sudo dd if=/dev/zero of=/swapfile bs=1M count=2000
	sudo mkswap /swapfile
	sudo chown root:root /swapfile
	sudo chmod 0600 /swapfile
	sudo swapon /swapfile

	#make swap permanent
	sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
}

clonerepo() { #TODO: add error detection
	message "Downloading Wallet from CHC Github..."
  	cd ~/
	git clone https://github.com/chaincoin/chaincoin
}

compile() {
	cd chaincoin #TODO: squash relative path
	message "Let's Build This Now..."
	./autogen.sh
	if [ $? -ne 0 ]; then error; fi
	message "Configuring Build Options..."
	./configure $1 --disable-tests
	if [ $? -ne 0 ]; then error; fi
	message "Building ChainCoin...this may take a few minutes..."
	make
	if [ $? -ne 0 ]; then error; fi
	message "Installing ChainCoin Wallet..."
	sudo make install
	if [ $? -ne 0 ]; then error; fi
}

createconf() {
	#TODO: Can check for flag and skip this
	#TODO: Random generate the user and password

	message "Creating chaincoin.conf..."
	
	CONFDIR=~/.chaincoincore
	CONFILE=$CONFDIR/chaincoin.conf
	if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
	if [ $? -ne 0 ]; then error; fi
	
	mnip=$(curl -s https://api.ipify.org)
	
	printf "%s\n" "rpcauth={rpcauth user}:{rpcauth key}" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "masternode=1" "masternodeprivkey=(MN GenKey)" > $CONFILE

        chaincoind
        message "Wait 10 seconds for daemon to load..."
        sleep 20s
        MNPRIVKEY=$(chaincoin-cli masternode genkey)
	chaincoin-cli stop
	message "wait 10 seconds for deamon to stop..."
        sleep 10s
	sudo rm $CONFILE
	message "Updating chaincoin.conf..."
        printf "%s\n" "rpcauth={rpcauth user}:{rpcauth key}" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "masternode=1" "masternodeprivkey=(MN GenKey)" > $CONFILE


}

sentinel() {
	message "Installing Sentinel..."
	cd ~/
	sudo apt-get update
	sudo apt-get -y install python-virtualenv
	sudo apt install virtualenv -y
	git clone https://github.com/chaincoin/sentinel.git && cd sentinel
	virtualenv ./venv
	virtualenv ./venv && ./venv/bin/pip install -r requirements.txt
	git pull
	message "Creating sentinel.conf..."
	printf "%s\n" "rpcuser={rpcauth user}" "rpcpassword={rpcauth password}" "rpcport=11995" "rpchost=127.0.0.1" "network=mainnet" "db_name=database/sentinel.db" "db_driver=sqlite" > sentinel.conf
	message "Updating Crontab..."
	(crontab -l 2>/dev/null; echo "* * * * * cd /root/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1") | crontab -
}

success() {
	
	message "SUCCESS! Your CHC Wallet Is Installed. Please update config files"
	message "Please Donate to Fred!"
	message "His CHC Address: CPKc6gk5S3zyVgD4yKSoz5M7MQxiuSCupV"
	exit 0
}

install() {
	prepdependencies
	createswap
	clonerepo
	compile $1
	createconf
	sentinel
	success
}

#main
#default to --without-gui
install --without-gui
