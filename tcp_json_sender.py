#!/usr/bin/env python3

## usage: term1:  python tcp_json_sender.py 0135.json.txt 9000 0.016667

## term2: 

##var src = new TcpIpSignalSource("127.0.0.1", 9000, 60);   // Fs = 60 Hz
##while (true)
##{
##    var sample = await src.ReadNextAsync(ct);
##    if (!sample.HasValue) break;
##    Console.WriteLine(sample.Value);
##}
import json
import socket
import struct
import sys
import time

def main():
    if len(sys.argv) < 2:
        print("Usage: tcp_json_sender.py <file.json> [port=9000] [interval_sec=0.0]")
        sys.exit(1)

    json_path = sys.argv[1]
    port      = int(sys.argv[2]) if len(sys.argv) > 2 else 9000
    interval  = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0

    # ---- load JSON ----
    with open(json_path, "r", encoding="utf-8") as f:
        doc = json.load(f)
    values = doc["values"]          # list[float]
    print(f"Loaded {len(values)} samples from {json_path}")

    # ---- TCP server ----
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind(("127.0.0.1", port))
        srv.listen(1)
        print(f"Listening on {port}.  Connect with TcpIpSignalSource…")

        conn, addr = srv.accept()
        with conn:
            print("Client connected from", addr)
            for v in values:
                conn.sendall(struct.pack("d", v))
                if interval:
                    time.sleep(interval)
            print("All values sent – closing connection.")

if __name__ == "__main__":
    main()
