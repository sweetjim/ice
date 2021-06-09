function [x,y]  = connectedge(in,n,varargin)
if nargin>2
    matrix = varargin{1};
else 
    matrix = 8;
end
biggest_n   = n;
CC          = bwconncomp(in,matrix);
numPixels   = cellfun(@numel,CC.PixelIdxList);
[~,idx] = sort(numPixels,'descend');
if isempty(idx);x = NaN;y=x;return;end
if biggest_n>length(idx);biggest_n=length(idx);end
list    = idx(1:biggest_n);
for i=1:CC.NumObjects
   if ~sum(i==list)>0
       in(CC.PixelIdxList{i}) = 0;
   end
end
[x,y] = find(in);
end