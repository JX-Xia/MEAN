function [clusterResult] = minkFilePair(para_Num,k,distTable)
% Compute the k file pairs with the minimum distance

clusterResultTmp = cell(para_Num,1);
parfor taskID = 1:para_Num
    [clusterResultTmp{taskID,1}] = minkFilePairFunc(taskID,para_Num,k,distTable);
end

clusterResult = clusterResultTmp{1,1};
[MaxDist,I] = max(clusterResult.dist);
for taskID = 2:para_Num
    for i = 1:k
        if clusterResultTmp{taskID,1}.dist(i) < MaxDist
            % Delete the original file pair
            clusterResult = setdiff(clusterResult,clusterResult(I(1),:),'rows','stable');
            % Join the current file pair
            clusterResult = union(clusterResult,clusterResultTmp{taskID,1},'rows','stable');
            % Update MaxDist
            [MaxDist,I] = max(clusterResult.dist);
        end
    end
end

