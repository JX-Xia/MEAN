function [fileInfoTmp] = deltaP_forDedupHet(taskID,para_Num,fileInfo,serverInfo,uniChunk,storageChunksAll,ii)
% The calculation file is stored in the current server deltaP, deltaP = P^(sNum+1).

% The file_index start position of the subtask
subTask_start = floor(size(fileInfo,1)/para_Num)*(taskID-1) + 1;
% The end position of the subtask's file_index
if taskID == para_Num
    subTask_end = size(fileInfo,1);
else
    subTask_end = floor(size(fileInfo,1)/para_Num) * taskID;
end
    
% This subtask considers only part of the data of fileInfo
fileInfoTmp = fileInfo(subTask_start : subTask_end, :);
for i = 1 : size(fileInfoTmp,1)
    % Calculate the minimum number of servers across sNum required to store 
    % the file, starting from the first server to find the blocks of the file
    selectChunk = fileInfoTmp.chunk{i}; 
    % Find the corresponding position of chunk in selectChunk in uniChunk
    Locb = selectChunk.chunkID;

    % Check which chunks were previously stored by the server
    LocbTmp = intersect(Locb,storageChunksAll);

    % Calculate the minimum number of servers across sNum
    sNum = 0;
    % If none of the previous servers store the file, its reliability is the reliability of the current server
    if isequal(Locb,LocbTmp)
        % The same means that the current server does not store chunks
        fileInfoTmp.deltaP(i) = 1;
    else
        fileInfoTmp.deltaP(i) = serverInfo.reliability(ii);
    end
    % If the previous server also stores chunks of the current file, its reliability is updated
    while isempty(LocbTmp) == 0
        sNum = sNum + 1;
        % If there are chunks stored in this server
        LocbTmpt = intersect(LocbTmp,serverInfo.storageChunks{sNum});

        % If it is not empty, chunks of the file are stored on the server
        if isempty(LocbTmpt) == 0
            % Update LocbTmp
            LocbTmp = setdiff(LocbTmp,LocbTmpt);
            % Update deltaP
            fileInfoTmp.deltaP(i) = fileInfoTmp.deltaP(i) * serverInfo.reliability(sNum);
        end
    end

end



end

