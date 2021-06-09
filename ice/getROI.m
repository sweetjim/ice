function ROI = getROI(im,varargin)
if nargin>1
    a = varargin{1};
else
    f=figure('Name','ROI');
    a=axes(f);
end
S = [size(im,2)*1/4 size(im,1)*1/4 size(im,2)/2 size(im,1)/2];

imagesc(a,im);
colormap gray
h = imrect(a, S);
addNewPositionCallback(h,@(p) title(mat2str(p,3)));
fcn = makeConstrainToRectFcn('imrect',get(a,'XLim'),get(a,'YLim'));
setPositionConstraintFcn(h,fcn)
position = wait(h);
if isempty(position)
    ROI = [1 1 size(im,1) size(im,2)];
    return
end
[~,ROI] = imcrop(im,position);
ROI     = round(ROI);
if nargin==1
    close(f)
end
end