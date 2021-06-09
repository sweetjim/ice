function addlabels(ax,title_str,x_str,y_str)

if ~exist('x_str','var')&&~exist('y_str','var')
        x_str = '$x$ (cm)';
        y_str = '$z$ (cm)';
end
xlabel(ax,x_str,'Interpreter','latex');
ylabel(ax,y_str,'Interpreter','latex');
title(ax,title_str,'Interpreter','latex')
set(gca,'TickLabelInterpreter','latex')
end