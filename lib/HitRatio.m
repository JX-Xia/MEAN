function [IndexTable,totalHeat] = HitRatio(selectLines,serverInfo,fileInfo,crossFile)
% Roughly calculate the hit ratio and return the IndexTable where the file is stored

% Some methods do not consider storing files across servers, and the default value is set to an empty set
if nargin < 4
    crossFile = [];
end

% Calculate the reliability of each stored file
IndexTable = table;

[a,b] = size(selectLines);
if b > a
    selectLines = selectLines';
end

IndexTable.line = selectLines;
% Keep track of which files the row is made up of (because files may be merged through the cluster process)
IndexTable.files = cell(size(IndexTable,1),1);
for i = 1:size(IndexTable,1)
    IndexTable.files{i} = fileInfo.file{IndexTable.line(i)};
end
% Keep track of which servers the files are stored on
IndexTable.location = cell(size(selectLines,1),1);

% Add the location of each file to the index table
for i = 1:size(serverInfo,1)
    for j = 1:length(serverInfo.storageLines{i})
        [~,Locb] = ismember(serverInfo.storageLines{i}(j), IndexTable.line);
        IndexTable.location{Locb} = [IndexTable.location{Locb};{i}];
    end
end

% Add the files in crossFile to the index table
for i = 1:size(crossFile,1)
    [~,Locb] = ismember(crossFile.line(i), IndexTable.line);
    % The variable that keeps track of where it is stored
    location = [];
    for j = 1:size(crossFile.chunk2server{i},1)
        location = union(location,crossFile.chunk2server{i}.server(j),'stable');
    end
    IndexTable.location{Locb} = [IndexTable.location{Locb};{location}];
end

IndexTable.reliability = zeros(size(IndexTable,1),1);

% Calculate hit ratio
totalHeat = 0;
for i = 1:size(IndexTable,1)
    fileHeat = fileInfo.heat(IndexTable.line(i));
    P = 1;
    for j = 1:length(IndexTable.location{i})
        Ptmp = 1;
        for j1 = 1:length(IndexTable.location{i}{j})
            serverID = IndexTable.location{i}{j}(j1);
            Ptmp = Ptmp * serverInfo.reliability(serverID);
        end
        % Probability of unavailability of the current storage scheme
        Ptmp = 1 - Ptmp;
        % Probability of unavailability
        P = P * Ptmp;
    end
    % The availability probability is: 1 minus the probability that all cases are unavailable
    P = 1 - P;
    IndexTable.reliability(i) = P;
    totalHeat = totalHeat + fileHeat * P;
end



end

