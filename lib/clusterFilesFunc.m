function [distTable] = clusterFilesFunc(taskID,para_Num,fileInfo)
% Clustering files in parallel

% The file_index start position of the subtask
subTask_start = floor(size(fileInfo,1)/para_Num)*(taskID-1) + 1;
% The end position of the subtask's file_index
if taskID == para_Num
    subTask_end = size(fileInfo,1);
else
    subTask_end = floor(size(fileInfo,1)/para_Num) * taskID;
end

fileNum = size(fileInfo,1);

% A table to record the Jaccard distance between files:
distTable = ones(subTask_end-subTask_start+1, fileNum);

for i = subTask_start : subTask_end

    for j = i+1 : fileNum
        % Calculate the Jaccard distance between two files
        % file 1:
        file1_chunks = fileInfo.chunk{i};
        % file 2:
        file2_chunks = fileInfo.chunk{j};
        
        % Compute the intersection of two files (this is the most time-consuming) 
        AnB = intersect(file1_chunks,file2_chunks,'row','stable');
        
        % Calculate the Jaccard distance of a pair of files
        AnB_size = sum(AnB.size);
        AuB_size = sum(file1_chunks.size)+sum(file2_chunks.size)-AnB_size;
        dist = 1 - AnB_size/AuB_size;

        heatDsize = (fileInfo.heat(i)+fileInfo.heat(j))/AuB_size;
        
        % If heat/size does not get smaller after merging, the two files may be merged
        if heatDsize >= max(fileInfo.heatDsize(i), fileInfo.heatDsize(j))
            % Update distTable
            distTable(i-subTask_start+1,j) = dist;
        else
            % Otherwise, set their dist to 1
            distTable(i-subTask_start+1,j) = 1;
        end
        
    end
    % toc;
end





end

