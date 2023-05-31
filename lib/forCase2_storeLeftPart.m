function [selectID,heatDsize] = forCase2_storeLeftPart(para_Num,fileInfo,serverInfo,uniChunk,storageChunks,capacityLeft,partFilesLine,ii)
% Files previously stored in the current server are saved intact

% If the current server stores the deduplicated file (avoid storing a copy of a file stored by a previous server)
if isempty(partFilesLine) == 0
    fileInfoTable = fileInfo(partFilesLine,:);
    % Parts that were not previously stored locally are stored completely:
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
    deltaP = serverInfo.reliability(ii) - fileInfoTable.deltaP;
    fileInfoTable.heatDsize = fileInfoTable.heatDsize .* deltaP;
    % Find the row with the largest heatDsize and store all its chunks
    [heatDsize,I] = max(fileInfoTable.heatDsize);
    % Check that the maximum value is not 0 (a 0 would mean that deltasize is greater than the left space, so selectFileFunc sets them all to 0).
    heatDsize = heatDsize(1);
    if heatDsize ~= 0
        selectID = partFilesLine(I(1));
    else
        selectID = 0;
    end
else
    selectID = 0;
    heatDsize = 0;
end





end

