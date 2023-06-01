# -*- coding: utf-8 -*-
# Client
import random
import socket
import struct
from multiprocessing import Pool, Process, Manager
from scipy.io import loadmat
import time
import pickle
import pandas as pd
import copy
import pause
import numpy as np
import threading
import inspect
import ctypes
import argparse

socket_num = 128

fileNum = 200

delay = [0] * fileNum
thpt = [0] * fileNum

# Number of Server
serverNum = 10

chunkPath = 'rsv_chunks/chunk'


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


def load_variavle(filename):
    try:
        f = open(filename, 'rb')
        r = pickle.load(f)
        f.close()
        return r
    except EOFError:
        return ""


def reqChunks(_chunks_str, _serverID):
    if _serverID == 0:
        # if serverID is 0, request the cloud server
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # client_addr = ('10.0.0.11', 3010)
        # client.bind(client_addr)

        # IP of the could server
        client.connect(('0.0.0.0', 3008))
        # print('Cloud connection sucess!')
    else:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(('10.0.0.' + str(_serverID), 3008))

    # Send information
    d_size = struct.pack("l", len(bytes(_chunks_str.encode('utf-8'))))
    client.send(d_size)
    # print('d_size is '+str(len(bytes(_chunks_str.encode('utf-8')))))
    client.sendall(bytes(_chunks_str.encode('utf-8')))
    # print(_chunks_str)
    # print('Sent chunkList!')

    # Receive
    d = client.recv(struct.calcsize("l"))
    total_size = struct.unpack("l", d)[0]
    # print('File size is '+str(total_size))
    data = b''
    while True:
        data += client.recv(8192)
        if len(data) >= total_size:
            break
    # print('Received size is '+str(len(data)))

    with open(chunkPath, "wb") as f:
        f.write(data)
    f.close()

    client.close()
    # print('Received chunks!')


def paraRequest(_chunksGroup, _servers):
    pro_list = []
    for _j in range(len(_servers)):
        _chunks_str = str(_chunksGroup[_j])
        _serverID = _servers[_j]
        p = Process(target=reqChunks, args=(_chunks_str, _serverID,))
        p.start()
        pro_list.append(p)
    for p in pro_list:
        p.join()


def paraSocket(_chunksGroup, _servers, _file_size, _index, delay_list, thpt_list):
    _time1 = time.time()
    _chunks_list = []
    _servers_list = []
    _i = 0
    for _chunks in _chunksGroup:
        _num = 0
        _chunk_tmp = []
        for _j in range(len(_chunks)):
            _num = _num + 1
            _chunk_tmp.append(_chunks[_j])
            if _num == socket_num or _j == len(_chunks) - 1:
                _chunks_list.append(_chunk_tmp)
                # Update server list
                _servers_list.append(_servers[_i])
                # Init
                _num = 0
                _chunk_tmp = []
        _i = _i + 1
    paraRequest(_chunks_list, _servers_list)
    _time2 = time.time()

    # delay[_index] = _time2 - _time1
    # thpt[_index] = _file_size / 1024 / 1024 / delay[_index]

    delay_list[_index] = _time2 - _time1
    thpt_list[_index] = _file_size / 1024 / 1024 / delay_list[_index]

    if _servers[0] == 0:
        print("Got the file from the cloud server!")
        print('Cloud throughput is ' + str(thpt_list[_index]) + 'MB/s')
    else:
        print("Got the file from the edge server!")
        print('Edge throughput is ' + str(thpt_list[_index]) + 'MB/s')

    # delay = _time2 - _time1
    # thpt = _file_size / 1024 / 1024 / delay
    # results = (delay, thpt)
    # return results


def isFileAtEdge(_chunkServers, _availServers_index):
    _isEdge = 1
    for _chunkServer in _chunkServers:
        for _server in _chunkServer:
            if len(_server) == 0:
                _isEdge = 0
                return _isEdge
    if _isEdge == 1:
        for _chunkServer in _chunkServers:
            _availNum = _chunkServer.size
            for _server_index in range(_chunkServer.size):
                if _availServers_index[int(_chunkServer[0][_server_index]) - 1] == 0:
                    _availNum = _availNum - 1
            if _availNum == 0:
                _isEdge = 0
                return _isEdge
    return _isEdge


