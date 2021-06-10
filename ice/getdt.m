function dt=getdt(files,i,item)
dt = split(between(datetime(files(1).date),datetime(files(i).date)),'time');
switch item
    case 'hour'
        dt = hours(dt);
    case 'min'
        dt = minutes(dt);
    case 'sec'
        dt = seconds(dt);
end
end