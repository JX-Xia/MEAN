function [selectID,heatDsize] = forCase2_storeReplicaFile(para_Num,fileInfo,fileTable,uniChunk,storageChunks,capacityLeft)
% Store a replica of the complete file from the previous server to the current server

% Tidy up the new fileInfoTable and select the rows where the SELECT is false, where true means the file is already stored on the server
deltaP = fileTable.deltaP(find(fileTable.select==false));
selectLine = fileTable.line(find(fileTable.select==false));
if isempty(selectLine) == 0
    fileInfoTable = fileInfo(selectLine,:);
    % Since these files were previously stored in the server, select is set to 0
    fileInfoTable.select = false(size(fileInfoTable,1),1);

    % The new file stores only the parts that were not stored by the server before: 
    % look in the storageChunksAll table to find the file with the largest heatDsize
    fileInfoTmp = cell(para_Num,1);
    for taskID = 1:para_Num
        [fileInfoTmp{taskID}] = Case1_selectFileFunc(taskID,para_Num,fileInfoTable,uniChunk,storageChunks,capacityLeft);
    end
    % Combine the results
    fileInfoTable = fileInfoTmp{1};
    for taskID = 2:para_Num
        fileInfoTable = [fileInfoTable;fileInfoTmp{taskID}];
    end

    % Update heatDsize
    fileInfoTable.heatDsize = fileInfoTable.heatDsize .* deltaP;

    % Find the row with the largest heatDsize and store all its chunks
    [heatDsize,I] = max(fileInfoTable.heatDsize);

    % Check that the maximum value is not 0 (a 0 would mean that deltasize is greater than the left space, so selectFileFunc sets them all to 0).
    heatDsize = heatDsize(1);
    if heatDsize ~= 0
        selectID = selectLine(I(1));
    else
        selectID = 0;
    end
else
    heatDsize = 0;
    selectID = 0;
end



end

