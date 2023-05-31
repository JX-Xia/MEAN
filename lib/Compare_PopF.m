function [IndexTable,serverInfo,totalHeat] = Compare_PopF(fileInfo,uniChunk,serverInfo)
% PopF: The most popular files are stored first, and the files are selected until the server is full
    
selectLines = [];
fileSize = zeros(size(fileInfo,1),1);
for i = 1:size(fileInfo,1)
    fileSize(i) = sum(fileInfo.chunk{i}.size);
end

fileInfoTmp = fileInfo;

for ii = 1:size(serverInfo,1)
    totalCapacity = serverInfo.capacity(ii);
    % Keep track of how much data is currently stored
    nowSize = 0;
    % Indicates whether the current server is full
    isFull = 0;

    while nowSize < totalCapacity && isFull == 0
        % Only files with a size less than or equal to nowSize are considered
        fileInfoT = fileInfo(fileSize<serverInfo.capacity(ii),:);
        % Look for the hottest file each time
        [M,I] = max(fileInfoT.heat);
        if isempty(I) == 0 && M(1) ~= 0
            selectID = fileInfoT.file{I(1)}(1);

            % Record all the chunks of the selected file
            selectChunk = fileInfo.chunk{selectID};
            Locb = selectChunk.chunkID;

            % Calculate the incremental size to store the file
            deltaSize = 0;
            for j = 1:length(Locb)
                if ismember(Locb(j),serverInfo.storageChunks{ii}) == false
                    deltaSize = deltaSize + uniChunk.size(Locb(j));
                end
            end

            % Update storageChunks
            serverInfo.storageChunks{ii} = union(serverInfo.storageChunks{ii},Locb);

            nowSize = sum(uniChunk.size(serverInfo.storageChunks{ii}));
            % Update the currently stored file
            serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID);

            serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + fileInfo.heat(selectID) * sum(selectChunk.size);
            
            % Update serverInfo.capacity(ii)
            serverInfo.capacity(ii) = totalCapacity - nowSize;

            selectLines = union(selectLines,selectID,'stable');
            
            % The popularity of the selected file is set to 0
            fileInfo.heat(selectID) = 0;
        else
            % End while
            isFull = 1;
        end
    end
end

% Estimate the hit ratio roughly
[IndexTable,totalHeat] = HitRatio(selectLines,serverInfo,fileInfoTmp);

end

