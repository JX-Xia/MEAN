function [IndexTable,serverInfo,totalHeat] = Compare_Random(fileInfo,uniChunk,serverInfo)
% Naive: Randomly select files until the server is full

selectLines =[];
fileSize = zeros(size(fileInfo,1),1);
fileInfo.line = zeros(size(fileInfo,1),1);
for i = 1:size(fileInfo,1)
    fileSize(i) = sum(fileInfo.chunk{i}.size);
    fileInfo.line(i) = i;
end

for ii = 1:size(serverInfo,1)
    % Total storage capacity of all servers
    totalCapacity = serverInfo.capacity(ii);
    % Keep track of how much data is currently stored
    nowSize = 0;
    % Indicates whether the current server is full
    isFull = 0;
   
    while nowSize < totalCapacity && isFull == 0
        fileInfoT = fileInfo(fileSize<serverInfo.capacity(ii),:);
        fileSetT = fileInfoT.line;
        fileSet = setdiff(fileSetT,selectLines);
        if isempty(fileSet) == 0
            % Select a file at random from the fileSet
            fileSetID = randi([1,length(fileSet)]);
            selectID = fileSet(fileSetID);

            selectChunk = fileInfo.chunk{selectID};
            % Find the corresponding position of chunk in selectChunk in uniChunk
            Locb = selectChunk.chunkID;

            deltaSize = 0;
            for j = 1:length(Locb)
                if ismember(Locb(j),serverInfo.storageChunks{ii}) == false
                    deltaSize = deltaSize + uniChunk.size(Locb(j));
                end
            end

            % Update parameters
            serverInfo.storageChunks{ii} = union(serverInfo.storageChunks{ii},Locb);

            nowSize = sum(uniChunk.size(serverInfo.storageChunks{ii}));

            serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID);

            serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + fileInfo.heat(selectID) * sum(selectChunk.size);
            
            % Keep track of the selected rows
            selectLines = union(selectLines,selectID,'stable');
            
            serverInfo.capacity(ii) = totalCapacity - nowSize;
        else
            % End the while
            isFull = 1;
        end
    end
end

% Estimate the hit ratio roughly
[IndexTable,totalHeat] = HitRatio(selectLines,serverInfo,fileInfo);


end

