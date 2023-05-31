function [fileInfoTmp] = Case2_selectFileFunc(taskID,taskNum,fileInfo,uniChunk,storageChunks,capacityLeft,storageChunksAll)
% 并行cluster选择Jaccard距离最小的k个文件

if nargin < 7
    storageChunksAll = storageChunks;
end

% 该子任务的file_index起始位置
subTask_start = floor(size(fileInfo,1)/taskNum)*(taskID-1) + 1;
% 该子任务的file_index结束位置
if taskID == taskNum
    % 如果是最后一个任务
    subTask_end = size(fileInfo,1);
else
    subTask_end = floor(size(fileInfo,1)/taskNum) * taskID;
end
    
% 该子任务只考虑fileInfo的部分数据
fileInfoTmp = fileInfo(subTask_start : subTask_end, :);
for i = 1 : size(fileInfoTmp,1)
    % 该文件没有被标记存储过
    if fileInfoTmp.select(i) == false
        selectChunk = fileInfoTmp.chunk{i};
        % 计算每个文件与当前存储数据的增量size
        Locb = selectChunk.chunkID;
        
        deltaSize = sum(uniChunk.size(Locb(storageChunksAll(Locb) == false)));

%         % 这段代码等价于以下代码：
%         deltaSize = 0;
%         for j = 1:length(Locb)
%             if storageChunksAll(Locb(j)) == false
%                 deltaSize = deltaSize + uniChunk.size(Locb(j));
%             end
%         end

        % 用if判断一下，减少计算量
        if nargin < 7
            storageSize = deltaSize;
        else
            storageSize = sum(uniChunk.size(Locb(storageChunks(Locb) == false)));
        end

        % 检查剩余空间是否能够存储该文件
        if capacityLeft >= storageSize
            % 如果能够存储得下该行的文件，则计算并更新heatDsize
            fileInfoTmp.heatDsize(i) = fileInfoTmp.heat(i)/deltaSize;
        else
            % 如果该行文件deltasize太大，已经存不下，则那把它的heatDsize置位0
            fileInfoTmp.heatDsize(i) = 0;
            % 同时标记上该文件，便于Case1_selectFile函数的while循环判断
            fileInfoTmp.select(i) = true;
        end
    else
        % 如果被标记过，那把它的heatDsize置位0
        fileInfoTmp.heatDsize(i) = 0;
    end

end





end

