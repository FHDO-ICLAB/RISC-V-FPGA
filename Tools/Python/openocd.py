# Taken from the official OpenOCD Python example, 
# https://sourceforge.net/p/openocd/code/ci/master/tree/contrib/rpc_examples/ocd_rpc_example.py

import socket

class OpenOcd:

    COMMAND_TOKEN = '\x1a'

    def __init__(self, verbose=False):
        self.verbose = verbose
        self.tclRpcIp       = "127.0.0.1"
        #self.tclRpcIp       = "10.3.34.44" For remote connection (IPv4 Address).
        self.tclRpcPort     = 6666
        self.bufferSize     = 4096

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, type, value, traceback):
        self.disconnect()

    def connect(self):
        self.sock.connect((self.tclRpcIp, self.tclRpcPort))

    def disconnect(self):
        try:
            self.send("exit")
        finally:
            self.sock.close()

    def send(self, cmd):
        """Send a command string to TCL RPC. Return the result that was read."""
        data = (cmd + OpenOcd.COMMAND_TOKEN).encode("utf-8")
        if self.verbose:
            print("<- ", data)

        self.sock.send(data)
        return self._recv()

    def _recv(self):
        """Read from the stream until the token (\x1a) was received."""
        data = bytes()
        while True:
            chunk = self.sock.recv(self.bufferSize)
            data += chunk
            if bytes(OpenOcd.COMMAND_TOKEN, encoding="utf-8") in chunk:
                break

        if self.verbose:
            print("-> ", data)

        data = data.decode("utf-8").strip()
        data = data[:-1] # strip trailing \x1a

        return data

    def readVariable(self, address):
        raw = self.send("mdw 0x%x" % address).split(": ")
        return None if (len(raw) < 2) else self.strToHex(raw[1])

    def readMemory(self, wordLen, address, n):
        self.send("array unset output") # better to clear the array before
        self.send("mem2array output %d 0x%x %d" % (wordLen, address, n))

        output = [*map(int, self.send("return $output").split(" "))]
        d = dict([tuple(output[i:i + 2]) for i in range(0, len(output), 2)])

        return [d[k] for k in sorted(d.keys())]

    def writeVariable(self, address, value):
        assert value is not None
        self.send("mww 0x%x 0x%x" % (address, value))

    def writeMemory(self, wordLen, address, n, data):
        array = " ".join(["%d 0x%x" % (a, b) for a, b in enumerate(data)])

        self.send("array unset 1986ве1т") # better to clear the array before
        self.send("array set 1986ве1т { %s }" % array)
        self.send("array2mem 1986ве1т 0x%x %s %d" % (wordLen, address, n))

    @classmethod
    def strToHex(cls, data):
        return map(cls.strToHex, data) if isinstance(data, list) else int(data, 16)
