function [chunk2server,serverIndex] = outputResult_uni(uniChunk,serverInfo,storageChunks)
% Collate the results for testing (Scenario One)

chunk2server = cell(size(uniChunk,1),1);
storageChunks_size = uniChunk.size(storageChunks);

serverIndex = cell(size(serverInfo,1),1);
j = 1;
for i = 1 : length(storageChunks)
    if j  <= size(serverInfo,1)
        if serverInfo.capacity(j) - storageChunks_size(i) >= 0
            serverInfo.capacity(j) = serverInfo.capacity(j) - storageChunks_size(i);
            chunk2server{i} = union(chunk2server{i}, j);
            serverIndex{j} = union(serverIndex{j}, i);
        else
            j = j+1;
        end
    end
end


end