function getMeltPrediction(analysis,varargin)
%% Get Melt Prediction                                  
% Uses the results from 'getEdgeAnalysis' and predicts the time required to
% fully melt the ice according to a linear regression of dhdt(z).
%
% -------------------------------------------------------------------------
% %  Parameters:
% -------------------------------------------------------------------------
%  analysis: [struct] (Required)
%   The output from program 'getEdgeAnalysis'.
%
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

%%  Initialization and parsers                          

persistent fig
fig_title = 'Melt Analysis';
openFig(fig_title)


[smooth_x,smooth_y,dt_str,rerun] = parseInput(varargin);

if rerun;fig = getfig;end

dt      = analysis.dt;
z       = analysis.z;
t       = analysis.t(2:end);                        % Assume that first image includes barrier
h       = smooth2a(analysis.h(:,2:end),smooth_x,smooth_y);

if rerun
    if isempty(fig)
        fig = getfig;
    elseif ~isvalid(fig)
        fig = getfig;else
        clf(fig)
    end
else
    if isempty(fig)
        fig = getfig;
    elseif ~isvalid(fig)
        fig = getfig;
    else
        clf(fig)
    end
end


%% Time-to-zero-h                                       
t2zero      = zeros(size(h,1),1);
for i=1:size(h,1)
    [~,idx] = find(h(i,:)<=0,1,'first');
    if isempty(idx)
       idx = NaN; 
    end
    t2zero(i) = idx;
end
%% Ablation Velocity (regularized to zero-height time)  

dhdt    = zeros(size(h,1),1);
h_pred  = zeros(size(h));
R2      = dhdt;
rmse    = dhdt;

for i=1:size(h,1)

    window = 1:t2zero(i);
    if isnan(window)
       window = 1:length(t);
    end
    p                   = polyfitn(t(window),h(i,window),1);
    h_fit               = polyval(p.Coefficients,t(window));
    rmse(i)             = p.RMSE;
    R2(i)               = p.R2;
    h_pred(i,window)    = h_fit;
    dhdt(i)             = p.Coefficients(1);
end
%% Prediction                                           
clf
fac         = 1;
while 1
    t_pred      = linspace(0,t(end)*fac,length(t)*fac);
    h_pred      = dhdt.*t_pred + h(:,2);
    t2zero_pred = t2zero;
    
    for i=1:size(h,1)
        [~,idx_pred] = find(h_pred(i,:)<=0,1,'first');
        if isempty(idx_pred)
            idx_pred = NaN;
        end
        t2zero_pred(i) = idx_pred;
    end
    if sum(isnan(t2zero_pred)==1)>0
       fac = fac + 5; 
    else
        break
    end
    
end

names       = {'sec','min','hour','day'};
sec2val     = [1 60 60^2 60^2*24];
converttime = repmat(sec2val,[4 1])./[1 60 60^2 60^2*24]';
timelookup  = array2table(converttime,'VariableNames',names,'RowNames',names);
tfac        = table2array(timelookup(dt_str,analysis.dt_str));

data_marks = z([find(isnan(t2zero),1,'first') find(isnan(t2zero),1,'last')]);
%% Plotting         

t = tiledlayout(fig,2,1);
ax(1) = nexttile(t,1);
plot(ax(1),z,t2zero*dt*tfac,'k',...
    z,t2zero_pred*dt*tfac,'--r')

xlabel(ax(1),'$z$ (m)','Interpreter','latex')
ylabel(ax(1),sprintf('%s (%s)','$t$',dt_str),'Interpreter','latex')
title(ax(1),...
    sprintf('Time to melt %.3f m of ice',mean(h(:,2))),...
    'Interpreter','latex')

set(ax(1),'YScale','log','YGrid','on')
line(ax(1),data_marks(1).*[1 1],ylim,'linestyle',':','color','k')
line(ax(1),data_marks(2).*[1 1],ylim,'linestyle',':','color','k')
line(ax(1),xlim,t2zero(find(isnan(t2zero),1,'first')-1).*[1 1]*dt*tfac,'linestyle',':','color','k')
legend(ax(1),...
    {'Data','Linear fit'},...
    'Interpreter','latex')
xlim(ax(1),[0 max(z)])
set(ax(1),'TickLabelInterpreter','latex')

% ------------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------------

ax(2) = nexttile(t,2);
yyaxis(ax(2),'left')
plot(ax(2),z,dhdt/tfac*dt)
xlabel(ax(2),'$z$ (m)','Interpreter','latex')
ylabel(ax(2),sprintf('%s (m/%s)','$U$',dt_str),'Interpreter','latex')
title(ax(2),'Linear ablation velocity (regularized)','Interpreter','latex')

line(ax(2),data_marks(1).*[1 1],ylim,'linestyle',':','color','k')
line(ax(2),data_marks(2).*[1 1],ylim,'linestyle',':','color','k')
set(ax(2),'Ygrid','on')
ylim(ax(2),[-Inf 0])

yyaxis(ax(2),'right')
plot(ax(2),z,R2)
ylabel(ax(2),'Non-linearity ($R_2$)','Interpreter','latex')
ylim(ax(2),[min(R2) 1])
xlim(ax(2),[0 max(z)])

set(ax(2),'TickLabelInterpreter','latex')
%% Outputs                                              
melt = struct(...
    'zerotime',t2zero,...
    'zerotime_pred',t2zero_pred,...
    'dt',dt*tfac,...
    'timeconvert',sprintf('%s to %s',analysis.dt_str,dt_str),...
    'root',analysis.root,...
    'savepath',analysis.savepath);
assignin('base','melt',melt);

save(melt.savepath,'melt','-append')
%% Functions                                            
    function [smooth_x,smooth_y,dt_str,rerun] = parseInput(varargin)
        dt_str      = 'day';
        smooth_x    = 0;
        smooth_y    = 0;
        rerun       = false;
        
        m = 1;
        items = varargin{:};
        for k=1:length(items)
            switch items{m}
                case 'rerun'
                    rerun = true;
                %% Name arguments
                case {'sec','min','hour','day'}
                    dt_str  = items{m};
                    %% Name-value arguments
                case 'smooth'
                    smooth = namevalue;
                    if numel(smooth)>1
                        smooth_x = smooth;
                        smooth_y = smooth;
                    else
                        smooth_x = smooth(1);
                        smooth_y = smooth(2);
                    end
            end
            m = m+1;
            if m>length(items);break;end
        end
        function out = namevalue
            out = items{m+1};
            m   = m+1;
        end
    end
    function fig = getfig
        fig = figure('Name',fig_title,'WindowStyle','docked','NumberTitle','off');
    end
end

