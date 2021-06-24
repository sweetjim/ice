function tunerWIP
%% Tuner
% A GUI program for detecting edges in an image. Control options include 
% filtering through Gaussian convolution and flat-field correction, edge
% detection methods such as 'Canny' and 'Sobel', and binary image (sparse)
% connectivity. 
%% Premable
warning off

screen  = get(0,'screensize');
% w       = screen(3)*.75;
% h       = screen(4)*.75;
p       = [screen(3)/2 32 screen(3)/2 screen(4)-62]; % split-half
title_str = 'Tune edge detection (dynamic)';
fig     = uifigure('Position',p,'Name',title_str,...
                    'Resize','on','CloseRequestFcn',@fig_close);
dims    = fig.Position(3:4).*[.95 .85];
tunercache = fullfile(cd,'functions','tuner','cache','tuner_cache.mat');
%% Variables
xi      = [];
yi      = [];
roi_mask= [];
roi     = [];
invert  = false;
%% Design
g       = uigridlayout(fig,...
    'RowHeight',{'4x','2x'},...
    'ColumnWidth',{'1x'});

% Axes
ax      = uiaxes(g,'Position',[10 100 dims(1) dims(2)]);
disableDefaultInteractivity(ax);
gl      = uigridlayout(g,[1 2],'ColumnWidth',{'1x','3x'});

[files,image]= getData;
rotation = 0;
ROI0 = [1 1 size(image,1) size(image,2)];
ROI = ROI0;
%% Side Buttons
gl_buts     = uigridlayout(gl,[5 1],...
    'RowHeight',{'1x','1x'});
uibutton(gl_buts,...
    'Text','Save',...
    'ButtonPushedFcn',@save_push);
uibutton(gl_buts,...
    'Text','Folder',...
    'ButtonPushedFcn',@getfiles_push);
