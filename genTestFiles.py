# -*- coding: utf-8 -*-
"""
This script generates test files for "SimpleTest-HitRatio.py".
After running "Test_Scenario2and3.m", the script is used to perform a simple test of the results,
comparing the hit rates of different methods.

By generating multiple test files, different methods can be compared under the same conditions.
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
# Reliability of management nodes
ManageNode_reliability = 1.0
ManageNodeNum = 1
# Load the results
results = loadmat("results/results1_MEAN.mat")
# results = loadmat("results/results_MEAN.mat")

def save_variable(v, filename):
    f = open(filename, 'wb')
    pickle.dump(v, f)
    f.close()
    return filename


if __name__ == '__main__':
    # Load results
    fileHeat = results['fileHeat']
    reliability = results['reliability']

    test_path = 'tmp/'

    # According to the probability of server reliability, a list of available servers is produced
    for ii in range(100):
        serverList = []
        for i in range(reliability.size):
            p = random.random()
            if reliability[i][0] >= p:
                serverID = i + 1
                serverList.append(serverID)
        save_variable(serverList, test_path + 'serverList-' + str(ii))

        p = random.random()
        if p <= ManageNode_reliability:
            ManageNode = 1
        else:
            ManageNode = 0
        save_variable(ManageNode, test_path + 'ManageNode-' + str(ii))

        # The case where there are multiple management nodes
        ManageNodeList = []
        for i in range(ManageNodeNum):
            p = random.random()
            if p <= ManageNode_reliability:
                ManageNode = 1
            else:
                ManageNode = 0
            ManageNodeList.append(ManageNode)
        save_variable(ManageNodeList, test_path + 'MultiManageNode-' + str(ii))

    # Generate test files array
    for ii in range(1):
        fileNum = 1000 + 1000 * ii
        for jj in range(5):
            # Select the required number of fileNum files according to the file popularity
            heatAccum = [0] * fileHeat.size
            heatAccum[0] = int(fileHeat[0][0])
            for i in range(1, fileHeat.size):
                heatAccum[i] = heatAccum[i - 1] + int(fileHeat[i][0])
            heatAcum_end = heatAccum[len(heatAccum) - 1]

            # Generate a list of requested files based on their popularity values
            fileList = []
            for i in range(fileNum):
                randNum = random.randint(1, heatAcum_end)
                file_index = 0
                flag = 1
                while flag:
                    if randNum > heatAccum[file_index]:
                        file_index = file_index + 1
                    else:
                        flag = 0
                fileList.append(file_index)
            # Save fileList
            filename = test_path + str(fileNum) + '-' + str(jj)
            save_variable(fileList, filename)
    print('All fileLists saved!')
