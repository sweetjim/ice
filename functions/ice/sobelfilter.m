function fout = sobelfilter(in)
idx     = find(sum((log10((abs(fft(in)).^2))>-5),1)==0,1);
mask    = ones(size(in));
mask(:,idx:end) = 0;
fout    = mask.*in;
end

