function [selectID,heatDsize] = forCase2Parallel(taskID,ii,para_Num,fileInfo,uniChunk,storageChunks,storageChunksAll,capacityLeft,partFilesLine,fileTable,serverInfo)

if taskID == 1
    % Case 1: Store the global deduplicated portion of a new file
    [selectID,heatDsize] = forCase2_storeDedupPart(para_Num,fileInfo,uniChunk,storageChunks,storageChunksAll,capacityLeft,partFilesLine);
end
if taskID == 2
    % Case 2: Store a copy of the complete file from the previous server to the current server
    [selectID,heatDsize] = forCase2_storeReplicaFile(para_Num,fileInfo,fileTable,uniChunk,storageChunks,capacityLeft);
end
if taskID == 3
    % Note that the third case does not exist when the server stores the first file
    % Case 3: Files previously stored in the current server are saved intact
    [selectID,heatDsize] = forCase2_storeLeftPart(para_Num,fileInfo,serverInfo,uniChunk,storageChunks,capacityLeft,partFilesLine,ii);
end


end