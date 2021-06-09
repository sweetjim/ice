function state  = tuner(image,waitstate)
%% Tuner
% A GUI program for detecting edges in an image. Control options include filtering
% through Gaussian convolution and flat-field correction, as well as edge
% detection methods such as 'Canny' and 'Sobel'. If a waitstate argument is
% parsed, the program will block all commands in Matlab until the GUI is
% closed or has been saved. 
% 
% Parameters:
% * image: [double, unit8] the image to be processed.
% 
% * waitstate: [logical] enables or disables a dynamic environment where
% Matlab commands are available (0) or blocked (1).

%% Preamble 

screen  = get(0,'screensize');
w       = screen(3)*.75;
h       = screen(4)*.75;
if waitstate
    title_str = 'Tune edge detection';
else
    title_str = 'Tune edge detection (dynamic)';
end
fig     = uifigure('Position',[w/2 h/5 w/2 h],'Name',title_str,...
                    'Resize','on','CloseRequestFcn',@fig_close);
dims    = fig.Position(3:4).*[.95 .85];

%% Design
g       = uigridlayout(fig,...
    'RowHeight',{'4x','1x'},...
    'ColumnWidth',{'1x'});

% Axes
ax      = uiaxes(g,'Position',[10 100 dims(1) dims(2)]);
gl      = uigridlayout(g,[1 2],'ColumnWidth',{'1x','3x'});
imagesc(ax,image)
axis(ax,'tight')

%% Buttons
gl_buts     = uigridlayout(gl,[4 1],...
    'RowHeight',{'1x','1x'});
save_but    = uibutton(gl_buts,...
    'Text','Save',...
    'ButtonPushedFcn',@save_push);
view_list = uidropdown(gl_buts,'Items',...
    {'Original','Filter','Detection','Combined'},'Value','Combined',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
method_list = uidropdown(gl_buts,'Items',...
    {'Sobel','Prewitt','Roberts','log','Canny'},'Value','Canny',...
    'ValueChangedFcn',@(sld,event) list_change(event,ax));
uibutton(gl_buts,...
    'Text','Refresh',...
    'ButtonPushedFcn',@state_push);
%% Initializing
thres = 1e-3;
sigma = 1e-3;

%% Tabs
tabg            = uitabgroup(gl);
tab_fiters      = uitab(tabg,'Title','Filters');
tab_detection   = uitab(tabg,'Title','Detection');
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
    'ValueChangingFcn',...
    @(sld,event) sld_move(event,ax));

gauss_x_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',10,...
    'ValueChangingFcn',...
    @(sld,event) sld_move(event,ax));
gauss_y_sld = uislider(gl_filter_vars,...
    'Limits',[0 20],...
    'Value',2,...
    'ValueChangingFcn',...
    @(sld,event) sld_move(event,ax));

%% Detection Tab
% Sliders
gl_detect_vars     = uigridlayout(tab_detection,[2 2],...
    'ColumnWidth',{'1x','4x'});
uilabel(gl_detect_vars,'Text','Threshold');
thres_sld = uislider(gl_detect_vars,...
    'Limits',[0 1],...
    'Value',thres,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

sigma_label = uilabel(gl_detect_vars,'Text','Sigma');
sigma_sld = uislider(gl_detect_vars,...
    'Limits',[0 30],...
    'Value',sigma,...
    'ValueChangedFcn',...
    @(sld,event) sld_move(event,ax));

updateAxes(ax)
%% Wait statements
if waitstate;waitfor(fig);end
clc
%% Callbacks
    function updateAxes(ax)
        %% Error-passers
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
                %% 
                imagesc(ax,image)
            case 'Filter'
                %% Zero values 
                out = checkZeros;
                imagesc(ax,out)
                caxis(ax,[0 100])
            case 'Detection'
                %%
                switch method_list.Value
                    case {'Sobel','Prewitt','Roberts'}
                        thres_sld.Limits = [0 10];
                        imagesc(ax,edge(image,method_list.Value,thres_sld.Value))
                    case {'Canny','log'}
                        thres_sld.Limits = [0 1];
                        imagesc(ax,edge(image,method_list.Value,thres_sld.Value,sigma_sld.Value))
                end
            case 'Combined'
                %% Zero values 
                out = checkZeros;
                switch method_list.Value
                    case {'Sobel','Prewitt','Roberts'}
                        sigma_sld.Enable = 'off';
                        thres_sld.Limits = [0 10];
                        imagesc(ax,edge(out,method_list.Value,thres_sld.Value))
                    case {'Canny','log'}
                        sigma_sld.Enable = 'on';
                        thres_sld.Limits = [0 1];
                        imagesc(ax,edge(out,method_list.Value,thres_sld.Value,sigma_sld.Value))
                end
        end
        
    end
    function save_push(PushButton,event)
        %% Output
        out = checkZeros;
        switch method_list.Value
            case {'Sobel','Prewitt','Roberts'}
                out = edge(out,method_list.Value,thres_sld.Value);
            case {'Canny','log'}
                out = edge(out,method_list.Value,thres_sld.Value,sigma_sld.Value);
        end
        
        args = struct(...
        'thres',thres_sld.Value,...
        'sigma',sigma_sld.Value,...
        'flatfield',flatfield_sld.Value,...
        'gaussfilt',[gauss_x_sld.Value gauss_y_sld.Value],...
        'method',method_list.Value,...
        'out',out);
    
        assignin('base','args',args);
        %% Print statements and closing
        fprintf('Saved values:\n\tThres = %.2f \n\tSigma = %.2f \n\tFlatfield = %i\n\tGuassFilt = [%i %i]\n',...
            thres_sld.Value,...
            sigma_sld.Value,...
            round(flatfield_sld.Value),...
            round(gauss_x_sld.Value),round(gauss_y_sld.Value))
        
        if waitstate
            state = 1;
            closereq();
        end
    end
    function state_push(PushButton,event)
        updateAxes(ax)
    end
    function sld_move(event,ax)
        updateAxes(ax)
    end
    function list_change(event,ax)
        updateAxes(ax)
    end
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
    function out = checkZeros
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
end