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
$broadcastIp = isset($argv[2]) ? $argv[2] : '255.255.255.255';
$port = 9;

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

// Broadcast packet across the local network using UDP sockets
if (function_exists('socket_create'))
{
    $socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
    if ($socket)
    {
        socket_set_option($socket, SOL_SOCKET, SO_BROADCAST, 1);
        socket_sendto($socket, $magicPacket, strlen($magicPacket), 0, $broadcastIp, $port);
        socket_close($socket);
        echo "Magic packet sent to {$targetMac} via {$broadcastIp}:{$port}\n";
        exit(0);
    }
}

// Fallback to stream socket if the sockets extension is disabled
$context = stream_context_create
(
    [
        'socket' => [
            'so_broadcast' => true
        ]
    ]
);

$stream = @stream_socket_client("udp://{$broadcastIp}:{$port}", $errno, $errstr, 2, STREAM_CLIENT_ASYNC_CONNECT, $context);
if ($stream)
{
    fwrite($stream, $magicPacket);
    fclose($stream);
    echo "Magic packet sent to {$targetMac} via {$broadcastIp}:{$port}\n";
    exit(0);
}

echo "Error: Failed to open UDP broadcast socket.\n";
exit(1);
?>
