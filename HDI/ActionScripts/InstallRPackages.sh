#!/usr/bin/env bash

#usage - ./InstallRPackages <package1> <package2> <package3> ...
#example - ./InstallRPackages useCRAN bitops stringr arules

sed "s;CXX1X =;CXX1X = gcc -std=c++0x;g" Makeconf
sed "s;CXX1XSTD =;CXX1XSTD = -std=c++0x -fPIC;g" Makeconf

echo "Sample action script to install R packages..."

REPO=

if [ -f /usr/bin/R ]
then

        #loop through the parameters (i.e. packages to install)
        for i in "$@"; do
                if [ -z $name ]
                then
                        if [ "$i" == "useCRAN" ]
                        then
                                REPO="http://cran.us.r-project.org"
                        else
                                name=\'$i\'
                        fi

                else
                        name=$name,\'$i\'
                fi
        done

        echo "Install packages..."

        if [ -z $REPO ]
        then
                R --no-save -q -e "install.packages(c($name))"
        else
                R --no-save -q -e "install.packages(c($name), repos='$REPO')"
        fi

else
        echo "R not installed"
        exit 1
fi

echo "Finished"

