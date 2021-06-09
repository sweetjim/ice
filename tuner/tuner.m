function tuner
%% Tuner                        
% A GUI intended for detecting the edges of an ice-face that is immersed in
% a fluid. The pipeline for extracting the edge vector is as follows: 
% 
% 1. Filtering: Vignette correction and Guassian averaging convolution to
% raise or lower image contrast or detectable features.
% 
% 2. Detection: Edge detection algorithms (Canny, Sobel, Prewitt, log) with
% threshold and sigma argument tuning to isolate dominate edges in image.
% 
% 3. Dilation: Artificial dilation of non-sparse binary image pixels, with
% median filter adjustment and isolated pixel neighbourhood deletion to
% join dominate detected edges and omit erroneous features.
% 
% 4. Connectivity: Detection of longest edges with smoothing tuner, can
% select 'leading' edge (greatest connection at higher x-coordinates).

%% Premable         (Figures)   
warning off

screen      = get(0,'screensize');
p           = [screen(3)/2 32 screen(3)/2 screen(4)-62]; % split-half

fig         = uifigure('Name','Tuner Controls',...
    'Position',[80 80 screen(3)*.4 screen(4)*.3],...
    'Resize','on',...
    'CloseRequestFcn',@fig_close);

image_fig   = figure('Name','Tuner Output',...
    'Position',p,...
    'Resize','on',...
    'WindowStyle','docked',...
    'CloseRequestFcn',@fig_close);

tunercache  = fullfile(cd,'functions','tuner','cache','tuner_cache.mat');
%% Variables                    
xi      = [];
yi      = [];
%% Design                       
g       = uigridlayout(fig,...
    'RowHeight',{'2x'},...
    'ColumnWidth',{'1x'});
ax                  = axes(image_fig);
gl                  = uigridlayout(g,[1 2],'ColumnWidth',{'1x','3x'});
disableDefaultInteractivity(ax);

[files,image]       = getData;


on_screen_output    = image;
rotation            = 0;
ROI0                = [1 1 size(image,1) size(image,2)];
ROI                 = ROI0;
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
    {'Original','Filter','Detection','Combined','Dilate','Connectivity'},...
    'Value','Combined',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
