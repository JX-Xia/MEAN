function [storageChunks,storageLines,totalHeat,nowSize] = Case1_selectFile(para_Num,fileInfo,uniChunk,serverInfo)

% Scenario One: Server reliability is not considered

totalCapacity = sum(serverInfo.capacity);

% To record which chunks are stored
storageChunks = [];
% Used to keep track of which files are stored
storageLines = [];

% Keep track of how much data is currently stored
nowSize = 0;

% Record the remaining storage space
capacityLeft = totalCapacity;

% Record the total heat
totalHeat = 0;

is_full = 0;

while nowSize < totalCapacity && sum(fileInfo.select) < size(fileInfo,1) && is_full == 0
    % Each time, the file with the largest current heat/size is greedily selected to store to the current server
    if isempty(storageLines)
        % For the first file, choose the one with the largest heat/size
        [~,I] = max(fileInfo.heatDsize);
        selectID = I(length(I));

        % Record all the chunks of the selected file
        selectChunk = fileInfo.chunk{selectID};

        % Find the corresponding position of chunk in selectChunk in uniChunk
        Locb = selectChunk.chunkID;

        % Update variables
        storageChunks = union(storageChunks,Locb);

        nowSize = sum(uniChunk.size(storageChunks));

        storageLines = selectID;

        % Mark the selected row
        fileInfo.select(selectID) = true;

        totalHeat = totalHeat + fileInfo.heat(selectID);

        capacityLeft = totalCapacity - nowSize;
    else
        % For later files, the one with the largest heat/deltasize is selected and has not been selected
        % Calculate the deltasize of each file relative to the currently stored data
        fileInfoTmp = cell(para_Num,1);
        for taskID = 1:para_Num
            [fileInfoTmp{taskID}] = Case1_selectFileFunc(taskID,para_Num,fileInfo,uniChunk,storageChunks,capacityLeft);
        end
        % Combine the results of the calculations
        fileInfo = fileInfoTmp{1};
        for taskID = 2:para_Num
            fileInfo = [fileInfo;fileInfoTmp{taskID}];
        end
        % Find the row with the largest heatDsize and store all its files and chunks
        [M,I] = max(fileInfo.heatDsize);

        M = M(1);
        I = I(1);
        
        % Check that the maximum value is not 0 (a 0 would mean that deltasize is 
        % greater than the free space, so selectFileFunc sets them all to 0).
        if M ~= 0
            selectID = I(1);
            % Record all the chunks of the selected file
            selectChunk = fileInfo.chunk{selectID};
            Locb = selectChunk.chunkID;

            % Update
            storageChunks = union(storageChunks,Locb);
            nowSize = sum(uniChunk.size(storageChunks));
            storageLines = union(storageLines, selectID);
            % Mark the selected row
            fileInfo.select(selectID) = true;

            totalHeat = totalHeat + fileInfo.heat(selectID);

            capacityLeft = totalCapacity - nowSize;
        else
            is_full = 1;

        end
    end

end



end

