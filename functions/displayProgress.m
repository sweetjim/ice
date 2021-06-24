function displayProgress(string,val,start_val,end_val,varargin)
if val==start_val;fprintf('\r%s:\t',string);end

frac = round(val/end_val*100);
if frac == 0; frac=1;end
if val>start_val
    for j=0:log10(frac*1e3)
        fprintf('\b'); 
    end
end

lines = fprintf(' %i %%', frac);
pause(.001); 

if val==end_val
    if nargin>4
        if strcmp(varargin{1},'delete')
            fprintf(repmat('\b',1, lines+length(string)+1))
        else
            fprintf('\n');
        end
    else
        fprintf('\n');
    end
end
end

