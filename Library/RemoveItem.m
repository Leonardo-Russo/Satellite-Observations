function list = RemoveItem(list, index)
% Description: this function removes the i-th element from a row array.

n = length(list);

if index == 1
    list = list(2:end);
elseif index >= 2 && index < n
    list = [list(1:index-1); list(index+1:end)];
elseif index == n
    list = list(1:n-1);
end


end