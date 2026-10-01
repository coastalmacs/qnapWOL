<?php
/**
 * Broadcasts a Wake-on-LAN magic packet to wake a target device on the LAN.
 */

if ($argc < 2)
{
    echo "Usage: php wol.php <MAC_ADDRESS> [BROADCAST_IP]\n";
    exit(1);
}

$targetMac = $argv[1];
$broadcastIps = ['255.255.255.255', '192.168.1.255'];

if (isset($argv[2]) && !in_array($argv[2], $broadcastIps))
{
    $broadcastIps[] = $argv[2];
}

// Normalize the MAC address by stripping common delimiters
$cleanedMac = preg_replace('/[^0-9A-Fa-f]/', '', $targetMac);
if (strlen($cleanedMac) !== 12)
{
    echo "Error: Invalid MAC address provided. Expected 12 hexadecimal characters.\n";
    exit(1);
}

// Assemble the standard 102-byte WOL magic packet
$binaryMac = pack('H*', $cleanedMac);
$magicPacket = str_repeat(chr(0xFF), 6) . str_repeat($binaryMac, 16);

// Method 1: Native PHP sockets extension
if (function_exists('socket_create'))
{
    $socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
    if ($socket)
    {
        socket_set_option($socket, SOL_SOCKET, SO_BROADCAST, 1);
        foreach ($broadcastIps as $ip)
        {
            socket_sendto($socket, $magicPacket, strlen($magicPacket), 0, $ip, 9);
            socket_sendto($socket, $magicPacket, strlen($magicPacket), 0, $ip, 7);
        }
        socket_close($socket);
        echo "Magic packet sent via PHP sockets to {$targetMac}.\n";
        exit(0);
    }
}

// Method 2: Python broadcast fallback if PHP sockets extension is disabled
$pythonCmd = 'python3 -c "import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); data=bytes.fromhex(\'FFFFFFFFFFFF\' + \'' . $cleanedMac . '\' * 16); [s.sendto(data, (ip, port)) for ip in [\'255.255.255.255\', \'192.168.1.255\'] for port in [9, 7]]; s.close()" 2>&1';

$output = [];
$returnCode = 0;
exec($pythonCmd, $output, $returnCode);

if ($returnCode === 0)
{
    echo "Magic packet sent via Python fallback to {$targetMac}.\n";
    exit(0);
}

echo "Error: Failed to broadcast UDP packet.\n";
exit(1);
?>