#!/bin/sh

rm -f *.tar.gz
rm -f *.par
rm -f *.ppd
./Build distclean
perl Build.PL
./Build install
perldoc REST::Resource >  README
perldoc REST::Request  >> README
perldoc eg/parts.cgi   >> README
./Build dist
./Build ppmdist
./Build pardist
cp *.tar.gz ..
cp *.par ..
cp *.ppd ..
bin/testcoverage.sh
