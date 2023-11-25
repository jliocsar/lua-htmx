cwd=$(pwd)

sudo apt install -y lua5.4 liblua5.4-dev

cd /tmp
wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz
tar zxpf luarocks-3.9.2.tar.gz
cd luarocks-3.9.2
./configure && make && sudo make install
cd $cwd

sudo luarocks install luv
