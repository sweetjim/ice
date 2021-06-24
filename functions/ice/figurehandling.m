function figurehandling(varargin)
%% Parameters
% 'new'
% 'split'
% 'grid'

p = get(0,'MonitorPositions');
monitors = mod(numel(p)/4,4);

if nargin==1
    %%
    k       = monitors;
    h       = findall(groot,'Type','figure');
    figno   = numel(h);
    set(h(1),'Position',p(k,:),'WindowState','maximized')
    windowsize = get(h(1),'Position')-p(k,:);
    switch varargin
        case 'new'
            xspan = floor(p(1,3)/figno);
            for i=1:figno
                set(h(i),'WindowState','normal')
                set(h(i),'Position',[p(k,1)+xspan*(i-1) p(k,2) xspan p(k,4)]+windowsize)
                shg
            end
        case 'split'
            
        case 'grid'
            
    end
else
    %% 
    if monitors==2 % Two moniters
        set(gcf,'Position',p(2,:),'WindowStyle','normal','WindowState','maximized')
        shg
    else % One monitor
        set(gcf,'WindowStyle','docked')
    end

end
end

