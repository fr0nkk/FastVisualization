function tri = trifan(idx)

sz = size(idx);

w = sz(2);
m = [ones(1,w-2) ; 2:w-1 ; 3:w];
m = reshape(m,1,[]);

tri = reshape(idx(:,m)',3,[])';

end
