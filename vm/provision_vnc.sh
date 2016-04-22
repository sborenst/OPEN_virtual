#!/bin/bash

# Purpose:
#   Provision a Fedora 23 OS using LXDE window manager with tools needed to allow for remote desktop access using any HTML5 enabled browser
#
# Tools installed and configured by this script:
#   1) tigervnc-server
#   2) docker
#   3) guacd (server)
#   4) guacamole (web app)
#   5) nginx

myuser="jboss"
vncpass="jb0ssredhat!"
guacd_name="guacd"
guac_version="0.9.9"
hostname=`hostname`

lxde_monitor="#!/bin/sh
# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
# exec /etc/X11/xinit/xinitrc
#
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb \$HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
x-terminal-emulator -geometry 80x24+10+10 -ls -title \"\$VNCDESKTOP Desktop\" &
startlxde &"

guac_props="guacd-hostname: localhost
guacd-port:    4822
user-mapping:    /etc/guacamole/user-mapping.xml
auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping:    /etc/guacamole/user-mapping.xml"

guac_user_mapping="<user-mapping>
    
    <!-- Per-user authentication and config information -->
    <authorize username=\"$myuser\" password=\"$vncpass\">
        <protocol>vnc</protocol>
        <param name=\"hostname\">$hostname</param>
        <param name=\"port\">5901</param>
        <param name=\"password\">$vncpass</param>
    </authorize>
</user-mapping>"

nginx_location_config="location /guacamole/ {
    proxy_pass http://$hostname:8080/guacamole/;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    access_log off;
}"


function provisionTigerVNC() {

    # http://linoxide.com/linux-how-to/configure-tigervnc-server-fedora-22/

    echo -en "\nprovisionTigerVNC() ...\n"

    dnf install -y tigervnc-server.x86_64
    cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
    sed -i "s/<USER>/$myuser/" /etc/systemd/system/vncserver@:1.service
    systemctl daemon-reload
    mkdir -p /home/$myuser/.vnc
    echo $vncpass | vncpasswd -f > /home/$myuser/.vnc/passwd
    printf '%s\n' "$lxde_monitor" > /home/$myuser/.vnc/xstartup
    chown -R $myuser:$myuser /home/$myuser/.vnc
    chmod -R 755 /home/$myuser/.vnc
    chmod 0600 /home/$myuser/.vnc/passwd

    if [ "`systemctl is-active vncserver@:1.service`" != "active" ]
    then
        systemctl enable vncserver@:1.service
        systemctl start vncserver@:1.service
    fi
    echo "status of vncserver@:1.service is: `systemctl is-active vncserver@:1.service`"
}

function provisionGuacd() {

    echo -en "\nprovisionGuacd() ...\n"

    dnf install -y docker
    if [ "`systemctl is-active docker.service`" != "active" ]
    then
        systemctl start docker.service
        systemctl enable docker.service
        docker run --name $guacd_name --restart=on-failure:5 -d -p 4822:4822 glyptodon/guacd
    fi
    echo "status of docker is: `systemctl is-active docker.service`"
}

function provisionGuacamole() {

    # https://deviantengineer.com/2015/02/guacamole-centos7/

    echo -en "\nprovisionGuacamole() ...\n"
    dnf install -y tomcat tomcat-webapps

    path_to_guac_war="/root/guacamole-$guac_version.war"
    path_to_guac_auth_ldap="/root/guacamole-$guac_version.tar.gz"

    if [ ! -f $path_to_guac_war ]; then
        wget http://sourceforge.net/projects/guacamole/files/current/binary/guacamole-$guac_version.war -O $path_to_guac_war
        wget http://sourceforge.net/projects/guacamole/files/current/extensions/guacamole-auth-ldap-$guac_version.tar.gz $path_to_guac_auth_ldap
    fi

    mkdir -p /etc/guacamole/ /var/lib/guacamole /usr/share/tomcat/.guacamole

    cp $path_to_guac_war /var/lib/guacamole/guacamole.war
    ln -sf /var/lib/guacamole/guacamole.war /var/lib/tomcat/webapps/

    printf '%s\n' "$guac_props" > /etc/guacamole/guacamole.properties
    printf '%s\n' "$guac_user_mapping" > /etc/guacamole/user-mapping.xml
    ln -sf /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/
    chown -R tomcat:tomcat /usr/share/tomcat/.guacamole

    if [ "`systemctl is-active tomcat.service`" != "active" ]
    then
        systemctl start tomcat.service
        systemctl enable tomcat.service
    fi
    echo "status of tomcat is: `systemctl is-active tomcat.service`"
}

function provisionNginx() {
    echo -en "\nprovisionNginx() ...\n"
    dnf install -y nginx
    printf '%s\n' "$nginx_location_config" > /etc/nginx/default.d/guacamole.conf
    if [ "`systemctl is-active nginx.service`" != "active" ]
    then
        systemctl start nginx.service
        systemctl enable nginx.service
    fi
    echo "status of nginx is: `systemctl is-active nginx.service`"
}

function provisionNginxWithKerberos() {
    wget http://nginx.org/download/nginx-1.9.15.tar.gz
    tar -zxvf nginx-1.9.15.tar.gz
    cd nginx-1.9.15
    git clone https://github.com/stnoonan/spnego-http-auth-nginx-module.git
    dnf groupinstall "Development Tools"
    dnf install pcre-devel zlib-devel heimdal-devel krb5-devel
    make install

    mkdir -r /usrc/local/nginx/default.d
    printf '%s\n' "$nginx_location_config" > /etc/nginx/default.d/guacamole.conf

    cp nginx.service /usr/lib/systemd/system/nginx.service
    if [ "`systemctl is-active nginx.service`" != "active" ]
    then
        systemctl start nginx.service
        systemctl enable nginx.service
    fi
    echo "status of nginx is: `systemctl is-active nginx.service`"
}

provisionTigerVNC
provisionGuacd
provisionGuacamole
#provisionNginx
provisionNginxWithKerberos
