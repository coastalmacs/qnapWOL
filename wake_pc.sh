#!/bin/sh
CONF="/etc/config/qpkg.conf"
QPKG_NAME="WakePC"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f $CONF`

# Configure your desktop PC's MAC address and broadcast IP
TARGET_MAC="30:56:0F:3D:19:00"
BROADCAST_IP="192.168.1.255"
SUBNET_IP="192.168.1.255"

send_packet()
{
    SENT=0

    # 1. Try Python 3 or Python 2 (guaranteed raw UDP broadcast support)
    PYTHON_BIN=""
    if which python3 >/dev/null 2>&1; then
        PYTHON_BIN=$(which python3)
    elif which python >/dev/null 2>&1; then
        PYTHON_BIN=$(which python)
    elif [ -x "/mnt/ext/opt/Python3/bin/python3" ]; then
        PYTHON_BIN="/mnt/ext/opt/Python3/bin/python3"
    fi

    if [ -n "$PYTHON_BIN" ]; then
        $PYTHON_BIN -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); data=bytes.fromhex('FFFFFFFFFFFF' + '$TARGET_MAC'.replace(':', '').replace('-', '') * 16); [s.sendto(data, (ip, p)) for ip in ['$BROADCAST_IP', '$SUBNET_IP'] for p in [9, 7]]; s.close()" 2>/dev/null && SENT=1
    fi

    # 2. Try PHP script if Python was not available
    if [ "$SENT" -ne 1 ]; then
        PHP_BIN=""
        if [ -x "/usr/local/apache/bin/php" ]; then
            PHP_BIN="/usr/local/apache/bin/php"
        elif [ -x "/mnt/ext/opt/apache/bin/php" ]; then
            PHP_BIN="/mnt/ext/opt/apache/bin/php"
        elif which php >/dev/null 2>&1; then
            PHP_BIN=$(which php)
        fi

        if [ -n "$PHP_BIN" ] && [ -f "$QPKG_ROOT/wol.php" ]; then
            $PHP_BIN "$QPKG_ROOT/wol.php" "$TARGET_MAC" "$BROADCAST_IP" && SENT=1
        fi
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