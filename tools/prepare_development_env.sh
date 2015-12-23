#!/bin/bash

curl -kL http://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
perlbrew init
if ! grep -q "source ~/perl5/perlbrew/etc/bashrc" ~/.bashrc; then
	echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc
fi
if ! grep -q "source ~/perl5/perlbrew/etc/bashrc" ~/.bash_profile; then
	echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bash_profile
fi
perlbrew install perl-5.18.2 -Dusethreads --as threaded-perl-5.18.2
perlbrew lib create threaded-perl-5.18.2@vndrv
perlbrew use threaded-perl-5.18.2@vndrv
echo "N" | perlbrew install-cpanm
cpanm Carton
carton install --deployment
