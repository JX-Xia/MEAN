function [selectID,heatDsize] = forCase2_storeDedupPart(para_Num,fileInfo,uniChunk,storageChunks,storageChunksAll,capacityLeft,partFilesLine)
% for Case2: The current file only stores the heatDsize of the deduplicated part, 
% and selects the one with the largest heat/deltasize, which has not been selected by the tag

% The calculated size increment is the portion that is not stored by either the previous server or the current server
storageChunksAll = union(storageChunks,storageChunksAll);

% Files in partFilesLine are marked as not selectable because they have already been saved
fileInfo.select(partFilesLine) = true;

% The new file stores only the parts that were not stored by the server before: look in the storageChunksAll 
% table to find the file with the largest heatDsize
fileInfoTmp = cell(para_Num,1);
for taskID = 1:para_Num
    % [fileInfoTmp{taskID}] = Case2_selectFileFunc(taskID,taskNum,fileInfo,uniChunk,storageChunks,capacityLeft,storageChunksAll);
    [fileInfoTmp{taskID}] = Case1_selectFileFunc(taskID,para_Num,fileInfo,uniChunk,storageChunksAll,capacityLeft);
end
% Combine the results
fileInfo = fileInfoTmp{1};
for taskID = 2:para_Num
    fileInfo = [fileInfo;fileInfoTmp{taskID}];
end

% heatDsize multiplied by the corresponding deltaP
fileInfo.heatDsize = fileInfo.heatDsize .* fileInfo.deltaP;

% Find the row with the largest heatDsize and store all its files and chunks
[heatDsize,I] = max(fileInfo.heatDsize);

% Check that the maximum value is not 0 (a 0 would mean that deltasize is greater 
% than the left space, so selectFileFunc sets them all to 0).
heatDsize = heatDsize(1);
if heatDsize ~= 0
    selectID = I(1);
else
    selectID = 0;
end



end

