# -*- coding: utf-8 -*-
# Server
import socket
import struct
import os
from scipy.io import loadmat
import argparse
import threading
import inspect
import ctypes
from multiprocessing import Process

# Path of chunks
chunkpath = 'chunks/chunk'
# Load results
results = loadmat("results/results1_MEAN.mat")


def _async_raise(tid, exctype):
    """raises the exception, performs cleanup if needed"""
    tid = ctypes.c_long(tid)
    if not inspect.isclass(exctype):
        exctype = type(exctype)
    res = ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, ctypes.py_object(exctype))
    if res == 0:
        raise ValueError("invalid thread id")
    elif res != 1:
        # """if it returns a number greater than one, you're in trouble,
        # and you should call it again with exc=NULL to revert the effect"""
        ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, None)
        raise SystemError("PyThreadState_SetAsyncExc failed")
def stop_thread(thread):
    _async_raise(thread.ident, SystemExit)


def createfile(filename, _size):
    with open(filename, 'wb') as _f:
        _f.seek(_size - 1)
        _f.write(b'\x00')


def server_accept(sock, adddr):
    d = sock.recv(struct.calcsize("l"))
    chunkList_size = struct.unpack("l", d)[0]

    data = b''
    while True:
        data += sock.recv(8192)
        if len(data) >= chunkList_size:
            break
    # print(len(data))
    data = data.decode('utf-8')
    data = data.strip('[').strip(']').split(',')
    # chunkList
    chunkList = []
    for d in data:
        chunkList.append(int(d))

    log_data = b''
    for chunkID in chunkList:
        fl = open(chunkpath + str(chunkID))
        f = fl.read()
        log_data += f.encode("utf-8")
        fl.close()

    f_size = struct.pack("l", len(log_data))
    sock.send(f_size)

    sock.sendall(log_data)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--id', type=int, default=1)
    parser.add_argument('--start', type=int, default=0)
    args = parser.parse_args()
    # Server ID
    serverID = args.id
    # Load test files
    # chunk2server = results['chunk2server']
    chunkSize = results['chunkSize']
    # file2chunk = results['file2chunk']
    # fileHeat = results['fileHeat']
    serverIndex = results['serverIndex']

    # chunkpath = 'h' + str(serverID) + '_' + chunkpath

    if args.start == 0:
        server_index = serverID - 1
        storage_chunks = serverIndex[server_index, 0]
        for chunk_index in storage_chunks:
            size = int(chunkSize[chunk_index, 0])
            # Generate simulation files
            chunkID = int(chunk_index)
            createfile(chunkpath + str(chunkID), size)
        print('Server h' + str(serverID) + '\'s chunks generated!')

    '''
    if args.start == 0
        for chunk_index in range(chunkSize.size):
            size = int(chunkSize[chunk_index, 0])
            # Gen simulation files
            chunkID = chunk_index + 1
            createfile(chunkpath + str(chunkID), size)
        print('Server h' + str(serverID) + '\'s chunks generated!')

    if args.start == 0:
        for i in range(chunkSize.size):
            chunk_index = i
            server_index = serverID - 1
            if serverIndex[chunk_index, server_index] == 1:
                size = int(chunkSize[chunk_index, 0])
                # Generate simulation files
                chunkID = chunk_index + 1
                createfile(chunkpath + str(chunkID), size)
        print('Server h' + str(serverID) + '\'s chunks generated!')
    '''

    if args.start == 1:
        # Start
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # server_IP = socket.gethostbyname(socket.gethostname())
        # Note: IP of servers should be modified
        server_IP = '10.0.0.' + str(serverID)
        print('Start server ' + str(server_IP))
        server_addr = (server_IP, 3008)
        server.bind(server_addr)

        server.listen(10000)
        i = 0
        while True:

            # print("start.......")
            sock, adddr = server.accept()
            # server_accept(sock, adddr)
            # t_recv = threading.Thread(target=server_accept, args=(sock, adddr))
            # t_recv.start()
            p = Process(target=server_accept, args=(sock, adddr,))
            p.start()

            


