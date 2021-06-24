function ds = getds(image)
figure(1)
set(gcf,'WindowStyle','docked')
imagesc(image)
imdistline;
ds = input('Enter the distance:\n');
end
