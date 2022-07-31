#! /bin/sh

APPLICATIONS=("libmirage" "vhba-module" "cdemu-daemon" "cdemu-client" "gcdemu" "image-analyzer")

for APP in ${APPLICATIONS[@]}
do
	cd ${APP}
	../../buildrpm.sh $(pwd)
	cd -
done

../buildrpm.sh $(pwd)
