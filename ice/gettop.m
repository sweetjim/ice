function X = gettop(x,n,varargin)
%% Gettop
%  This function takes a connected image's output in one dimension and
%  finds its 'leading' edge through a recursive method of checking whether
%  the neighboring indicies are maximas.

if nargin>2
        mode = varargin{1};
else
    mode = 'left';
end

Y = gettoprecursive(x);
for j=1:n-1
    Y = gettoprecursive(Y);
end

X =Y;
function Y=gettoprecursive(x)  
Y = zeros(1,length(x));
for i=1:length(x)-1
    switch mode
        case 'left'
            cond = x(i+1)>x(i);
        case 'right'
            cond = x(i+1)<x(i);
    end
    if cond
        Y(i+1) = x(i+1);
    else
        Y(i+1) = x(i);
    end
end
end
end

