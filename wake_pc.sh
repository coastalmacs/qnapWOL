#!/bin/sh
CONF="/etc/config/qpkg.conf"
QPKG_NAME="WakePC"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f $CONF`

# Configure your desktop PC's MAC address and broadcast IP
TARGET_MAC="30:56:0F:3D:19:00"
BROADCAST_IP="255.255.255.255"

send_packet()
{
    PHP_BIN=""
    if [ -x "/usr/local/apache/bin/php" ]; then
        PHP_BIN="/usr/local/apache/bin/php"
    elif [ -x "/mnt/ext/opt/apache/bin/php" ]; then
        PHP_BIN="/mnt/ext/opt/apache/bin/php"
    elif which php >/dev/null 2>&1; then
        PHP_BIN=$(which php)
    fi

    if [ -n "$PHP_BIN" ] && [ -f "$QPKG_ROOT/wol.php" ]; then
        $PHP_BIN "$QPKG_ROOT/wol.php" "$TARGET_MAC" "$BROADCAST_IP"
    else
        # Fallback to python socket if PHP CLI is unreachable
        python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(bytes.fromhex('FFFFFFFFFFFF' + '$TARGET_MAC'.replace(':', '').replace('-', '') * 16), ('$BROADCAST_IP', 9)); s.close()"
    fi
}

case "$1" in
    start|stop)
        send_packet
        ;;
    restart)
        send_packet
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
