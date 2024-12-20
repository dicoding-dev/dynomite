#!/bin/bash

CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo_cyan() {
  echo -e "${CYAN}$@${NC}"
}

echo_cyan => "Install requirement packages"
apt update
apt install -y build-essential cmake autoconf libtool gcc automake openssl pkg-config libyaml-dev libssl-dev

echo
echo_cyan => "Clone dynomite repository"
cd /tmp
git clone https://github.com/Netflix/dynomite.git
cd /tmp/dynomite
git checkout v0.6.22

echo
echo_cyan => "Fix dyn_ring_queue code"
# Reference: https://github.com/Netflix/dynomite/pull/775/files
cd /tmp/dynomite
sed -i '14i _C2G_InQ C2G_InQ = {};' src/dyn_ring_queue.c 
sed -i '15i _C2G_OutQ C2G_OutQ = {};' src/dyn_ring_queue.c 
sed -i '19s/.*/typedef volatile struct {/' src/dyn_ring_queue.h 
sed -i '23s/.*/} _C2G_InQ;/' src/dyn_ring_queue.h 
sed -i '25s/.*/typedef volatile struct {/' src/dyn_ring_queue.h 
sed -i '29s/.*/} _C2G_OutQ ;/' src/dyn_ring_queue.h 
sed -i '30i ' src/dyn_ring_queue.h
sed -i '31i extern _C2G_InQ C2G_InQ;' src/dyn_ring_queue.h
sed -i '32i extern _C2G_OutQ C2G_OutQ;' src/dyn_ring_queue.h
git add .
git commit -m "Fix building and linking with GCC 10"

echo
echo_cyan => "Unzip yaml library"
cd /tmp/dynomite/contrib
tar -xzf yaml-0.1.4.tar.gz

echo
echo_cyan => "Run autoupdate conf"
cd /tmp/dynomite/contrib/yaml-0.1.4
autoupdate
cd /tmp/dynomite
autoupdate

echo
echo_cyan => "Run build"
cd /tmp/dynomite
autoreconf -fvi
./configure --enable-debug=yes
make
src/dynomite -h

echo
echo_cyan => "Clean up"
cp /tmp/dynomite/src/dynomite "$(pwd)/dynomite"
rm -r /tmp/dynomite
