function out = interpolate(vec,im,dim)
out = imresize(vec,[size(im,dim) 1]);
end