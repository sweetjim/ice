function out = within(x,xrange)
x1 = xrange(1);
x2 = xrange(2);
out = (x>x1&x<x2);
if diff(xrange)<0
out = (x<x1&x>x2);
end
end

