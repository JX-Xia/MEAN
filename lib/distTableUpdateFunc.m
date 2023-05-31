function [distTablePart] = distTableUpdateFunc(taskID,para_Num,fileInfoTmp,mC_len)
% Compute the distTable that needs to be updated in parallel

% The file_index start position of the subtask
subTask_start = floor(mC_len/para_Num)*(taskID-1) + 1 + size(fileInfoTmp,1)-mC_len;
% The end position of the subtask's file_index
if taskID == para_Num
    subTask_end = size(fileInfoTmp,1);
else
    subTask_end = floor(mC_len/para_Num) * taskID + size(fileInfoTmp,1)-mC_len;
end

fileNum = size(fileInfoTmp,1);
% A table to record the Jaccard distance between files
distTablePart = ones(fileNum, subTask_end-subTask_start+1);
for j = subTask_start : subTask_end
    for i = 1 : j-1
        % Calculate the Jaccard distance between two files
        file1_chunks = fileInfoTmp.chunk{i};
        file2_chunks = fileInfoTmp.chunk{j};
        
        % Compute the intersection of two files (this is the most time-consuming) 
        AnB = intersect(file1_chunks,file2_chunks,'row','stable');
        
        % Calculate the Jaccard distance of a pair of files
        AnB_size = sum(AnB.size);
        AuB_size = sum(file1_chunks.size)+sum(file2_chunks.size)-AnB_size;
        dist = 1 - AnB_size/AuB_size;

        heatDsize = (fileInfoTmp.heat(i)+fileInfoTmp.heat(j))/AuB_size;
        
        % If heat/size does not get smaller after merging, the two files may be merged
        if heatDsize >= max(fileInfoTmp.heatDsize(i), fileInfoTmp.heatDsize(j))
            % Update distTable
            distTablePart(i,j-subTask_start+1) = dist;
        else
            % Otherwise, set their dist to 1
            distTablePart(i,j-subTask_start+1) = 1;
        end
        
    end
end




end

