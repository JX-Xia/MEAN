function [resultD] = deltaP_Paral(tID,para_Num,fileInfo,serverInfo,uniChunk,storageChunksAll,ii,fileTable)
% Two deltaP computation tasks are executed in parallel

if tID == 1
    % deltaP is computed for the fileInfo table
    fileInfo.deltaP = zeros(size(fileInfo,1),1);
    % Calculate deltaP in parallel
    fileInfoTmp = cell(para_Num,1);
    parfor taskID = 1:para_Num
        [fileInfoTmp{taskID}] = deltaP_forDedupHet(taskID,para_Num,fileInfo,serverInfo,uniChunk,storageChunksAll,ii);
    end
    % Combine the results
    fileInfo = fileInfoTmp{1};
    for taskID = 2:para_Num
        fileInfo = [fileInfo;fileInfoTmp{taskID}];
    end

    resultD = fileInfo;
else
    % Calculate deltaP
    fileTable.deltaP =zeros(size(fileTable,1),1);
    fileTableTmp = cell(para_Num,1);
    parfor taskID = 1:para_Num
        [fileTableTmp{taskID}] = deltaP_forReplicaHet(taskID,para_Num,fileTable,serverInfo,ii);
    end
    % Combine the results
    fileTable = fileTableTmp{1};
    for taskID = 2:para_Num
        fileTable = [fileTable;fileTableTmp{taskID}];
    end

    resultD = fileTable;
end

end