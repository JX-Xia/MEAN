function [chunk2server,serverIndex,reliability] = outputResult(uniChunk,serverInfo)
% Collate the results for testing (Scenario Two and Three)

chunk2server = cell(size(uniChunk,1),1);
parfor i = 1:size(uniChunk,1)
    for j = 1:size(serverInfo,1)
        if ismember(i, serverInfo.storageChunks{j})
            chunk2server{i} = union(chunk2server{i},j);
        end
    end
end

serverIndex = serverInfo.storageChunks;

reliability = serverInfo.reliability;


end