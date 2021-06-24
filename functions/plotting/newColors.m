function newColors(ax,cmoceanmap,limits,label)
    h = get(ax,'Children');
    c = flipud(imresize(cmocean(cmoceanmap),[length(h) 3],'nearest'));
    for i=1:length(h)
        h(i).Color =  c(i,:);
    end
    caxis(limits)
    set(gca,'Colormap',cmocean(cmoceanmap,diff(caxis)))
    cbar = colorbar;
    cbar.Label.String = label;
    cbar.Label.Interpreter = 'latex';
end