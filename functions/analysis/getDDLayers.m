function getDDLayers(analysis,varargin)
%% Get Double Diffusive Layers 
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

[mode,min_z,prominance_w,smooth_x,smooth_y,method,resize,rerun] = parseInput(varargin);

persistent fig
fig_title = 'Double-Diffusive Layers Analysis';
openFig(fig_title)
if rerun;fig = getfig;end
clf

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
%%
t_offset = 10;
dt      = analysis.dt;
z       = analysis.z;
ds      = max(z)/length(z);

z_range = (z>0);
min_th  = find(z>min_z,1,'first');

z       = z(z_range);
t       = analysis.t(t_offset:end);                        % Assume that first image includes barrier
h       = smooth2a(analysis.h(z_range,t_offset:end),smooth_x,smooth_y);


if sum(resize)>0
    if numel(resize)==1
        h = imresize(h,[size(h,1) size(h,2)*resize]);
        t = imresize(t,[1 length(t)*resize]);
    else
        h = imresize(h,size(h).*resize);
        z = imresize(z,[1 length(z)*resize(1)]);
        t = imresize(t,[1 length(t)*resize(2)]);
    end
end

H       = h; 
H(H==0) = NaN;


%% Peak acquisition                                     
LMax        = zeros(size(h));
LMin        = zeros(size(h));

