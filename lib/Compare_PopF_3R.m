function [IndexTable,serverInfo,totalHeat] = Compare_PopF_3R(fileInfo,uniChunk,serverInfo,replicaNum)
% PopF_3R: Popularity first and multiple replicas

selectLines = [];
fileSize = zeros(size(fileInfo,1),1);
for i = 1:size(fileInfo,1)
    fileSize(i) = sum(fileInfo.chunk{i}.size);
end

fileInfoTmp = fileInfo;

isFull = 0;
% Pick the hottest file one at a time
while isFull == 0
    [M,I] = max(fileInfo.heat);
    if M(1) ~= 0
        selectID = fileInfo.file{I(1)}(1);
        % Record all the chunks of the selected file
        selectChunk = fileInfo.chunk{selectID}; 
        Locb = selectChunk.chunkID;
        % Find a server that can store the file and its replica
        avail_server = [];
        for i = 1:size(serverInfo,1)
            % Calculate the incremental size to store the file
            deltaSize = 0;
            for j = 1:length(Locb)
                if ismember(Locb(j),serverInfo.storageChunks{i}) == false
                    deltaSize = deltaSize + uniChunk.size(Locb(j));
                end
            end
            if serverInfo.capacity(i) - deltaSize >= 0
                avail_server = union(avail_server,i);
            end
        end
        % If enough servers are available
        if length(avail_server) >= replicaNum
            % Shuffle the server order
            rowrank = randperm(length(avail_server)); 
            avail_server = avail_server(rowrank);
            
            % Store the replicas to the previous replicaNum server
            for i = 1:replicaNum
                serverID = avail_server(i);
               
                % Calculate the incremental size to store the file
                deltaSize = 0;
                for j = 1:length(Locb)
                    if ismember(Locb(j),serverInfo.storageChunks{serverID}) == false
                        deltaSize = deltaSize + uniChunk.size(Locb(j));
                    end
                end
                % Update the server's serverInfo information
                serverInfo.capacity(serverID) = serverInfo.capacity(serverID) - deltaSize;
                serverInfo.storageChunks{serverID} = union(serverInfo.storageChunks{serverID},Locb);

                % Update the currently stored file
                serverInfo.storageLines{serverID} = union(serverInfo.storageLines{serverID}, selectID);
                % Uptade total heat
                serverInfo.visitAmount(serverID) = serverInfo.visitAmount(serverID) + fileInfo.heat(selectID)/replicaNum * sum(selectChunk.size);

                % Keep track of the selected rows
                selectLines = union(selectLines,selectID,'stable');
                
                % The popularity of the selected file is set to 0
                fileInfo.heat(selectID) = 0;
            end

        else
            % Set the popularity of the file to 0 and don't store the file
            fileInfo.heat(selectID) = 0;
        end

    else
        isFull = 1;
    end

end


% Estimate the hit ratio roughly
[IndexTable,totalHeat] = HitRatio(selectLines,serverInfo,fileInfoTmp);

end