view_list = uidropdown(gl_buts,'Items',...
    {'Original','Filter','Detection','Frequency','Combined','Connectivity'},...
    'Value','Combined',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
method_list = uidropdown(gl_buts,'Items',...
    {'Sobel','Prewitt','Roberts','log','Canny'},'Value','Canny',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
edge_list = uidropdown(gl_buts,'Items',...
    {'Edge','Frequency'},'Value','Edge',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
% uibutton(gl_buts,...
%     'Text','Refresh',...
%     'ButtonPushedFcn',@state_push);
%% Tabs
tabg            = uitabgroup(gl);
tab_images      = uitab(tabg,'Title','Images');
tab_fiters      = uitab(tabg,'Title','Filters');
tab_detection   = uitab(tabg,'Title','Detection');
tab_freq        = uitab(tabg,'Title','Frequency');
tab_connect     = uitab(tabg,'Title','Connectivity');
tab_movie       = uitab(tabg,'Title','Movie');
%% Image Tab
gl_image     = uigridlayout(tab_images,[3 1]);
gl_image_vars = uigridlayout(gl_image,'ColumnWidth',{'1x','4x'});
uilabel(gl_image_vars,'Text','Image number');

image_sld = uislider(gl_image_vars,...
    'Limits',[1 length(files)],...
    'Value',1,...
    'MajorTicks',1:round(length(files)/4):length(files),...
    'ValueChangedFcn',...
    @(sld,event) image_sld_move(event,ax));

image_sld.MajorTickLabels{1} = '1';
   
gl_image_rot = uigridlayout(gl_image,[1 4],'RowHeight',{'3x','1x'},'ColumnWidth',{'1x','1x','1x','1x'});

rot_label = uilabel(gl_image_rot,'Text',sprintf('Rotation (%i)',rotation));

uibutton(gl_image_rot,...
    'Text','Clockwise',...
    'ButtonPushedFcn',@rot_c_push);

uibutton(gl_image_rot,...
    'Text','Counter-clockwise',...
    'ButtonPushedFcn',@rot_cc_push);

gl_image_roi = uigridlayout(gl_image,[1 4],'RowHeight',{'3x','1x'},'ColumnWidth',{'1x','1x','1x','1x'});

uilabel(gl_image_roi,'Text','Region of interest');
uibutton(gl_image_roi,...
    'Text','Set',...
    'ButtonPushedFcn',@ROI_push);
uibutton(gl_image_roi,...
    'Text','Reset',...
    'ButtonPushedFcn',@ROI_reset_push);
%% Filter Tab 
gl_filter_vars     = uigridlayout(tab_fiters,[3 2],...
    'RowHeight',{'1x','2x'},...
    'ColumnWidth',{'1x','1x','1x'});
uilabel(gl_filter_vars,'Text','Vignette correction','HorizontalAlignment','center');
uilabel(gl_filter_vars,'Text','Guassian Filter (Y)','HorizontalAlignment','center');
uilabel(gl_filter_vars,'Text','Guassian Filter (X)','HorizontalAlignment','center');

flatfield_sld = uislider(gl_filter_vars,...
    'Limits',[0 100],...
    'Value',10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

gauss_x_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
gauss_y_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',2,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
%% Detection Tab
% Sliders
gl_detect_vars     = uigridlayout(tab_detection,[2 2],...
    'ColumnWidth',{'1x','4x'});
uilabel(gl_detect_vars,'Text','Threshold');
thres_sld = uislider(gl_detect_vars,...
    'Limits',[0 1],...
    'Value',1e-3,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(gl_detect_vars,'Text','Sigma');
sigma_sld = uislider(gl_detect_vars,...
    'Limits',[0 30],...
    'Value',1e-3,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
%% Frequency tab
gl_freq_vars     = uigridlayout(tab_freq,[3 2],...
    'ColumnWidth',{'1x','4x'});
uilabel(gl_freq_vars,'Text','FFT Coefficient Rejection (%)');
fft_thres_sld = uislider(gl_freq_vars,...
    'Limits',[0 1],...
    'Value',0.5,...
    'MajorTicks',0:.1:1,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
uilabel(gl_freq_vars,'Text','Smoothing');
fft_smooth_sld = uislider(gl_freq_vars,...
    'Limits',[1 10],...
    'MajorTicks',1:10,...
    'Value',1,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

fft_but = uibutton(gl_freq_vars,'state',...
    'Text','ROI',...
    'Value',false,...
    'ValueChangedFcn',@(btn,event) fft_roi_push(event,ax));
%% Connectivity Tab

gl_connect     = uigridlayout(tab_connect,[3 1],...
    'RowHeight',{'1x','1x','1x'});

g1_connect_vars = uigridlayout(gl_connect,[1 2],...
    'ColumnWidth',{'1x','4x'});

uilabel(g1_connect_vars,'Text','Connections');
connect_sld = uislider(g1_connect_vars,...
    'Limits',[1 10],...
    'Value',1,...
    'MajorTicks',1:10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(g1_connect_vars,'Text','Smoothing');

connect_smooth_sld = uislider(g1_connect_vars,...
    'Limits',[0 100],...
    'Value',1,...
    'MajorTicks',0:10:100,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

g1_connect_buts = uigridlayout(gl_connect,[1 2],...
    'ColumnWidth',{'1x','3x'});

connect_but = uibutton(g1_connect_buts,'state',...
    'Text','Original',...
    'Value',false,...
    'ValueChangedFcn',@(btn,event) sld_move(event,ax));
connect_list = uidropdown(g1_connect_buts,'Items',...
    {'None','Connectivity leading','Leading'},'Value','None',...
    'ValueChangedFcn',@(sld,event) sld_move(event,ax));
%% Movie tab
gl_movie = uigridlayout(tab_movie,[3 4]);

uilabel(gl_movie,'Text','Step');

step_edit = uieditfield(gl_movie,'numeric','RoundFractionalValues','on',...
    'Value',1,'Limits',[1 10]);
gridspace(gl_movie,2)
uilabel(gl_movie,'Text','Pause time');
pause_edit = uieditfield(gl_movie,'numeric',...
    'Value',.1,'Limits',[1e-3 10]);
gridspace(gl_movie,4)
play_but = uibutton(gl_movie,'state','Value',0,'Text','Play','ValueChangedFcn',...
    @movie_push);
stop_but = uibutton(gl_movie,'state','Value',0,'Text','Stop','ValueChangedFcn',...
    @movie_push);
%% Last executables
if isfile(tunercache)
   setvars
end
updateAxes(ax)
clc
%% Functions
    function out = applyFilt
        if (gauss_x_sld.Value==0&&flatfield_sld.Value==0)||(gauss_y_sld.Value==0&&flatfield_sld.Value==0)
            out  = image;
        elseif flatfield_sld.Value==0
            out = imgaussfilt(image,round([gauss_x_sld.Value gauss_y_sld.Value]));
        elseif gauss_x_sld.Value==0||gauss_y_sld.Value==0
            out = imflatfield(image,round(flatfield_sld.Value));
        else
            out = imgaussfilt(imflatfield(image,round(flatfield_sld.Value)),...
                round([gauss_x_sld.Value gauss_y_sld.Value]));
        end
    end
    function out = applyEdgeDetection(in)
        switch method_list.Value
            case {'Sobel','Prewitt','Roberts'}
                out = edge(in,method_list.Value,thres_sld.Value);
            case {'Canny','log'}
                out = edge(in,method_list.Value,thres_sld.Value,sigma_sld.Value);
        end
    end
    function out = applyEdgeMethod
        out = applyEdgeDetection(applyFilt);
    end
    function [files,imout]= getData
        addpath(fullfile(cd,'functions'))
        folder  = uigetdir(fullfile(cd,'photos')); %cd must be experiment directory
        if ~folder
           disp('Nothing selected')
           return
        end
        files   = dir(folder);
        files   = files(3:end);
        imout   = loadimage(files,1,0);
        imagesc(ax,imout)
        axis(ax,'tight')
    end
    function fout = freqFilter(in)
        F       = fftshift(fft2(double(in)));
        Fabs    = abs(F);
        mask    = Fabs>fft_thres_sld.Value*max(Fabs,[],'all')*1e-3;
        n       = floor((size(F)+1)/2)*2;
        k       = -n(2)/2:n(2)/2-1; dk = mean(diff(k));
        o       = -n(1)/2:n(1)/2-1; do = mean(diff(o));
        
        if fft_but.Value
           mask = mask.*roi_mask;
           if invert
              mask = ~mask; 
           end
        end
                
        fout    = (ifft2(fftshift(F.*mask)));
        fout    = fout-min(fout,[],'all');
        fout    = real(fout/max(fout,[],'all'));
        fout    = double(imgaussfilt(double(fout),round(fft_smooth_sld.Value))>.1);
        return
    end
%% UI & Initialization
    function fig_close(src,callbackdata)
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection
            case 'Yes'
                state = 0;
                closereq();
            case 'No'
                return
        end
    end
    function fig_close_fft_roi(src,callbackdata)
        closereq();
        fft_but.Value = 0;
    end
    function setvars
        if ~isfile(strcat(files(1).folder,'.mat'))
            load(tunercache,'args')
        else
            load(strcat(files(1).folder,'.mat'))
        end
        method_list.Value   = args.edgemethod;
        switch method_list.Value
            case {'Sobel','Prewitt','Roberts'}
                thres_sld.Limits = [0 10];
            case {'Canny','log'}
                thres_sld.Limits = [0 1];
        end
        edge_list.Value     = args.connectmethod;
        connect_list.Value  = args.connectsubmethod;
        thres_sld.Value     = args.thres;
        sigma_sld.Value     = args.sigma;
        flatfield_sld.Value = args.flatfield;
        gauss_x_sld.Value   = args.gaussfilt(1);
        gauss_y_sld.Value   = args.gaussfilt(2);
        connect_sld.Value   = args.connectivity;
        connect_smooth_sld.Value = args.connect_smooth;
        rotation            = args.rotation;
        
        fft_smooth_sld.Value    = args.fft_smooth;
        fft_thres_sld.Value     = args.fft_reject;
        updateAxes(ax)
    end
    function gridspace(parent,n)
        for i=1:n
            uilabel(parent,'Text','');
        end
    end
%% Callbacks - Axes
    function updateAxes(ax)
%         tic;
        rot_label.Text = sprintf('Rotation (%i)',rotation);
        %% Slider error-passers
        if thres_sld.Value==0
            thres_sld.Value = 1e-9;
        elseif thres_sld.Value==1
            thres_sld.Value = 1-1e-9;
        end
        
        if sigma_sld.Value==0
            sigma_sld.Value = 1e-9;
        end        

        %% 
        switch view_list.Value 
            case 'Original'
                imagesc(ax,image)
            case 'Filter'
                out = applyFilt;
                imagesc(ax,out)
            case 'Detection'
                out = applyEdgeMethod;
                imagesc(ax,out)
            case 'Combined'
                out = applyEdgeDetection(applyFilt);
                imagesc(ax,out)
            case 'Connectivity'
                switch edge_list.Value
                    case 'Edge'
                        out  = applyEdgeDetection(applyFilt);
                    case 'Frequency'
                        out = edge(freqFilter(applyEdgeMethod));
                end
                switch connect_but.Value
                    case 1
                        imagesc(ax,image)
                    case 0
                        imagesc(ax,out)
                end
                hold(ax,'on')
                
                switch connect_list.Value
                    case 'Connectivity leading'
                        [yi,xi] = connectedge(out',round(connect_sld.Value));
                        yi      = gettop(yi,5);
                        [xi,yi] = deal(yi,xi);
                    case 'Leading'
                        [yi,xi] = find(out');
                        yi      = gettop(yi,5);
                        [xi,yi] = deal(yi,xi);
                    case 'None'
                        [yi,xi] = connectedge(out,round(connect_sld.Value));
                end
                
                if connect_smooth_sld.Value
                    xi = smooth(xi,connect_smooth_sld.Value);
                end
                plot(ax,xi,yi,'.r')
                hold(ax,'off')
            case 'Frequency'
                imagesc(ax,~freqFilter(applyEdgeMethod).*image)
        end
        colormap(ax,'gray')
%         toc
    end  
%% Callbacks - Sliders
    function image_sld_move(event,ax)
        image = imcrop(loadimage(files,round(image_sld.Value),rotation),ROI);
        updateAxes(ax);
    end
    function sld_move(event,ax)
        updateAxes(ax)
    end
%% Callbacks - Lists
    function list_change(event,ax)
        switch event.Value
            case {'Sobel','Prewitt','Roberts'}
                thres_sld.Limits = [0 10];
                sigma_sld.Enable = 'off';
            case {'Canny','log'}
                thres_sld.Limits = [0 1];
                sigma_sld.Enable = 'on';         
        end
        updateAxes(ax)
    end
%% Callbacks - Buttons
    function save_push(PushButton,event)
        %% Output
        out = applyFilt;
        out = applyEdgeDetection(out);
        
        args = struct(...
            'files',files,....
            'roi',ROI,...
            'thres',thres_sld.Value,...
            'sigma',sigma_sld.Value,...
            'flatfield',flatfield_sld.Value,...
            'gaussfilt',[gauss_x_sld.Value gauss_y_sld.Value],...
            'edgemethod',method_list.Value,...
            'connectmethod',edge_list.Value,...
            'connectsubmethod',connect_list.Value,...
            'connectivity',round(connect_sld.Value),...
            'connect_smooth',connect_smooth_sld.Value,...
            'rotation',rotation,...
            'out',out,...
            'detect',applyEdgeDetection(image),...
            'fft_reject',fft_thres_sld.Value,...
            'fft_smooth',fft_smooth_sld.Value,...
            'in',image);
    
        assignin('base','args',args);
        
        %% Cache file
        save(tunercache,'args')
        save(files(1).folder,'args')
        %% Print statements and closing
%         fprintf('Saved values:\n\tThres = %.2f \n\tSigma = %.2f \n\tFlatfield = %i\n\tGuassFilt = [%i %i]\n',...
%             thres_sld.Value,...
%             sigma_sld.Value,...
%             round(flatfield_sld.Value),...
%             round(gauss_x_sld.Value),round(gauss_y_sld.Value))
        
%         if waitstate
%             state = 1;
%             closereq();
%         end
end
    function state_push(PushButton,event)
        updateAxes(ax)
    end
    function ROI_push(PushButton,event)
       ROI      = getROI(image);
       image    = imcrop(image,ROI);
       updateAxes(ax);
    end
    function ROI_reset_push(PushButton,event)
        image = loadimage(files,round(image_sld.Value),rotation);
        ROI   = ROI0;
        updateAxes(ax);
    end
    function rot_c_push(PushButton,event)
        rotation    = mod(rotation-1,4);
        image       = rot90(image,rotation);
        roi_mask    = rot90(roi_mask,rotation);
        [gauss_x_sld.Value, gauss_y_sld.Value] = deal(gauss_y_sld.Value,gauss_x_sld.Value);
        updateAxes(ax)
    end
    function rot_cc_push(PushButton,event)
        rotation    = mod(rotation + 1,4);
        image       = rot90(image,rotation);
        roi_mask    = rot90(roi_mask,rotation);
        [gauss_x_sld.Value, gauss_y_sld.Value] = deal(gauss_y_sld.Value,gauss_x_sld.Value);
        updateAxes(ax)
    end
    function movie_push(PushButton,event)
        if play_but.Value
            for i=1:step_edit.Value:length(files)
                if i==1
                    args = struct(...
                        'thres',thres_sld.Value,...
                        'sigma',sigma_sld.Value,...
                        'flatfield',flatfield_sld.Value,...
                        'gaussfilt',[gauss_x_sld.Value gauss_y_sld.Value],...
                        'method',method_list.Value,...
                        'connectivity',round(connect_sld.Value));
                    play_but.Enable = 'off';
                end
                
                [out,xi,yi] = applytuner(loadimage(files,i,rotation),args);
                imagesc(ax,out)
                hold(ax,'on')
                plot(ax,xi,yi,'.r')
                hold(ax,'off')
                
                if stop_but.Value
                    play_but.Value = 0;
                    stop_but.Value = 0;
                    play_but.Enable = 'on';
                    break 
                end
                
                pause(pause_edit.Value)
            end
            play_but.Enable = 'on';
            play_but.Value = 0;
        end
    end
    function getfiles_push(PushButton,event)
        [files,image]   = getData;
        rotation        = 0;
        image_sld.Limits= [1 length(files)];
        image_sld.Value = 1;
        image_sld.MajorTicks            = 1:round(length(files)/5):length(files);%round(linspace(1,length(files),5),-1);
        image_sld.MajorTickLabelsMode   = 'auto' ;
        setvars;
        updateAxes(ax)
    end
    function fft_roi_push(event,ax)
        if fft_but.Value 
            roi_fig = uifigure('Position',p/3+[0 screen(4)/2 0 0],'Name','Fourier space',...
                'Resize','on','CloseRequestFcn',@fig_close_fft_roi);
            gl_roi = uigridlayout(roi_fig,'RowHeight',{'4x','1x'},'ColumnWidth',{'1x'});
            
            ax_fft = uiaxes(gl_roi);
            
            disableDefaultInteractivity(ax_fft);
            
            gl_roi_vars = uigridlayout(gl_roi,'RowHeight',{'1x'},'ColumnWidth',{'1x','1x'});
            roi_list = uidropdown(gl_roi_vars,'Items',{'Ellipse','Rectangle','Cross'},'Value','Ellipse','ValueChangedFcn',@(btn,event) draw_roi(event,ax_fft));
            invert_but = uibutton(gl_roi_vars,'state',...
                'Text','Invert',...
                'Value',false,...
                'ValueChangedFcn',@(btn,event) invert_push(event,ax));
            
            Fabs_roi    = abs(fftshift(fft2(image)));            
            plotFFTROI
            updateAxes_ROI(ax_fft)
        else
            
        end
        function updateAxes_ROI(ax2plot)
            plotFFTROI
            delete(roi)
            switch roi_list.Value
                case 'Ellipse'
                    roi = images.roi.Ellipse(ax2plot,'Center',fliplr(size(image)/2),'Semiaxes',[100 100]);
                    roi_mask = createMask(roi,Fabs_roi);
                case 'Rectangle'
                    roi = images.roi.Rectangle(ax2plot,...
                        'Rotatable',1,...
                        'Position',[size(image,2)*1/4 size(image,1)*1/4 size(image,2)/2 size(image,1)/2]);
                    roi_mask = createMask(roi,Fabs_roi);
                case 'Cross'
                    roi = images.roi.Rectangle(ax2plot,...
                        'Rotatable',1,...
                        'Position',[size(image,2)*1/4 size(image,1)*1/4 size(image,2)/2 size(image,1)/2]);
                    region_x    = round(roi.Position(1):(roi.Position(1)+roi.Position(3)));
                    region_y    = round(roi.Position(2):(roi.Position(2)+roi.Position(4)));
                    cross       = zeros(size(image));
                    cross(region_y,:) = 1;
                    cross(:,region_x) = 1;
                    hold(ax_fft,'on');
                    imagesc(ax_fft,log10(Fabs_roi).*cross)
                    hold(ax_fft,'off');
                    roi_mask = cross;
            end
            addlistener(roi,'ROIMoved',@(sld,event) roi_move(event,ax));
            addlistener(fft_thres_sld,'ValueChanged',@plotFFTROI);
        end
        function draw_roi(event,ax)
            updateAxes_ROI(ax)
        end
        function invert_push(event,ax)
            if invert_but.Value
                invert = 1;
            else
                invert = 0;
            end
            updateAxes(ax)
        end
        function roi_move(event,ax)
            switch roi_list.Value
                case {'Ellipse','Rectangle'}
                    roi_mask = createMask(roi,Fabs_roi);
                case 'Cross'
                    region_x    = round(roi.Position(1):(roi.Position(1)+roi.Position(3)));
                    region_y    = round(roi.Position(2):(roi.Position(2)+roi.Position(4)));
                    cross       = zeros(size(image));
                    cross(region_y,:) = 1;
                    cross(:,region_x) = 1;
                    hold(ax_fft,'on');
                    imagesc(ax_fft,fft_image.*cross)
                    hold(ax_fft,'off');
                    roi_mask = cross;
            end
            
            updateAxes(ax)
        end
        function plotFFTROI
            clim  = log10(fft_thres_sld.Value*max(Fabs_roi,[],'all')*1e-3);
            imagesc(ax_fft,log10(Fabs_roi));
            c = caxis(ax_fft);
            m = cmocean('balance','pivot',clim/c(2));close(gcf);
            idx = round(clim/c(2)*length(m));
            for i=idx:length(m);m(i,:,:) = [1 0 0];end
            colormap(ax_fft,m)
            colorbar(ax_fft)
            axis(ax_fft,'tight') 
        end
    end

end