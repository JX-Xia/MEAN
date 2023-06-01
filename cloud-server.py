# -*- coding: utf-8 -*-
# Cloud-server
import socket
import struct
import os
from scipy.io import loadmat
import argparse
from multiprocessing import Process
import threading

# path of chunks
chunkpath = 'chunks/chunk'
# Load the test file
results = loadmat("results/results1_MEAN.mat")


def createfile(filename, _size):
    with open(filename, 'wb') as _f:
        _f.seek(_size - 1)
        _f.write(b'\x00')

def server_accept(sock, adddr):
    d = sock.recv(struct.calcsize("l"))
    chunkList_size = struct.unpack("l", d)[0]

    # Prepare buffer
    data = b''
    while True:
        data += sock.recv(8192)
        if len(data) >= chunkList_size:
            break
    data = data.decode('utf-8')
    data = data.strip('[').strip(']').split(',')
    # chunkList
    chunkList = []
    for d in data:
        chunkList.append(int(d))
    # print(chunkList)

    log_data = b''
    for chunkID in chunkList:
        fl = open(chunkpath + str(chunkID))
        f = fl.read()
        log_data += f.encode("utf-8")
        fl.close()

    # Send the file size
    f_size = struct.pack("l", len(log_data))
    sock.send(f_size)
    # print('Sending files...')
    sock.sendall(log_data)
    # print('Finish!')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--start', type=int, default=0)
    args = parser.parse_args()
    serverID = 0

    chunkSize = results['chunkSize']

    chunkpath = 'h'+str(serverID)+'_'+chunkpath

    if args.start == 0:
        # Simulate files according to chunk size
        for chunk_index in range(chunkSize.size):
            size = int(chunkSize[chunk_index, 0])
            chunkID = chunk_index + 1
            createfile(chunkpath + str(chunkID), size)

    if args.start == 1:
        # Start server
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # server_IP = socket.gethostbyname(socket.gethostname())
        server_IP = '0.0.0.0'
        print('Start server ' + str(server_IP))
        server_addr = (server_IP, 3008)
        server.bind(server_addr)

        server.listen(100000)
        while True:
            # print("start.......")
            sock, adddr = server.accept()
            # server_accept(sock, adddr)
            # t_recv = threading.Thread(target=server_accept, args=(sock, adddr))
            # t_recv.start()

            p = Process(target=server_accept, args=(sock, adddr,))
            p.start()



            

