function [fileTableTmp] = deltaP_forReplicaHet(taskID,para_Num,fileTable,serverInfo,ii)
% Calculate the deltaP of the file stored in the current server, deltaP = (1-p)^sNum - (1-p)^(sNum+1)

% The file_index start position of the subtask
subTask_start = floor(size(fileTable,1)/para_Num)*(taskID-1) + 1;
% The end position of the subtask's file_index
if taskID == para_Num
    subTask_end = size(fileTable,1);
else
    subTask_end = floor(size(fileTable,1)/para_Num) * taskID;
end
    
% This subtask considers only part of the data of fileInfo
fileTableTmp = fileTable(subTask_start : subTask_end, :);
for i = 1 : size(fileTableTmp,1)
    % Calculate sNum
    sNum = length(fileTable.server{i});
    % Calculate delatP
    deltaP = 1;
    for j = 1:sNum
        serverID = fileTable.server{i}(j);
        deltaP = deltaP * (1-serverInfo.reliability(serverID));
    end
    
    fileTableTmp.deltaP(i) = deltaP * serverInfo.reliability(ii);
    
end



end

