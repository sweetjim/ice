function fout   = edgefilter(in,filterko,clim,mode)
%%
% try ~isempty(clip)&&~isempty(clim);catch;clip=0.02;clim=.1;end
F       = fftshift(fft2(double(in)));
Fabs    = abs(F);
%%
switch mode
    case 'intensity'
        mask    = Fabs>filterko*max(Fabs,[],'all');
        fout    = ifft2(fftshift(F.*mask));
        fout    = fout-min(fout,[],'all');
        fout    = fout/max(fout,[],'all');
        fout    = fout>clim;
    case 'frequency'       
        %%
        
        clip    = [20 50];
        filterko    = [-1 1 -1 1].*[clip(1).*[1 1] clip(2).*[1 1]]-0.5;
        n       = floor((size(F)+1)/2)*2;
        k       = -n(2)/2:n(2)/2-1; dk = mean(diff(k));
        o       = -n(1)/2:n(1)/2-1; do = mean(diff(o));
        regionk = (k>filterko(1)&k<filterko(2));
        regiono = (o>filterko(3)&o<filterko(4));
        mask    = ones(size(Fabs));
        mask(:,regionk) = 0;
        mask(regiono,:) = 0;
%         mask = imgaussfilt(mask,2);
        fout    = ifft2(fftshift(F.*~mask));
%         fout    = fout./max(fout,[],'all');
        
        tiledlayout(1,2)
        nexttile
        imagesc(log10(Fabs.*mask))
        nexttile
        imagesc(real(fout))

    case 'blur'
        mask    = Fabs;%double(Fabs./max(Fabs,[],'all')>.01);
        mask    = imgaussfilt(mask,[3,7]);
        fout    = ifft2(fftshift(F.*mask));
        fout    = fout./max(fout,[],'all');
%         fout    = fout>clim;
    case 'adapt'
        %%
        figure(1)
        tiledlayout(1,3)
        perc        = 0.7125*1e-2;
        mask_int    = Fabs>perc/100*max(Fabs,[],'all');
        
        nexttile(1)
        imagesc(mask_int)
        title(sprintf('(%s %s)','$\hat{f}>$',strcat(notation(perc),' \%')),'Interpreter','latex')
        
        clip    = [10 10];
        filterko    = [-1 1 -1 1].*[clip(1).*[1 1] clip(2).*[1 1]]-0.5;
        n       = floor((size(F)+1)/2)*2;
        k       = -n(2)/2:n(2)/2-1; dk = mean(diff(k));
        o       = -n(1)/2:n(1)/2-1; do = mean(diff(o));
        regionk = (k>filterko(1)&k<filterko(2));
        regiono = (o>filterko(3)&o<filterko(4));
        mask    = ones(size(Fabs));
        mask(:,regionk) = 0;
        mask(regiono,:) = 0;
        
        [X,Y] = meshgrid(k,o);
        R2  = X.^2+Y.^2;
        mask_circ = R2<60^2;
        
        mask = ~(mask.*mask_circ).*mask_int;
%         mask = imgaussfilt(mask,2);
%         fout    = ifft2(fftshift(F.*~mask));
%         fout    = fout./max(fout,[],'all');

        mask = imgaussfilt(double(~mask),2);

        fout    = real(ifft2(fftshift(F.*mask)));
        fout    = fout-min(fout,[],'all');
        fout    = fout/max(fout,[],'all');
%         fout    = fout>clim;
        
        nexttile(2)
        imagesc(mask_int.*mask_circ)
        title(sprintf('(%.2f%s%.2f, %.2f%s%.2f)',...
            filterko(1),'$<k<$',filterko(2),...
            filterko(3),'$<l<$',filterko(4)),...
            'interpreter','latex')
        nexttile(3)
        imagesc(log10(Fabs.*mask))
        colorbar
        title('Combined','Interpreter','latex')
        
        figure(2)
        tiledlayout(1,2)
        nexttile
        imagesc(imflatfield(in,20))
        cmocean('gray')
        nexttile
        imagesc(imflatfield(fout,20))
        colorbar
        cmocean('gray')
        
    case 'sobel'
        idx     = find(sum((log10((abs(fft(in)).^2))>-5),1)==0,1);
        mask    = ones(size(in));
        mask(:,idx:end) = 0;
        fout    = mask.*in;
end
pts = in-abs(real(fout))>.8;%[row,col] = find(pts);

fout = real(fout); % Ignore erroneous machine precision complex values
% clf;imagesc(im0); hold on; plot(col,row,'.r');
end