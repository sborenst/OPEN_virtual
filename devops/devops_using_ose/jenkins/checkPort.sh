function checkRemotePort() {
    (echo >/dev/tcp/$1/$2) &>/dev/null
    if [ $? -eq 0 ]; then
        echo -en "\n$1:$2 is open.\n"
    else
        echo -en "\n$1:$2 is closed.\n"
        exit 1;
    fi
}

checkRemotePort $1 $2
