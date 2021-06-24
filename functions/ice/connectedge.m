function [x,y]  = connectedge(in,n)
%% Connect Edge
% 
% -------------------------------------------------------------------------
% %  Parameters:
% -------------------------------------------------------------------------
%  in: [binary image] (Required)
%   The input binary image (assumed to have a long)
%
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

%%


%%
biggest_n   = n;
CC          = bwconncomp(in,8);
numPixels   = cellfun(@numel,CC.PixelIdxList);
[~,idx]     = sort(numPixels,'descend');

if isempty(idx)
    x   = NaN;
    y   = x;
    return
end

if biggest_n>length(idx)
    biggest_n=length(idx);
end

list    = idx(1:biggest_n);

for i=1:CC.NumObjects
   if ~sum(i==list)>0
       in(CC.PixelIdxList{i}) = 0;
   end
end
% imagesc(in)
%%
% clc
H = zeros(size(in,1),1);

for i=1:size(in,1)
    [~,idx] = find(in(i,:),1,'last');
    if isempty(idx)
       idx = 0; 
    end
    H(i)=idx;
end
%%
% dim = size(in);
% col = 1;
% row = find(in(:,1),1,'first');
% 
% boundary = bwtraceboundary(in,[row col],'N')
% 
% tiledlayout(1,2)
% nexttile
% plot((boundary(:,1)))
% nexttile
% plot(boundary(:,2),boundary(:,1))
%%
x = H;
y = 1:size(in,2);
end