def kill_thread(threadList):
    for thread_index in len(threadList) - 10:
        stop_thread(threadList[thread_index])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--ids', type=str, default=1)
    args = parser.parse_args()
    ids = args.ids.split(',')
    # The available servers
    availServers = []
    for serverID in ids:
        availServers.append(int(serverID))
    # print(availServers)

    delayRst = []
    thptRst = []
    for ii in range(3):
        for ii0 in range(6):
            # capacity = 5 + ii0 * 5

            # Possion
            lam = 60 + 30 * ii0

            if ii == 0:
                results = loadmat("results/results1_MEAN.mat")
            if ii == 1:
                results = loadmat("results/results1_PopF.mat")
            if ii == 2:
                results = loadmat("results/results1_PopF_3R.mat")
            # if ii == 3:
                # results = loadmat("results/results1_Rnd.mat")

            delayTmp = []
            thptTmp = []
            for ij in range(10):
                # Import parameters
                test_path = 'tmp/'
                availServers = load_variavle(test_path + 'serverList-' + str(ij))

                # Cloud_only
                if ii == 4:
                    availServers = []

                print(availServers)
                pause.seconds(2)

                availServers_index = [0] * serverNum
                for availServerID in availServers:
                    availServers_index[availServerID - 1] = 1

                # Load results.mat
                chunk2server = results['chunk2server']
                chunkSize = results['chunkSize']
                file2chunk = results['file2chunk']
                fileHeat = results['fileHeat']
                # serverIndex = results['serverIndex']

                test_fileTmp = test_path + str(fileNum)

                pro_list = []
                # pool = Pool(processes=fileNum)
                manger = Manager()
                delay_list = manger.list(delay)
                thpt_list = manger.list(thpt)
                for jj in range(1):
                    test_file = test_fileTmp + '-' + str(jj)
                    fileList = load_variavle(test_file)

                    serverLoad = [float('inf')] * serverNum
                    for serverID in availServers:
                        serverLoad[serverID - 1] = 0

                    waiting_time = 0
                    total_thpt = 0
                    x_i = 0
                    x = np.random.poisson(lam, 1)
                    x_pause = 60 / x
                    for i in range(fileNum):
                        file_index = int(fileList[i])

                        x_i = x_i + 1
                        if x_i <= x:
                            pause.seconds(float(x_pause))
                        else:
                            x_i = 0
                            x = np.random.poisson(lam, 1)
                            # Number of requests in one minute
                            x_pause = 60 / x

                        chunks = file2chunk[file_index][0]
                        chunkServers = []
                        chunkList = []
                        file_size = 0
                        for chunkID in chunks:
                            file_size = file_size + int(chunkSize[int(chunkID) - 1][0])
                            chunkServers.append(chunk2server[int(chunkID) - 1][0])
                            chunkList.append(int(chunkID))

                        isEdge = isFileAtEdge(chunkServers, availServers_index)
                        if isEdge == 0:
                            cloud_server = [0]
                            cloud_chunk_list = [chunkList]
                            # Request the file from the cloud

                            # t_recv = threading.Thread(target=paraSocket, args=(cloud_chunk_list, cloud_server, file_size, i))
                            # t_recv.start()

                            p = Process(target=paraSocket,
                                        args=(cloud_chunk_list, cloud_server, file_size, i, delay_list, thpt_list,))
                            p.start()

                            # p = pool.apply_async(paraSocket, args=(cloud_chunk_list, cloud_server, file_size, i,))

                            pro_list.append(p)

                        else:
                            # Request the file from the edge server
                            matchServers = []
                            for chunkServer in chunkServers:
                                serverLoadTmp = []
                                for j in range(chunkServer.size):
                                    serverLoadTmp.append(serverLoad[int(chunkServer[0][j]) - 1])
                                server_index = serverLoadTmp.index(min(serverLoadTmp))
                                serverID = int(chunkServer[0][server_index])
                                matchServers.append(serverID)

                                chunkID = int(chunks[len(matchServers) - 1])
                                serverLoad[serverID - 1] = serverLoad[serverID - 1] + int(chunkSize[chunkID - 1][0])

                            servers = []
                            chunksGroup = []
                            j = 0
                            for serverID in matchServers:
                                if serverID in servers:
                                    server_index = servers.index(serverID)
                                    chunksGroup[server_index].append(chunkList[j])
                                else:
                                    servers.append(serverID)
                                    chunksGroup.append([])
                                    chunksGroup[len(chunksGroup) - 1].append(chunkList[j])
                                j = j + 1

                            # t_recv = threading.Thread(target=paraSocket, args=(chunksGroup, servers, file_size, i))
                            # t_recv.start()

                            p = Process(target=paraSocket,
                                        args=(chunksGroup, servers, file_size, i, delay_list, thpt_list,))
                            p.start()

                            # p = pool.apply_async(paraSocket, args=(chunksGroup, servers, file_size, i,))

                            pro_list.append(p)

                    for p in pro_list:
                        p.join()

                    pause.seconds(5)
                    # print(delay_list)
                    delayTmp.append(sum(list(delay_list)) / len(list(delay_list)))
                    thptTmp.append(sum(list(thpt_list)) / len(list(thpt_list)))
                    print('Start a new round ...')

            delayRst.append(sum(delayTmp) / len(delayTmp))
            thptRst.append(sum(thptTmp) / len(thptTmp))
        # Mark
        delayRst.append(0)
        thptRst.append(0)

    df = pd.DataFrame(thptRst)
    df.to_excel("output/thpt.xlsx", index=False)

    df = pd.DataFrame(delayRst)
    df.to_excel("output/delay.xlsx", index=False)
    print('Finish!')
