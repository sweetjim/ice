function [out,xi,yi] = applytuner(args,varargin)
%% Apply Tuner
% This function applies the output arguments of the GUI program 'tuner'.
% Parameters include:
%   args: [struct] (Required)
%   method: [char] (Optional)
%       'filter'
%       'detection'
%       'combined'
%       'frequency'
%       'dilate'
%       'all' (default)
%   image: [double, logical, unit8, int] (Optional)
%       loadimage(args.files,1,args.rotation) (default)
%       image_no
%   output: [char](Optional)
%       'image'
%       'pipeline' 
%       'none' (default)


[method,in,output] = parseInput(varargin);

%% Inputs

in = imcrop(in,args.roi);

switch method
    case 'filter'
        out = apply_p1_Filters;
    case 'detection'
        out = apply_p2_EdgeMethod(in);
    case 'combined'
        out = apply_p2_EdgeMethod(apply_p1_Filters);
    case 'frequency'
        out = ~freqFilter(apply_p2_EdgeMethod(apply_p1_Filters));
    case 'dilate'
        out = apply_p3_Dilation(apply_p2_EdgeMethod(apply_p1_Filters));
    case 'all'
        out = apply_p_Pipeline;
end


%% Outputs

switch output
    case 'image'
        imagesc(out)
        clear out
    case 'pipeline'
        imagesc(out)
        hold on
        plot(xi,yi,'--r')
        hold off
        clear out xi yi
end

%% Functions
    function out = apply_p1_Filters
        if (args.filter.gaussfilt(1)==0&&args.filter.flatfield==0)||...
                (args.filter.gaussfilt(2)==0&&args.filter.flatfield==0)
            out  = in;
        elseif args.filter.flatfield==0
            out = imgaussfilt(in,...
                round([args.filter.gaussfilt(1) args.filter.gaussfilt(2)]));
        elseif args.filter.gaussfilt(1)==0||args.filter.gaussfilt(2)==0
            out = imflatfield(in,round(args.filter.flatfield));
        else
            out = imgaussfilt(imflatfield(in,round(args.filter.flatfield)),...
                round([args.filter.gaussfilt(1) args.filter.gaussfilt(2)]));
        end
    end
    function out = apply_p2_EdgeMethod(in)
        switch args.method.edge
            case {'Sobel','Prewitt','Roberts'}
                out = edge(in,args.method.edge,args.filter.thres);
            case {'Canny','log'}
                out = edge(in,args.method.edge,args.filter.thres,args.filter.sigma);
        end
    end
    function out = apply_p2_FilterAndEdge
        out = apply_p2_EdgeMethod(apply_p1_Filters);
    end
    function out = apply_p3_Dilation(in)
        out = imdilate(in,true(args.dilation.factor));
        out = medfilt2(out,[1 1].*args.dilation.filter);
        out = bwareaopen(out,args.dilation.area);
    end
    function out = apply_p_Pipeline
        switch args.method.connect
            case 'Edge'
                out  = apply_p2_EdgeMethod(apply_p1_Filters);
            case 'Dilate'
                out  =  bwmorph(apply_p3_Dilation(apply_p2_FilterAndEdge),'remove');
            case 'Frequency'
                out = edge(freqFilter(apply_p2_EdgeMethod(apply_p1_Filters)));
        end
        switch args.method.submethod
            case 'Connectivity leading'
                [yi,xi] = connectedge(out',args.connect.connectivity);
                yi      = gettop(yi,5);
                [xi,yi] = deal(yi,xi);
            case 'Leading'
                [yi,xi] = find(out');
                yi      = gettop(yi,5);
                [xi,yi] = deal(yi,xi);
            case 'None'
                [yi,xi] = connectedge(out,args.connect.connectivity);
        end
        if args.connect.smooth
            xi = smooth(xi,args.connect.smooth);
        end
        xi = interpolate(xi,out,1);
        yi = interpolate(yi,out,1);
        
    end
    function fout = freqFilter(in)
        F       = fftshift(fft2(double(in)));
        Fabs    = abs(F);
        mask    = Fabs>args.fft_reject*max(Fabs,[],'all')*1e-3;
        fout    = ifft2(fftshift(F.*mask));
        fout    = fout-min(fout,[],'all');
        fout    = fout/max(fout,[],'all');
        fout    = double(imgaussfilt(double(fout),round(args.fft_smooth))>.1);
        return
    end

%% Parsers
    function [method,in,output] = parseInput(varargin)
        method  = 'all';
        output  = 'none';
        in      = loadimage(args.files,1,args.rotation);
        
        items   = varargin{:};
        for i=1:length(items)
            switch items{i}
                case {'filter','detection','combined','frequency','dilate','all'}
                    method   = items{i};
                case {'image','pipeline'}
                    output   = items{i};
                otherwise
                    in       = items{i};
            end
        end
        
        if isinteger(int8(in))&&numel(in)==1
            if in<1
                in=1;
            elseif in>length(args.files)
                in=length(args.files);
            end
            in = loadimage(args.files,in,args.rotation);
        else
            in = double(in);
        end

        
    end
end

