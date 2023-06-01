# -*- coding: utf-8 -*-
"""
This is a simple test of the results to evaluate the hit ratio of methods.
We need to generate a test file by running "SimpleTest-genTestFiles.py" and then run this script
The results are output to the "hitRatio.xls"
"""

import random
import socket
import struct
from multiprocessing import Process
from scipy.io import loadmat
import pandas as pd
import time
import pickle
import argparse

# The number of servers
serverNum = 10


def load_variavle(filename):
    try:
        f = open(filename, 'rb')
        r = pickle.load(f)
        f.close()
        return r
    except EOFError:
        return ""


def isFileAtEdge(_chunkServers, _availServers_index):
    # Check, if any chunk is not stored, and if so, the file is fetched from cloud
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


if __name__ == '__main__':
    test_path = 'tmp/'
    # The number of failure modes
    failureNum = 10
    # The number of retrieval requests
    fileNum = 1000

    # Number of tests for each number of requests
    testNum = 1

    hitRatioRst = []
    # A different method is computed each time through the loop
    for ii in range(3):
        if ii == 0:
            # MEAN
            results = loadmat("results/results1_MEAN.mat")
            # results = loadmat("results/results_MEAN.mat")
        if ii == 1:
            # PopF
            results = loadmat("results/results1_PopF.mat")
            # results = loadmat("results/results_PopF.mat")
        if ii == 2:
            # PopF_3R
            results = loadmat("results/results1_PopF_3R.mat")
            # results = loadmat("results/results_PopF_3R.mat")
        # if ii == 3:
            # Naive
            # results = loadmat("results/results1_Rnd.mat")
            # results = loadmat("results/results_Rnd.mat")

        if ii <= 3:
            # Load
            chunk2server = results['chunk2server']
            chunkSize = results['chunkSize']
            file2chunk = results['file2chunk']

            # Generate test files array
            test_fileTmp = test_path + str(fileNum)

            # Used to record the hitRatio for each time
            hitRatioList = []
            for iii in range(failureNum):
                # According to the probability of server reliability, a list of available servers is produced
                availServers = load_variavle(test_path + 'serverList-' + str(iii))

                availServers_index = [0] * serverNum
                for availServerID in availServers:
                    availServers_index[availServerID - 1] = 1

                # Multiple tests
                for jj in range(testNum):
                    hitNum = 0
                    test_file = test_fileTmp + '-' + str(jj)
                    fileList = load_variavle(test_file)

                    for i in range(fileNum):
                        file_index = fileList[i]
                        chunks = file2chunk[file_index][0]
                        chunkServers = []
                        chunkList = []
                        file_size = 0
                        for chunkID in chunks:
                            file_size = file_size + int(chunkSize[int(chunkID) - 1][0])
                            chunkServers.append(chunk2server[int(chunkID) - 1][0])
                            chunkList.append(int(chunkID))

                        isEdge = isFileAtEdge(chunkServers, availServers_index)
                        if isEdge == 1:
                            hitNum = hitNum + 1

                    hitRatio = hitNum / fileNum
                    # print('Hit ratio:' + str(hitRatio))
                    hitRatioList.append(hitRatio)

        print('Finish the ' + str(ii) + '-th sub-round!')
        # Record the results
        hitRatioRst.append(sum(hitRatioList) / len(hitRatioList))

        print('Method ' + str(ii) + '\'s hit ratio is ' + str(sum(hitRatioList) / len(hitRatioList)))

    print('Finish calculation!')
    df = pd.DataFrame(hitRatioRst)
    df.to_excel("results/hitRatio.xlsx", index=False)
