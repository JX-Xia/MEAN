function [IndexTable,serverInfo,crossFile,fileTable,selectLines,totalHeat] = Case2_selectFile(para_Num,fileInfo,uniChunk,serverInfo)
% Solution for Scenario Two and Three (server reliability may be the same or different)

% Output:
% - serverInfo: Record information about each server, which files are stored, etc
% - crossFile: Keep track of which files are stored across servers
% - fileTable: Keep track of which files are fully stored on which servers (for debug)
% - selectLines: Keep track of which files were selected to store in the server (for debug)
% - totalHeat: The total heat value stored by all servers is the sum of heat * size rather than simply the sum of HEAT

% Note that this function also requires the Case1_selectFileFunc() function

% Keep track of which files are currently stored
selectLines = [];
% A list of files maintained to keep track of which files (lines) were previously stored in their entirety on which servers
fileTable = table;
% Keeps track of which blocks are currently stored by all servers
storageChunksAll = [];
for ii = 1:size(serverInfo,1)
    serverInfo.storageChunks{ii} = [];
end

% Keep track of which files are stored across servers
crossFile = [];

% For debug
error = 0;

for ii = 1:size(serverInfo,1)
    % The first server considers only heat/deltaSize
    if ii == 1
        capacityLeft = serverInfo.capacity(ii);
        storageChunks = serverInfo.storageChunks{ii};
        while sum(fileInfo.select) < size(fileInfo,1) 
            % Each time, the file with the largest current heat/size is greedily selected to store to the current server
            if isempty(serverInfo.storageLines{ii})
                % For the first file, choose the one with the largest heat/size
                [~,I] = max(fileInfo.heatDsize);
                selectID = I(1);
                % Record all the chunks of the selected file
                selectChunk = fileInfo.chunk{selectID};
                % Find the corresponding position of chunk in selectChunk in uniChunk
                Locb = selectChunk.chunkID;

                % Update
                storageChunks = union(storageChunks,Locb);
                nowSize = sum(uniChunk.size(storageChunks));
                serverInfo.storageLines{ii} = selectID;
                % Mark
                fileInfo.select(selectID) = true;

                visitAmount = fileInfo.heat(selectID) * sum(selectChunk.size);
                serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;
                capacityLeft = serverInfo.capacity(ii) - nowSize;

                % Keep track of the selected rows
                selectLines = selectID;
                
                % Add the file to the list
                fileTable.line = selectID;
                fileTable.server = {ii};
            else
                % For later files, we choose the one with the largest heat/deltasize and that has not been selected by the tag
                % Calculate the deltasize of each file relative to the currently stored data
                fileInfoTmp = cell(para_Num,1);
                for taskID = 1:para_Num
                    [fileInfoTmp{taskID}] = Case1_selectFileFunc(taskID,para_Num,fileInfo,uniChunk,storageChunks,capacityLeft);
                end
                % Combine the results
                fileInfo = fileInfoTmp{1};
                for taskID = 2:para_Num
                    fileInfo = [fileInfo;fileInfoTmp{taskID}];
                end
                % Find the row with the largest heatDsize and store all its files and chunks
                [M,I] = max(fileInfo.heatDsize);

                % Check that the maximum value is not 0 (a 0 would mean that deltasize is greater than the free space, so selectFileFunc sets them all to 0).
                if M(1) ~= 0
                    selectID = I(1);
                    % Record all the chunks of the selected file
                    selectChunk = fileInfo.chunk{selectID};
                    Locb = selectChunk.chunkID;

                    % Update
                    storageChunks = union(storageChunks,Locb);
                    nowSize = sum(uniChunk.size(storageChunks));
                    serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID,'stable');
                    % Mark
                    fileInfo.select(selectID) = true;

                    visitAmount = fileInfo.heat(selectID) * sum(selectChunk.size);
                    serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;
                    capacityLeft = serverInfo.capacity(ii) - nowSize;

                    selectLines = union(selectLines,selectID);
                    % Add the file to the list of files, because it is stored in whole parts, so we can just add it
                    newCell = {selectID,{ii}};
                    newTable = cell2table(newCell);
                    newTable.Properties.VariableNames = {'line','server'};
                    fileTable = [fileTable;newTable];
                end
                
            end
        end
        % When the first server is full, you need to update fileInfo by setting the select to 0 for files that are not stored
        % The select for files that are already stored is marked with 1
        fileInfo.select = false(size(fileInfo,1),1);
        fileInfo.select(selectLines,1) = true;
        % Update nowSize
        nowSize = 0;
        % Update serverInfo
        serverInfo.capacity(ii) = capacityLeft;
        serverInfo.storageChunks{ii} = storageChunks;
        storageChunksAll = storageChunks;
    else
        % A new server
        capacityLeft = serverInfo.capacity(ii);
        storageChunks = serverInfo.storageChunks{ii};
        % Used to keep track of whether the file is stored in the current server
        fileTable.select = false(size(fileTable,1),1);
        
        % Compute deltaP for the fileInfo table
        fileInfo.deltaP = zeros(size(fileInfo,1),1);

        fileInfoTmp = cell(para_Num,1);
        for taskID = 1:para_Num
            [fileInfoTmp{taskID}] = deltaP_forDedupHet(taskID,para_Num,fileInfo,serverInfo,uniChunk,storageChunksAll,ii);
        end
        % Combine the results
        fileInfo = fileInfoTmp{1};
        for taskID = 2:para_Num
            fileInfo = [fileInfo;fileInfoTmp{taskID}];
        end
        
        % Compute deltaP for fileTable
        fileTable.deltaP =zeros(size(fileTable,1),1);
        fileTableTmp = cell(para_Num,1);
        for taskID = 1:para_Num
            [fileTableTmp{taskID}] = deltaP_forReplicaHet(taskID,para_Num,fileTable,serverInfo,ii);
        end
        % Combine the results
        fileTable = fileTableTmp{1};
        for taskID = 2:para_Num
            fileTable = [fileTable;fileTableTmp{taskID}];
        end

        isFull = 0;
        
        % Keep track of which files in the current server store only the parts that the previous server did not store
        partFilesLine = [];
        
        while sum(fileInfo.select) < size(fileInfo,1) && isFull == 0
            % Compare the following three cases and choose the one with the largest heatDszie to store:
            selectID = zeros(3,1);
            heatDsize = zeros(3,1);

            for taskID = 1:3
                [selectID(taskID),heatDsize(taskID)] = forCase2Parallel(taskID,ii,para_Num,fileInfo,uniChunk,storageChunks,storageChunksAll,capacityLeft,partFilesLine,fileTable,serverInfo);
            end

            % Calculate the maximum heatDsize and store it in the current server
            [M,I] = max(heatDsize);
            M = M(1);
            I = I(1);

            if M ~= 0
                % If we choose to store deduplicated files
                if I(1) == 1
                    % First, determine whether the remaining deduplicated chunks need to be stored locally
                    selectChunk = fileInfo.chunk{selectID(I(1))}; 
                    Locb = selectChunk.chunkID;
                    
                    crossFileTmp = table;
                    % Find out what parts were stored by each server previously
                    LocbTmp = intersect(Locb,storageChunksAll);

                    LocbTmp0 = LocbTmp;

                    sNum = 0;
                    while isempty(LocbTmp) == 0
                        sNum = sNum + 1;
                        % Determine which server serves each chunk of the file
                        chunkID = intersect(LocbTmp,serverInfo.storageChunks{sNum});

                        if isempty(chunkID) == 0
                            newCell = {{chunkID}, sNum};
                            newTable = cell2table(newCell);
                            newTable.Properties.VariableNames = {'chunkID','server'};
                            crossFileTmp = [crossFileTmp;newTable];
                            % Update LocbTmp
                            LocbTmp = setdiff(LocbTmp,chunkID);
                        end
                    end
                    
                    % Update the corresponding heat value of the server
                    % that previously stored the file chunk
                    for i = 1:size(crossFileTmp,1)
                        visitAmount = fileInfo.heat(selectID(I(1))) * sum(uniChunk.size(crossFileTmp.chunkID{i}));
                        serverInfo.visitAmount(crossFileTmp.server(i)) = serverInfo.visitAmount(crossFileTmp.server(i)) + visitAmount;
                    end
                    
                    % Update LocbTmp to the previous value (otherwise it would have been empty in the previous step)
                    LocbTmp = LocbTmp0;

                    % If the current server has chunks to store
                    if ~ isequal(Locb,LocbTmp)
                        % If the previous server does not store the part, it means that the file should be stored directly in the current server
                        if sNum == 0
                            % The index of this file is directly added to the current server

                            % Update storageChunks
                            storageChunks = union(storageChunks,Locb);

                            nowSize = sum(uniChunk.size(storageChunks));
                            
                            % Update the currently stored file
                            serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID(I(1)),'stable');

                            % Mark the selected row
                            fileInfo.select(selectID(I(1))) = true;

                            capacityLeft = serverInfo.capacity(ii) - nowSize;

                            if capacityLeft < 0
                                error = 1;  
                            end

                            selectLines = union(selectLines,selectID(I(1)),'stable');
                            
                            visitAmount = fileInfo.heat(selectID(I(1))) * sum(selectChunk.size);
                            serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;

                            % Record this file/cluster in fileTable
                            newCell = {selectID(I(1)),{ii},true,0};
                            newTable = cell2table(newCell);
                            newTable.Properties.VariableNames = {'line','server','select','deltaP'};
                            fileTable = [fileTable;newTable];
                        else
                            % Otherwise, the file has other chunks stored in other servers, and the index of such a file is added to crossFile
                            % Find blocks not previously stored by the server
                            LocbLeft = setdiff(Locb,LocbTmp,'stable');

                            storageChunks = union(storageChunks,LocbLeft);

                            nowSize = sum(uniChunk.size(storageChunks));
                            capacityLeft = serverInfo.capacity(ii) - nowSize;

                            if capacityLeft < 0
                                error = 1;
                            end

                            partFilesLine = union(partFilesLine,selectID(I(1)),'stable');

                            visitAmount = fileInfo.heat(selectID(I(1))) * sum(uniChunk.size(LocbLeft));
                            serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;

                            % File updates to crossFile record chunk location
                            newCell = {{LocbLeft}, ii};
                            newTable = cell2table(newCell);
                            newTable.Properties.VariableNames = {'chunkID','server'};
                            crossFileTmp = [crossFileTmp;newTable];
                            
                            % Record the file/cluster to the crossFile list
                            newCell = {selectID(I(1)), {}};
                            newTable = cell2table(newCell);
                            newTable.Properties.VariableNames = {'line','chunk2server'};
                            newTable.chunk2server = {crossFileTmp};
                            if isempty(crossFile)
                                crossFile = newTable;
                            else
                                crossFile = [crossFile;newTable];
                            end
                        end
       
                    end
                    
                end
                
                % If we choose to store a copy of the previous file, update fileTable.server and fileTable.select
                if I(1) == 2
                    % Record all the chunks of the selected file
                    selectChunk = fileInfo.chunk{selectID(I(1))};
                    Locb = selectChunk.chunkID;

                    % Update storageChunks
                    storageChunks = union(storageChunks,Locb);

                    nowSize = sum(uniChunk.size(storageChunks));

                    % Update the currently stored files/clusters
                    serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID(I(1)),'stable');
                    % Mark it
                    fileInfo.select(selectID(I(1))) = true;
                    % Update the left space
                    capacityLeft = serverInfo.capacity(ii) - nowSize;

                    if capacityLeft < 0
                        error = 1;
                    end
                    
                    % Update the heat value of the server that previously stored the file
                    line = find(fileTable.line==selectID(I(1)));
                    % The total number of servers on which the file is stored
                    sNum = length(fileTable.server{line}) + 1;
                    deltaAmount = (fileInfo.heat(selectID(I(1)))/(sNum-1) - fileInfo.heat(selectID(I(1)))/sNum) * sum(selectChunk.size);
                    % This delta has been subtracted from the server's popularity since the replica was added
                    for i = 1:sNum-1
                        serverID = fileTable.server{line}(i);
                        serverInfo.visitAmount(serverID) = serverInfo.visitAmount(serverID) - deltaAmount;
                    end

                    visitAmount = fileInfo.heat(selectID(I(1)))/sNum * sum(selectChunk.size);
                    serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;
                    
                    % The file in fileTable stores location records on the current server
                    fileTable.server{line} = union(fileTable.server{line},ii,'stable');
                    % The file in the fileTable flag has been selected to be stored in the current server
                    fileTable.select(line) = true;
                end
                
                % If the file is intact on the current server, update fileTable
                if I(1) == 3
                    % Add the file to the list of files, because it is stored in whole parts, so we can just add it
                    newCell = {selectID(I(1)),{ii},true,0};
                    newTable = cell2table(newCell);
                    newTable.Properties.VariableNames = {'line','server','select','deltaP'};
                    fileTable = [fileTable;newTable];
                    
                    % Determines whether the file stores past duplicates
                    line = find(crossFile.line==selectID(I(1)));
                    for i = 1:length(crossFile.chunk2server{line}.server)
                        % Calculate the backoff heat value
                        chunkID = crossFile.chunk2server{line}.chunkID{i};
                        deltaAmount = fileInfo.heat(selectID(I(1))) * sum(uniChunk.size(chunkID));
                        % Update to the previous server
                        serverID = crossFile.chunk2server{line}.server(i);
                        serverInfo.visitAmount(serverID) = serverInfo.visitAmount(serverID) - deltaAmount;
                    end
                    % Remove the file from the crossFile list
                    crossFile(line,:) = [];
                    % Remove the file from the partFilesLine list
                    partFilesLine(partFilesLine==selectID(I(1))) = [];
                    
                    % Record the selected files
                    selectChunk = fileInfo.chunk{selectID(I(1))};
                    Locb = selectChunk.chunkID;

                    % Update storageChunks
                    storageChunks = union(storageChunks,Locb);

                    nowSize = sum(uniChunk.size(storageChunks));

                    % Update the currently stored file
                    serverInfo.storageLines{ii} = union(serverInfo.storageLines{ii}, selectID(I(1)),'stable');
                    % Mark the line
                    fileInfo.select(selectID(I(1))) = true;

                    capacityLeft = serverInfo.capacity(ii) - nowSize;

                    if capacityLeft < 0
                        error = 1;
                    end

                    % Mark
                    selectLines = union(selectLines,selectID(I(1)),'stable');
                    
                    visitAmount = fileInfo.heat(selectID(I(1))) * sum(selectChunk.size);
                    serverInfo.visitAmount(ii) = serverInfo.visitAmount(ii) + visitAmount;
                end
                
            else
                % Mark that the current server is full
                isFull = 1;
            end
                    
        end
        % Update selectLines
        selectLines = union(selectLines,partFilesLine,'stable');
        
        % Update serverInfo.storageChunks
        serverInfo.storageChunks{ii} = storageChunks;
        % When the current server is full, we need to update fileInfo, and we need to set the select of files that are not stored to 0
        % The select for files that are already stored is marked with 1
        fileInfo.select = false(size(fileInfo,1),1);
        fileInfo.select(selectLines) = true;
        % Update nowSize
        nowSize = 0;
        % Update serverInfo.capacity
        serverInfo.capacity(ii) = capacityLeft;
        
        storageChunksAll = union(storageChunksAll,storageChunks);
    end
        
end

% Estimate the hit ratio roughly
[IndexTable,totalHeat] = HitRatio(selectLines,serverInfo,fileInfo,crossFile);


end

