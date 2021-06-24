function addColorbar(varargin)
%% Add Colorbar
% Adds a colorbar to the specified axes (or current axes) with a title
% formatted in LaTeX or in plain script.
%
% -------------------------------------------------------------------------
% %  Parameters:
% -------------------------------------------------------------------------
%   ax:     [axes] (Optional)
%   Axes to add colorbar to (default is gca).
% 
%   label:  [char] (Optional)
%   Colorbar label (default is '').
% 
%   latex:  [bool] (Optional)
%   Latex formatting (default is false).
% 
%   fs:     [int] (Optional)
%   Fontsize (default is 10).
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
%%
[ax,label,latex,fs] = parseInput(varargin);

c = colorbar(ax);
c.Label.String          = label;

if latex
    c.Label.Interpreter     = 'latex';
    c.TickLabelInterpreter  = 'latex';
end

c.FontSize = fs;
%% Input parser
    function [ax,label,latex,fs] = parseInput(varargin)
        ax          = gca;
        label       = '';
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
                case {'label','title'}
                    label   = namevalue;
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

