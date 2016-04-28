#!/bin/bash

# Number of PVs to create
max=200

# PV Size
pvsize="101M"

# NFS Server FQDN
nfsserver="inf00-mwl.opentlc.com"

# Path to NFS shares
pvnfspath="/exports/pvs"

# Subnet for NFS ACL
subnet="192.168.0.0/16"

# NFS export share config file
nfsexport="/etc/exports.d/pvs.exports"

# Directory to store PV yaml files
pvdir="/root/pvdir"

###############################################

mkdir -p $pvdir $pvnfspath

if [ ! -f $nfsexport ]
then
	touch $nfsexport
fi

NFSCHANGE=0
x=1
while [ $x -le $max ]
do
	pv="pv$x"
	if [ ! -d $pvnfspath/$pv ]
	then
		echo "Creating dir $pvnfspath/$pv"
		mkdir -p $pvnfspath/$pv
		chmod 700 $pvnfspath/$pv
		chown nfsnobody:nfsnobody $pvnfspath/$pv
	fi
	grep "$pvnfspath/$pv" $nfsexport >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "Creating share $pvnfspath/$pv"
		echo "$pvnfspath/$pv $subnet(rw,sync,all_squash)" >> $nfsexport
		NFSCHANGE=1
	fi
	((x=$x+1))
done

if [ $NFSCHANGE == 1 ]
then
	systemctl reload nfs
fi

x=1
while [ $x -le $max ]
do
	pv="pv$x"
	out=`oc get pv $pv|egrep 'Bound|Available' 2>/dev/null`
	if [ $? -ne 0 -o -z "$out" ]
	then
		echo "Creating PV $pv"
                if [ -z "$out" ]
                then
                    oc delete pv $pv 2>/dev/null
                fi
		/bin/cat << EOF > $pvdir/$pv.yaml
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "$pv"
  },
  "spec": {
    "capacity": {
        "storage": "$pvsize"
        },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "$pvnfspath/$pv",
        "server": "$nfsserver"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
		oc create -f $pvdir/$pv.yaml
	fi
	((x=$x+1))
done

