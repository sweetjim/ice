function image = loadimage(files,index,varargin)
image = double(imread(fullfile(files(3).folder,files(index).name)));

if nargin>2
    
   image = rot90(image,varargin{1}); 
end
end

