function [fileInfoTmp] = clusterFiles(para_Num,k,fileInfo,alpha)
% Clustering, the k file pairs with the smallest Jaccard distance are selected for merging

% Calculate distTable
distTableTmp = cell(para_Num,1);
parfor taskID = 1:para_Num
    [distTableTmp{taskID,1}] = clusterFilesFunc(taskID,para_Num,fileInfo);
end
% Combine the results
distTable = distTableTmp{1,1};
for taskID = 2:para_Num
    table_start = size(distTable,1)+1;
    table_end = size(distTable,1)+size(distTableTmp{taskID,1},1);
    distTable(table_start:table_end,:) = distTableTmp{taskID,1};
end
clear distTableTmp;

% Merge
fileInfoTmp = table;
fileInfoTmp.chunk = fileInfo.chunk;
fileInfoTmp.heat = fileInfo.heat;
fileInfoTmp.heatDsize = fileInfo.heatDsize;
% Create a new array of cells that keeps track of which files make up the row, starting with the original single file
fileInfoTmp.file = cell(size(fileInfoTmp,1),1);
for i = 1:size(fileInfoTmp,1)
    fileInfoTmp.file{i}(1) = i;
end
% Used to store markers
fileInfoTmp.select = false(size(fileInfoTmp,1),1);
    
fprintf('Merging files ...\n');
% Merging files
for i = 1:alpha
    [fileInfoTmp,distTable] = mergeFiles(para_Num,k,distTable,fileInfoTmp);
end




end