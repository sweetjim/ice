function getEdgeAnalysis(args,varargin)
%% Get Edge Analysis
% Uses the results from the GUI program 'tuner' and applies it to every
% image listed in the active repository (i.e. 'args.files') using the
% script 'applytuner'. At each time step ('step') the ice-edge, a
% vectorized quantity 'h', is added to the time series vector 'H'. Once
% complete, a surface type plot is generated displaying the results.
%
% -------------------------------------------------------------------------
% %  Parameters:
% -------------------------------------------------------------------------
%  args: [struct] (Required)
%   The output from GUI program 'tuner' (hitting 'save' generates this
%   variable).
%
% -------------------------------------------------------------------------
% %  Singular arguments (Optional)
% -------------------------------------------------------------------------
%
%  rerun: [char]
%   Activation variable for re-running the script. For use when new 'args'
%   variable is called.
%
%  surf, waterfall, contour: [char]
%   Plotting types; default is 'surf'.
%
%  height, gradient: [char]
%   C-axis data plotting types; default is 'height'.
%
%  sec, min, hour: [char]
%   Delta-t to extract from file timestamps (for time vector); default is
%   'min'.
%
% -------------------------------------------------------------------------
% % Name-value arguments (Optional)
% -------------------------------------------------------------------------
%  loop: [int, vector]
%   Elements to loop through and construct H from. For use when trialling
%   potentially unstable edge detection setups.
%
%  step: [int]
%   Time step to loop through and construct H from. Same as above.
%
%  ds: [double]
%   Delta-x or Delta-z in terms of cm/pixel.
%
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
%%  Initialization and parsers
step  = 1;
loop  = 1:step:length(args.files);
Zspan   = 1.1;
Zlength = size(args.out,1);
ds      = Zspan/Zlength;

[colormode,mode,rerun,dt_str] = parseInput(varargin);

z       = linspace(0,Zlength*ds,Zlength);
%% Loop (Edge detection time series)

persistent H T fig
% keep h(z,t) for quick plotting ('rerun' overwrites variables)

if rerun||(isempty(H)&&isempty(T))
    fig     = figure('Name','Edge Analysis','WindowStyle','docked');
    dt     = getdt(args.files,step*2,dt_str);
    
    T       = 0:dt:dt*(loop(end)-1);
    tplot   = T;
    H       = zeros(size(args.out,1),length(loop));
    j       = 1;
    for i=loop
        [~,h,~]     = applytuner(args,'all',i);
        H(:,j)      = h;
        j           = j+1;
        displayProgress('Progress',i,loop(1),loop(end))
    end
end
%% Plotting

if rerun
    if ~isvalid(fig)
        fig = figure('Name','Edge Analysis','WindowStyle','docked');
    else
        clf(fig)
    end
else
    switch dt_str
        case 'sec'
            tplot = T*60;
        case 'min'
            tplot = T;
        case 'hour'
            tplot = T/60;
    end
    if ~isvalid(fig)
        fig = figure('Name','Edge Analysis','WindowStyle','docked');
    else
        clf(fig)
    end
end


ax  = axes(fig);

switch colormode
    case 'height'
        C = H*ds;
        clabel = '$h$ (cm)';
    case 'gradient'
        [C,~] = gradient(H*ds);
        clabel = sprintf('%s (cm/%s)','$\partial_t h$',dt_str);
end

switch mode
    case 'waterfall'
        waterfall(ax,z,tplot,H'*ds,C')
        view(110,60)
    case 'surf'
        surf(ax,z,tplot,H'*ds,C')
        shading interp
        view(110,60)
    case 'contour'
        %%
        surf(ax,z,tplot,H'*ds,C')
        hold(ax,'on')
        caxis(max(caxis).*[-1 1])
        cmocean('balance','pivot',0,2^5)
        contour3(ax,z,tplot,H'*ds,'k')
        hold(ax,'off')
        shading interp
        %         view(90,90)
        view(110,60)
end
c                       = colorbar;
c.Label.String          = clabel;
c.Label.Interpreter     = 'latex';
c.TickLabelInterpreter  = 'latex';
c.FontSize              = 15;

ylabel(sprintf('%s (%s)','$t$',dt_str),'Interpreter','latex')
xlabel('$z$ (cm)','Interpreter','latex')
zlabel('$h$ (cm)','Interpreter','latex')
set(gca,'TickLabelInterpreter','latex','FontSize',15)

axis(gca,'tight')
%% Outputs
analysis = struct(...
    'z',z,...
    't',T,...
    'h',H*ds);
assignin('base','analysis',analysis);

%% Functions
    function [colormode,mode,rerun,dt_str] = parseInput(varargin)
        
        colormode   = 'height';
        mode        = 'surf';
        rerun       = false;
        dt_str      = 'min';
        
        m = 1;
        items = varargin{:};
        for k=1:length(items)
            switch items{m}
                %% Name arguments
                case {'default','gradient'}
                    colormode = items{m};
                case {'waterfall','surf','contour'}
                    mode    = items{m};
                case 'rerun'
                    rerun   = true;
                case {'sec','min','hour'}
                    dt_str  = items{m};
                    %% Name-value arguments
                case 'loop'
                    loop    = namevalue;
                case 'step'
                    step    = namevalue;
                case 'ds'
                    ds      = namevalue;
            end
            m = m+1;
            if m>length(items);break;end
        end
        function out = namevalue
            out = items{m+1};
            m   = m+1;
        end
    end

end

