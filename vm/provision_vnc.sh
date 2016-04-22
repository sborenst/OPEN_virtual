#!/bin/bash

myuser="jboss"
vncpass="jb0ssredhat!"
guacd_name="guacd"
guac_version="0.9.9"
hostname=`hostname`
path_to_guac_war="/root/guacamole-$guac_version.war"

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

    systemctl enable vncserver@:1.service
    systemctl start vncserver@:1.service
}

function provisionGuacd() {

    echo -en "\nprovisionGuacd() ...\n"

    dnf install -y docker
    systemctl start docker.service
    systemctl enable docker.service
    docker run --name $guacd_name --restart=on-failure:5 -d -p 4822:4822 glyptodon/guacd
}

function provisionGuacamole() {

    # https://deviantengineer.com/2015/02/guacamole-centos7/

    echo -en "\nprovisionGuacamole() ...\n"
    dnf install -y tomcat tomcat-webapps
    mkdir -p /etc/guacamole/ /var/lib/guacamole /usr/share/tomcat/.guacamole

    cp $path_to_guac_war /var/lib/guacamole/guacamole.war
    ln -sf /var/lib/guacamole/guacamole.war /var/lib/tomcat/webapps/

    printf '%s\n' "$guac_props" > /etc/guacamole/guacamole.properties
    printf '%s\n' "$guac_user_mapping" > /etc/guacamole/user-mapping.xml
    ln -sf /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/
    chown -R tomcat:tomcat /usr/share/tomcat/.guacamole

    systemctl start tomcat.service
    systemctl enable tomcat.service
}

function provisionHttpd() {
    echo -en "\nprovisionHttpd() ...\n"
}

provisionTigerVNC
provisionGuacd
provisionGuacamole
#provisionHttpd
