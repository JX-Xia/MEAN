function [fileInfoTmp] = Case2_selectFileFunc(taskID,taskNum,fileInfo,uniChunk,storageChunks,capacityLeft,storageChunksAll)
% Cluster in parallel to select k files with minimum Jaccard distance

if nargin < 7
    storageChunksAll = storageChunks;
end

% The file_index start position of the subtask
subTask_start = floor(size(fileInfo,1)/taskNum)*(taskID-1) + 1;
% The end position of the subtask
if taskID == taskNum
    subTask_end = size(fileInfo,1);
else
    subTask_end = floor(size(fileInfo,1)/taskNum) * taskID;
end
    
% This subtask considers only part of the data of fileInfo
fileInfoTmp = fileInfo(subTask_start : subTask_end, :);
for i = 1 : size(fileInfoTmp,1)
    if fileInfoTmp.select(i) == false
        selectChunk = fileInfoTmp.chunk{i};
        Locb = selectChunk.chunkID;
        
        deltaSize = sum(uniChunk.size(Locb(storageChunksAll(Locb) == false)));

        if nargin < 7
            storageSize = deltaSize;
        else
            storageSize = sum(uniChunk.size(Locb(storageChunks(Locb) == false)));
        end

        % Check that the remaining space is sufficient to store the file
        if capacityLeft >= storageSize
            fileInfoTmp.heatDsize(i) = fileInfoTmp.heat(i)/deltaSize;
        else
            fileInfoTmp.heatDsize(i) = 0;
            % The file is marked so that the while loop of Case1_selectFile can determine it
            fileInfoTmp.select(i) = true;
        end
    else
        % If it is marked, set its heatDsize to 0
        fileInfoTmp.heatDsize(i) = 0;
    end

end





end

