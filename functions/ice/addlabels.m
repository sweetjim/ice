function addlabels(varargin)

[ax,title_str,x_str,y_str,z_str,latex,fs] = parseInput(varargin);

if latex
    xlabel(ax,x_str,'Interpreter','latex')
    ylabel(ax,y_str,'Interpreter','latex')
    zlabel(ax,z_str,'Interpreter','latex')
    title(ax,title_str,'Interpreter','latex')
    set(ax,'TickLabelInterpreter','latex')
else
    xlabel(ax,x_str)
    ylabel(ax,y_str)
    zlabel(ax,z_str)
    title(ax,title_str)
end
set(ax,'FontSize',fs)

%% Input parser
    function [ax,title_str,x_str,y_str,z_str,latex,fs] = parseInput(varargin)
        ax          = gca;
        x_str       = '';
        y_str       = '';
        z_str       = '';
        title_str   = '';
        
        fs          = 10;
        latex       = false;
        
        m = 1;
        items = varargin{:};
        for k=1:length(items)
            switch items{m}
                %% Name arguments
                case 'latex'
                    latex   = true;
                %% Name-value arguments
                case 'ax'
                    ax      = namevalue;
                case 'title'
                    title_str   = namevalue;
                case {'x','x_str'}
                    x_str   = namevalue;
                case {'y','y_str'}
                    y_str   = namevalue;
                case {'z','z_str'}
                    z_str   = namevalue;
                case 'fs'
                    fs      = namevalue;
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