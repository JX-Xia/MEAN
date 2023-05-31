function [fileInfoTmp] = Case1_selectFileFunc(taskID,para_Num,fileInfo,uniChunk,storageChunks,capacityLeft)
% Selects k files with minimum Jaccard distance in parallel

% The file_index start position of this subtask
subTask_start = floor(size(fileInfo,1)/para_Num)*(taskID-1) + 1;
% End position
if taskID == para_Num
    subTask_end = size(fileInfo,1);
else
    subTask_end = floor(size(fileInfo,1)/para_Num) * taskID;
end

fileInfoTmp = fileInfo(subTask_start : subTask_end, :);
for i = 1 : size(fileInfoTmp,1)
    if fileInfoTmp.select(i) == false
        selectChunk = fileInfoTmp.chunk{i};
        Locb = selectChunk.chunkID;
        
        deltaSize = sum(uniChunk.size(setdiff(Locb,storageChunks)));
        
        if capacityLeft >= deltaSize
            fileInfoTmp.heatDsize(i) = fileInfoTmp.heat(i)/deltaSize;
        else
            fileInfoTmp.heatDsize(i) = 0;
            fileInfoTmp.select(i) = true;
        end
    else
        fileInfoTmp.heatDsize(i) = 0;
    end

end





end

