function [clusterResult] = minkFilePairFunc(taskID,taskNum,k,distTable)
% Calculate the k file pairs with minimum distance

% Initialization is used to record the results of the cluster process
clusterResult = table;
clusterResult.file1 = zeros(k,1);
clusterResult.file2 = zeros(k,1);
clusterResult.dist = zeros(k,1);
for i = 1:k
    clusterResult.file1(i) = i;
    clusterResult.file2(i) = 0;
    clusterResult.dist(i) = inf;
end

% The file_index start position of the subtask
subTask_start = floor(size(distTable,1)/taskNum)*(taskID-1) + 1;
% The file_index of the subtask is over
if taskID == taskNum
    subTask_end = size(distTable,1);
else
    subTask_end = floor(size(distTable,1)/taskNum) * taskID;
end

fileNum = size(distTable,1);
% The value of dist is used to determine whether the file pair is added to clusterResult
[MaxDist,I] = max(clusterResult.dist);
for i = subTask_start : subTask_end
    for j = i+1 : fileNum
        if distTable(i,j) < MaxDist
            % Delete the original file pair
            clusterResult = setdiff(clusterResult,clusterResult(I(1),:),'rows','stable');
            % Add the current file pair
            newFilePair = table;
            newFilePair.file1 = i;
            newFilePair.file2 = j;
            newFilePair.dist = distTable(i,j);
            clusterResult = union(clusterResult,newFilePair,'rows','stable');
            % Update MaxDist
            [MaxDist,I] = max(clusterResult.dist);
        end
    end
end



end

