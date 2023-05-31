function [fileInfoTmp,distTable] = mergeFiles(para_Num,k,distTable,fileInfoTmp)

% Look for the file pairs of k minimum dist
para_Num = 1;
[clusterResult] = minkFilePair(para_Num,k,distTable);

% Check whether the distance of the k file pairs with the smallest dist is all less than one
continueFlag = 1;
for i = 1:k
    if clusterResult.dist(i) >= 1
        % If any of these distances are greater than or equal to 1, then the remaining files 
        % are no longer relevant and should not be merged
        continueFlag = 0;
    end
end

% fprintf('Finish minkFilePair ...\n');

% If continueFlag is 1, continue merging; otherwise, do not merge
if continueFlag == 1
    mergePair = cell(k,1);
    for i = 1:k
        mergePair{i} = union(clusterResult.file1(i),clusterResult.file2(i),'stable');
    end
    
    % Merges pairs of files that are related to each other
    if k>1
        for i = 1:k
            for j = i+1 : k
                % If the intersection is not an empty set, they are merged
                if isempty(intersect(mergePair{i},mergePair{j})) == 0
                    mergePair{i} = union(mergePair{i},mergePair{j},'stable');
                    % Set the merged set to the empty set
                    mergePair{j} = [];
                end
            end
        end
    end

    % Delete the empty file pairs
    j = 0;
    for i = 1:k
        if isempty(mergePair{i}) == 0
            j = j+1;
        end
    end
    mergeCluster = cell(j,1);
    j = 0;
    for i = 1:k
        if isempty(mergePair{i}) == 0
            j = j+1;
            mergeCluster{j} = mergePair{i};
        end
    end

    % Based on the merged file pair, the cluster result is updated
    mC_len = length(mergeCluster);
    new_chunk = cell(mC_len,1);
    new_heat = zeros(mC_len,1);
    new_heatDsize = zeros(mC_len,1);
    new_file = cell(mC_len,1);
    for i = 1:mC_len
        new_chunk{i} = fileInfoTmp.chunk{mergeCluster{i}(1)};
        new_heat(i) = fileInfoTmp.heat(mergeCluster{i}(1));
        new_file{i} = fileInfoTmp.file{mergeCluster{i}(1)};
        % Each time a file is merged, the line marking the file is deleted, and the heat is set to -1 for convenience:
        fileInfoTmp.select(mergeCluster{i}(1)) = true;
        % Mark the rows that distTable wants to remove
        distTable(mergeCluster{i}(1),mergeCluster{i}(1)) = -1;
        if length(mergeCluster{i}) > 1
            for j = 2:length(mergeCluster{i})
                % Merge the chunks of all files within the cluster
                new_chunk{i} = union(new_chunk{i}, fileInfoTmp.chunk{mergeCluster{i}(j)},'stable');
                % The merged heat is the sum of the previous heat
                new_heat(i) = new_heat(i) + fileInfoTmp.heat(mergeCluster{i}(j));
                % Keep track of the files that make up the merged project (each file in mergeCluster may 
                % correspond to a set of files in fileInfoTmp.file)
                new_file{i} = union(new_file{i},fileInfoTmp.file{mergeCluster{i}(j)},'stable');
                
                % Each time a file is merged, the line marking the file is deleted, and the heat is set to -1 for convenience:
                fileInfoTmp.select(mergeCluster{i}(j)) = true;
                % Mark the rows that distTable wants to remove
                distTable(mergeCluster{i}(j),mergeCluster{i}(j)) = -1;
            end
        end
        % Update heat/size
        new_heatDsize(i) = new_heat(i)/sum(new_chunk{i}.size);
    end

    % Delete the rows marked by fileInfoTmp
    fileInfoTmp(fileInfoTmp.select,:) = [];
    % Remove the distTable's marked rows and columns
    i = 1;
    while i <= length(distTable)
        if distTable(i,i) == -1
            distTable(i,:) = [];
            distTable(:,i) = [];
        else
            i = i+1;
        end
    end

    % Update fileInfoTmp
    for i = 1:mC_len
        % Record the file information to the table
        newCell = {{}, new_heat(i), new_heatDsize(i), new_file{i}, false};
        newTable = cell2table(newCell);
        newTable.Properties.VariableNames = {'chunk','heat','heatDsize','file','select'};
        % Add new information to the TreeInfo of the task
        fileInfoTmp = [fileInfoTmp; newTable];
        fileInfoTmp.chunk{size(fileInfoTmp,1)} = new_chunk{i};
    end

    % Update distTable
   
    % Compute the parts of the distTable that need to be updated in parallel, 
    % and then update the distTable together based on each calculation
    para_Num = 64;

    distTablePart = cell(para_Num,1);
    parfor taskID = 1:para_Num
        [distTablePart{taskID}] = distTableUpdateFunc(taskID,para_Num,fileInfoTmp,mC_len);
    end

    % Expand the original distTable table down to the length(fileInfoTmp) * (length(fileInfoTmp)-mC_len) dimension
    distTable = [distTable; ones(mC_len,length(distTable))];
    % Combine the results
    for taskID = 1:para_Num
        % Horizontal extension of distTable is added to the results
        distTable = [distTable distTablePart{taskID}];
    end

end

end