switch method
    case 'gradient'
        %% Gradient and labelling
        [~,hz]  = gradient(H,t,z);
        [~,hzz] = gradient(hz,t,z);
         
        switch mode
            case 'max'
                H_pa    = -hzz;
                clabel = '$H$, distance from scollups (m)';
            case 'min'
                H_pa    = hzz;
                clabel  = '$H$, distance to scollups (m)';
        end
        
        new_lim = 5*nanstd(H_pa,[],'all');
        H_pa(H_pa>new_lim)  = NaN;
        H_pa(H_pa<-new_lim) = NaN;
        
        H_pa    = smooth2a(H_pa,0,5);
        IN      = H_pa>0;%1/4*nanstd(H_pa,[],'all');
        IN      = ~bwareaopen(~IN,300);
        IN      = bwareaopen(IN,500);
        LBL     = bwlabeln(IN')';
%         figure(1)
%         waterfall(z,t,H',LBL');
%         view(180,50)
        
        %% Peak/trough acquisition
        newIN   = LBL;
        thres   = 0.5;

        for i=1:max(newIN,[],'all')

            VAR = (newIN==i);
            LT  = getLayerThickness(VAR,'window',1,'normalize','invert');
            if i==1;OUT = zeros(size(LT));end
            OUT = OUT + LT;
            
            waterfall(z,t,H_pa',OUT');view(180,50)
        end
        OUT     = smooth2a(OUT,0,1);
        holes   = OUT>thres;
        OUT     = OUT.*(bwareaopen(holes,500));
        
%         figure(2)
%         waterfall(z,t,h',OUT')
%         
%         view(180,30);
%         colormap(gca,parula(5))
%         colorbar
        %% Layer thickness
        clf
        dist_map = zeros(size(h'));
        for i=1:length(t)
            dist_map(i,:) = bwdist(OUT(:,i)>thres);
        end        
        
        OUTPUT = dist_map*ds.*~isnan(H');
        
        thickness_t = zeros(length(t),1);
        for i=1:length(t)
            %%
            thick_max = islocalmax(OUTPUT(i,:)*ds);
            thickness_t(i) = mean(diff(z(thick_max)));             
%             plot(z,OUTPUT(i,:),z(thick_max),OUTPUT(i,thick_max),'o')
%             addlabels('title',sprintf('Hmean = %.2f',thickness_t(i)),'latex')
%             pause(.1)
        end
        
        delta_H     = thickness_t;
        grad_dH     = gradient(delta_H,t);
        spikes      = (grad_dH>std(grad_dH));
        
        %% Plots
        clf
        tiledlayout(1,10)
        nexttile([1 7])
        waterfall(z,t,h',OUTPUT);
        hold on
        w = waterfall(z,t(spikes),h(:,spikes)',h(:,spikes)'>0);
        w.EdgeColor = 'w';
        w.EdgeAlpha = 0.5;
        hold off
        view(170,50);
        
        logfac = ceil(-log10(max(delta_H))+1);
        caxis([0 ceil(max(delta_H)*10^logfac)*10^-logfac])
%         set(gca,'ColorScale','log')        
        addColorbar('latex','label',clabel,'fs',15)
        addlabels(gca,'title','Layer thickness',...
            'x','$z$ (m)',...
            'y',sprintf('%s (%s)','$t$',analysis.dt_str),...
            'z','$h$ (m)',...
            'latex','fs',15)
        axis xy tight
        
        nexttile(9,[1 2])
        plot(t,delta_H,t(spikes),delta_H(spikes),'o')
        addlabels(gca,'title','Layer thickness (spatial-average)',...
            'y','$\langle H\rangle$ (m)',...
            'x',sprintf('%s (%s)','$t$',analysis.dt_str),...
            'latex','fs',15)
        child = get(gca,'Children');
        legend(child(1),{'$\Delta H>\sigma_{\Delta H}$'},'Location','northwest','Interpreter','latex')
        axis xy tight
        
        ddlayer = struct(...
            'resize',resize,...
            't',t,...
            'z',z,...
            'h',h,...
            'ice',OUTPUT'*ds,...
            'layers',delta_H,...
            'spikes',spikes,...
            'root',analysis.root,...
            'savepath',analysis.savepath);
        assignin('base','ddlayer',ddlayer)
        return
    case 'peak'
        %%
        H_pa    = H;
        
        for i=1:size(h,2)
            HT          = H_pa(:,i);
            localmax    = islocalmax(HT,'MinSeparation',min_th,'ProminenceWindow',prominance_w);
            localmin    = islocalmin(HT,'MinSeparation',min_th,'ProminenceWindow',prominance_w);
            LMax(:,i)   = localmax;
            LMin(:,i)   = localmin;
        end
        
        switch mode
            case 'max'
                IN      = LMax;
                INcomp  = LMin;
                clabel = 'Distance from scollups (cm)';
            case 'min'
                IN      = LMin;
                INcomp  = LMax;
                clabel  = 'Distance to scollups (cm)';
        end
end


%% Binary labelling / connectivity                     

clf
out      = IN;

% Distance map
dist_map = zeros(size(h'));
for i=1:length(t)
    %             dist_map(i,:) = bwdist(out(i,:)>0);
    dist_map(i,:) = bwdist(out(:,i)>0);
end


waterfall(z,t,h',dist_map*ds)

% imagesc(z,t,bwdist(OUTmax>0,'quasi-euclidean')*ds)
shading flat


set(gca,'ColorScale','log')
addColorbar('latex','label',clabel,'fs',15)
addlabels(gca,'title','Layer Thickness',...
    'y','$z$ (cm)',...
    'x',sprintf('%s (%s)','$t$',analysis.dt_str),...
    'latex','fs',15)
axis xy tight

nexttile
%%
clf
tiledlayout(1,2)
H_IN = imdilate(IN,strel('rectangle',[5 10]));
HH = H_zz;
HH(H_IN==1)=2*max(HH,[],'all');
HH = getLayerThickness(~(HH>0))'*ds;
% nexttile
waterfall(z,t,h',(~HH.*H_zz'))
% view(170,50)

% nexttile
% waterfall(z,t,h',H_IN')%,dist_map*ds)
shading flat
view(180,80)
addlabels(gca,'title','Map',...
    'y','$z$ (cm)',...
    'x',sprintf('%s (%s)','$t$',analysis.dt_str),...
    'latex','fs',15)
addColorbar('latex','label',clabel,'fs',15)
axis xy tight
% set(gca,'ColorScale','log')

%[dist_map,~] = getDistMap(IN);

%% Plotting
clf

    % subplot(2,1,1)
    % waterfall(z,t,H',OUTmax>0);
    
    % addlabels(gca,'Scollup locations','$z$ (cm)',sprintf('%s (%s)','$t$',analysis.dt_str),'Scollup (boolean)')
    % addColorbar('latex','label','$h$ (cm)','fs',15)
    % zlim([0 2])
    % view(140,45)
    
    
    % subplot(2,1,2)
    % imagesc(z,t,(dist_map*ds))
    % clf
    waterfall(z,t,h',dist_map*ds)
    % imagesc(z,t,bwdist(OUTmax>0,'quasi-euclidean')*ds)
    shading flat
    
    % hold on
    % w = waterfall(z,t,h');
    % w.EdgeColor = 'c';
    % contour3(z,t,h','c','LevelStep',0.005)
    % hold off
    % view(0,30)
    % zlim([ds Inf])
    set(gca,'ColorScale','log')
%%
    [dm_Lmax,~] = getDistMap(LMax);
    [dm_Lmin,~] = getDistMap(LMin);

    dm_Lmax(dm_Lmax~=0) = 1;
    dm_Lmin(dm_Lmin~=0) = 1;

    dm_Lmax = imcomplement(dm_Lmax);
    dm_Lmin = -imcomplement(dm_Lmin);
    waterfall(z,t,h',dm_Lmax+dm_Lmin)
%     waterfall(z,t,h',abs((dist_map-dist_map_comp)*ds))
%     cmocean('balance','pivot',0)
    clabel  = '';



view(170,50)
addColorbar('latex','label',clabel,'fs',15)
addlabels(gca,'title','Layer Thickness',...
    'y','$z$ (cm)',...
    'x',sprintf('%s (%s)','$t$',analysis.dt_str),...
    'latex','fs',15)
axis xy

colormap(jet(256))


%% Plotting                                             


% if tiles
%     figure(10);dockfig;
%     tiledlayout(2,1)
% elseif figures
%     figure(10);dockfig;
% end
% 
% if tiles;nexttile(1);end
% plot(z,t2zero*dt*tfac,'k',...
%     z,t2zero_pred*dt*tfac,'--r')
% 
% xlabel('$z$ (cm)','Interpreter','latex')
% ylabel(sprintf('%s (%s)','$t$',dt_str),'Interpreter','latex')
% title(...
%     sprintf('Time to melt %.2f cm of ice',mean(h(:,2))*1e2),...
%     'Interpreter','latex')
% 
% set(gca,'YScale','log','YGrid','on')
% line(data_marks(1).*[1 1],ylim,'linestyle',':','color','k')
% line(data_marks(2).*[1 1],ylim,'linestyle',':','color','k')
% line(xlim,t2zero(find(isnan(t2zero),1,'first')-1).*[1 1]*dt*tfac,'linestyle',':','color','k')
% legend(...
%     {'Data','Linear fit'},...
%     'Interpreter','latex')
% xlim([0 max(z)])
% set(gca,'TickLabelInterpreter','latex')
% 
% if tiles;nexttile(2);else;figure(11);end
% 
% yyaxis left
% plot(z,dhdt/tfac*dt)
% xlabel('$z$ (cm)','Interpreter','latex')
% ylabel(sprintf('%s (cm/%s)','$U$',dt_str),'Interpreter','latex')
% title('Linear ablation velocity (regularized)','Interpreter','latex')
% 
% line(data_marks(1).*[1 1],ylim,'linestyle',':','color','k')
% line(data_marks(2).*[1 1],ylim,'linestyle',':','color','k')
% set(gca,'Ygrid','on')
% ylim([-Inf 0])
% 
% yyaxis right
% plot(z,R2)
% ylabel('Non-linearity ($R_2$)','Interpreter','latex')
% ylim([min(R2) 1])
% xlim([0 max(z)])
% 
% set(gca,'TickLabelInterpreter','latex')
%% Outputs                                              
% [C,~] = gradient(H*ds,tplot,z);
% layers = struct(...
%     'z',z,...
%     't',T,...
%     'h',H*ds,...
%     'dt',dt,...
%     'dt_str',dt_str,...
%     'dhdt',C,...
%     'root',analysis.root,...
%     'savepath',analysis.savepath);
% assignin('base','layers',layers);
% save(layers.savepath,'layers','-append')
%% Functions  
    function [dist_map,out] = getDistMap(IN)
        
%         dilate      = strel('rectangle',[1 10]);%ones(9);
%         erode       = strel('rectangle',[1 1]);
%         in          = imdilate(IN,dilate);
%         in          = longestCurve(in,'all');
        
        % INmax       = bwareaopen(INmax,80);
        % INmax       = smooth2a(INmax,2,5);
        % INmax       = INmax>0*H;
        % INmax       = imerode(INmax,erode);
        
%         in          = bwareaopen(in,1);
%         in          = bwlabel((in)',8);
%         in(isnan(H'))=NaN;
        
        out      = IN;
        
        %% Distance map
        dist_map = zeros(size(h'));
        for k=1:length(t)
%             dist_map(i,:) = bwdist(out(i,:)>0);
              dist_map(k,:) = bwdist(out(:,k)>0);
        end
        % dist_map(dist_map==0)   = NaN;
        % dist_map(isnan(H)')     = Inf;
    end

%% Input parser
    function [mode,min_z,prominance_w,smooth_x,smooth_y,method,resize,rerun] = parseInput(varargin)
        
        mode            = 'max';
        prominance_w    = 1;
        smooth_x        = 0;
        smooth_y        = 0;
        min_z           = 5e-2;
        method          = 'gradient';
        resize          = 0;
        rerun           = false;
        
        
        %%
        m = 1;
        items = varargin{:};
        for k=1:length(items)
            switch items{m}
                %% Name arguments
                case 'rerun'
                    rerun = true;
                case 'max'
                    mode  = items{m};
                case 'min'
                    mode  = items{m};
                case 'compare'
                    compare = true;        
                case {'gradient','dhdz'}
                    method  = 'gradient';
                    %% Name-value arguments
                case 'smooth'
                    smooth = namevalue;
                    if numel(smooth)<1
                        smooth_x = smooth;
                        smooth_y = smooth;
                    else
                        smooth_x = smooth(1);
                        smooth_y = smooth(2);
                    end
                case {'zmin','minz','min_z'}
                    min_z           = namevalue;
                case {'prominance','prom','p'}
                    prominance_w    = namevalue;
                case {'resize'}
                    resize          = namevalue;
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