method_list = uidropdown(gl_buts,'Items',...
    {'Sobel','Prewitt','Roberts','log','Canny'},'Value','Canny',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
edge_list = uidropdown(gl_buts,'Items',...
    {'Edge','Dilate'},'Value','Edge',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
%% Tabs                         
tabg            = uitabgroup(gl);
tab_images      = uitab(tabg,'Title','Images');
tab_fiters      = uitab(tabg,'Title','Filters');
tab_detection   = uitab(tabg,'Title','Detection');
tab_dilate      = uitab(tabg,'Title','Dilate');
tab_connect     = uitab(tabg,'Title','Connectivity');
tab_movie       = uitab(tabg,'Title','Movie');
%% Image        Tab (p0)        
gl_image        = uigridlayout(tab_images,[3 1]);
gl_image_vars   = uigridlayout(gl_image,'ColumnWidth',{'1x','4x'});
uilabel(gl_image_vars,'Text','Image number');

image_sld = uislider(gl_image_vars,...
    'Limits',[1 length(files)],...
    'Value',1,...
    'MajorTicks',1:round(length(files)/4):length(files),...
    'ValueChangedFcn',...
    @(sld,event) image_sld_move(event,ax));

image_sld.MajorTickLabels{1} = '1';
   
gl_image_rot    = uigridlayout(gl_image,[1 4],...
    'RowHeight',{'3x','1x'},...
    'ColumnWidth',{'1x','1x','1x','1x'});

rot_label       = uilabel(gl_image_rot,'Text',sprintf('Rotation (%i)',rotation));

uibutton(gl_image_rot,...
    'Text','Clockwise',...
    'ButtonPushedFcn',@rot_c_push);

uibutton(gl_image_rot,...
    'Text','Counter-clockwise',...
    'ButtonPushedFcn',@rot_cc_push);

gl_image_roi    = uigridlayout(gl_image,[1 4],...
    'RowHeight',{'3x','1x'},...
    'ColumnWidth',{'1x','1x','1x','1x'});

uilabel(gl_image_roi,'Text','Region of interest');
uibutton(gl_image_roi,...
    'Text','Set',...
    'ButtonPushedFcn',@ROI_push);
uibutton(gl_image_roi,...
    'Text','Reset',...
    'ButtonPushedFcn',@ROI_reset_push);
%% Filter       Tab (p1)        
gl_filter_vars     = uigridlayout(tab_fiters,[2 3],...
    'RowHeight',{'1x','1x','1x'},...
    'ColumnWidth',{'1x','3x'});
uilabel(gl_filter_vars,'Text','Vignette correction','HorizontalAlignment','center');
flatfield_sld = uislider(gl_filter_vars,...
    'Limits',[0 100],...
    'Value',10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(gl_filter_vars,'Text','Guassian Filter (Y)','HorizontalAlignment','center');
gauss_x_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(gl_filter_vars,'Text','Guassian Filter (X)','HorizontalAlignment','center');
gauss_y_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',2,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
%% Detection    Tab (p2)        
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
%% Dilate       Tab (p3)        
gl_freq_vars     = uigridlayout(tab_dilate,[3 2],...
    'ColumnWidth',{'1x','4x'});
uilabel(gl_freq_vars,'Text','Dilation factor');
dilation_sld = uislider(gl_freq_vars,...
    'Limits',[1 10],...
    'Value',1,...
    'MajorTicks',0:10,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(gl_freq_vars,'Text','Median-filtering');
dilation_medfilt_sld = uislider(gl_freq_vars,...
    'Limits',[1 10],...
    'MajorTicks',1:10,...
    'Value',1,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

uilabel(gl_freq_vars,'Text','Pixel area deletion');
dilation_area_sld = uislider(gl_freq_vars,...
    'Limits',[1 5000],...
    'MajorTicks',0:500:5000,...
    'Value',1,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));
%% Connectivity Tab (p4)        

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
    'Limits',[0 500],...
    'Value',1,...
    'MajorTicks',0:50:500,...
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
image = loadimage(files,round(image_sld.Value),rotation);
updateAxes(ax)
clc
%% Functions        (Pipeline)  
    function out = apply_p1_Filters
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
    function out = apply_p2_EdgeDetection(in)
        switch method_list.Value
            case {'Sobel','Prewitt','Roberts'}
                out = edge(in,method_list.Value,thres_sld.Value);
            case {'Canny','log'}
                out = edge(in,method_list.Value,thres_sld.Value,sigma_sld.Value);
        end
    end
    function out = apply_p2_FilterAndEdge
        out = apply_p2_EdgeDetection(apply_p1_Filters);
    end
    function out = apply_p3_Dilation(in)
       out = imdilate(in,true(round(dilation_sld.Value)));
       out = medfilt2(out,[1 1].*round(dilation_medfilt_sld.Value));
       out = bwareaopen(out,round(dilation_area_sld.Value));
    end
    function [out,xi,yi] = apply_p4_Connectivity
        switch edge_list.Value
            case 'Edge'
                out  = apply_p2_EdgeDetection(apply_p1_Filters);
            case 'Dilate'
                out = bwmorph(apply_p3_Dilation(apply_p2_FilterAndEdge),'remove');
        end        
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
    end
%% Functions        (Misc)      
    function [files,imout]= getData
        addpath(fullfile(cd,'functions'))
        folder  = uigetdir(fullfile(cd,'photos')); %cd must be experiment directory
        if ~folder
           disp('Nothing selected, loading last file')
           tmp = load(tunercache);
           files = tmp.args.files;
        else
            files   = dir(folder);
            files   = files(3:end);
        end
        imout   = loadimage(files,1,0);
        imagesc(ax,imout)
%         axis(ax,'image')
    end
%% UI & Initialization          
    function fig_close(src,callbackdata)
        close(fig);
        close(image_fig)
    end
    function setvars
        if ~isfile(strcat(files(1).folder,'.mat'))
            load(tunercache,'args')
        else
            load(strcat(files(1).folder,'.mat'))
        end
        method_list.Value   = args.method.edge;
        switch method_list.Value
            case {'Sobel','Prewitt','Roberts'}
                thres_sld.Limits = [0 10];
            case {'Canny','log'}
                thres_sld.Limits = [0 1];
        end
        edge_list.Value     = args.method.connect;
        try
        connect_list.Value  = args.method.submethod;
        thres_sld.Value     = args.filter.thres;
        sigma_sld.Value     = args.filter.sigma;
        flatfield_sld.Value = args.filter.flatfield;
        gauss_x_sld.Value   = args.filter.gaussfilt(1);
        gauss_y_sld.Value   = args.filter.gaussfilt(2);
        connect_sld.Value   = args.connect.connectivity;
        connect_smooth_sld.Value    = args.connect.smooth;
        rotation                    = args.rotation;
        dilation_sld.Value          = args.dilation.factor;
        dilation_medfilt_sld.Value  = args.dilation.filter;
        dilation_area_sld.Value     = args.dilation.area;
        catch
            
        end            
        
%         fft_smooth_sld.Value    = args.fft_smooth;
%         fft_thres_sld.Value     = args.fft_reject;
        updateAxes(ax)
    end
    function gridspace(parent,n)
        for i=1:n
            uilabel(parent,'Text','');
        end
    end
%% Callbacks        (Axes)      
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

        %% Output cases
        switch view_list.Value 

            case 'Original'
                on_screen_output = image;
                imagesc(ax,image)
                cLIM = [0 150];
            case 'Filter'
                out = apply_p1_Filters;
                on_screen_output = out;
                imagesc(ax,out)
                cLIM = [30 140];%[-Inf Inf];
            case 'Detection'
                out = apply_p2_EdgeDetection(image);
                on_screen_output = out;
                imagesc(ax,out)
                cLIM = [0 1];
            case 'Combined'
                out = apply_p2_EdgeDetection(apply_p1_Filters);
                on_screen_output = out;
                imagesc(ax,out)
                cLIM = [0 1];
            case 'Dilate'
                out = apply_p3_Dilation(apply_p2_FilterAndEdge);
                imagesc(ax,out)
                on_screen_output = out;
                cLIM = [0 1];
            case 'Connectivity'
                [out,xi,yi] = apply_p4_Connectivity;       
                switch connect_but.Value
                    case 1
                        imagesc(ax,image)
                        cLIM = [0 256];
                    case 0
                        imagesc(ax,out)
                        cLIM = [0 1];
                end
                hold(ax,'on')
                plot(ax,xi,yi,'--r')
                hold(ax,'off')
                on_screen_output = out;

        end
        colormap(ax,'gray')
        colorbar(ax)
        caxis(ax,cLIM)
%         toc
    end  
%% Callbacks        (Sliders)   
    function image_sld_move(event,ax)
        image = imcrop(loadimage(files,round(image_sld.Value),rotation),ROI);
        updateAxes(ax);
    end
    function sld_move(event,ax)
        updateAxes(ax)
    end
%% Callbacks        (Lists)     
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
%% Callbacks        (Buttons)   
    function save_push(PushButton,event)
        %% Output
        
        filtertab = struct(...
            'thres',thres_sld.Value,...
            'sigma',sigma_sld.Value,...
            'flatfield',flatfield_sld.Value,...
            'gaussfilt',[gauss_x_sld.Value gauss_y_sld.Value]);
        methods = struct(...
            'edge',method_list.Value,...
            'connect',edge_list.Value,...
            'submethod',connect_list.Value);     
        connect = struct(...
            'connectivity',round(connect_sld.Value),...
            'smooth',connect_smooth_sld.Value);
        dilation = struct(...
            'factor',round(dilation_sld.Value),...
            'filter',round(dilation_medfilt_sld.Value),...
            'area',round(dilation_area_sld.Value));
        args = struct(...
            'files',files,....
            'roi',ROI,...
            'filter',filtertab,...
            'method',methods,...
            'connect',connect,...
            'dilation',dilation,...
            'rotation',rotation,...
            'edge',struct('x',interpolate(xi,image,1),'y',interpolate(yi,image,1)),...
            'out',on_screen_output,...
            'in',image);
    
        assignin('base','args',args);
        
        %% Cache file
        save(tunercache,'args')
        save(files(1).folder,'args')

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
        rotation    = rotation-1;
        ROI         = [1 1 size(image,1) size(image,2)];
        image = imcrop(loadimage(files,round(image_sld.Value),rotation),ROI);
        [gauss_x_sld.Value, gauss_y_sld.Value] = deal(gauss_y_sld.Value,gauss_x_sld.Value);
        updateAxes(ax)
    end
    function rot_cc_push(PushButton,event)
        rotation    = rotation + 1;
        ROI         = [1 1 size(image,1) size(image,2)];
        image = imcrop(loadimage(files,round(image_sld.Value),rotation),ROI);
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
        image = loadimage(files,round(image_sld.Value),rotation);
        updateAxes(ax)
    end
end