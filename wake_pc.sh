#!/bin/sh
CONF="/etc/config/qpkg.conf"

# Desktop MAC address and directed subnet broadcast IP
TARGET_MAC="30560F3D1900"
BROADCAST_IP="192.168.1.255"

send_packet()
{
    python -c "import socket, binascii; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); data=b'\xff'*6 + binascii.unhexlify('$TARGET_MAC')*16; s.sendto(data, ('$BROADCAST_IP', 9)); s.sendto(data, ('$BROADCAST_IP', 7)); s.sendto(data, ('255.255.255.255', 9)); s.close(); print('Magic packet sent to $TARGET_MAC via $BROADCAST_IP')"

    # Automatically toggle switch back to OFF in App Center after 2 seconds
    ( sleep 2 && /sbin/setcfg WakePC Enable FALSE -f "$CONF" ) >/dev/null 2>&1 &
}

case "$1" in
    start|stop|restart)
        send_packet
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0