function s = wobj2struct(filename,triangulateFlag)

% s.o = string array
% s.g = string array
% s.m = struct array
% s.m(i).name = string
% s.m(i).(property) = value(s)
% s.v = single array [nbVertex X (3-7)]
% s.vt = single array [nbVertexTex X (2-3)]
% s.vn = single array [nbVertexNorm X 3]
% s.f = struct array
% s.f(i).o = scalar uint32
% s.f(i).g = scalar uint32
% s.f(i).m = scalar uint32
% s.f(i).s = logical
% s.f(i).v = uint32 array [nbFaces X nPtsPerFace]
% s.f(i).vt = uint32 array [nbFaces X nPtsPerFace]
% s.f(i).vn = uint32 array [nbFaces X nPtsPerFace]
% s.f(i).n = uint32 scalar nbFaces
% s.l = struct array
% s.l(i).o = scalar uint32
% s.l(i).g = scalar uint32
% s.l(i).v = uint32 array [1 X nPts]

if nargin < 2, triangulateFlag = false; end

[type,str] = readTypeTextLines(filename);

s = struct;

o_x = find(type == "o");
g_x = find(type == "g");
m_x = find(type == "usemtl");
s_x = find(type == "s");

s.g = str(g_x);
s.o = str(o_x);


d = fileparts(filename);
m_str = str(type == "mtllib");
if ~isempty(m_str)
    s.m = wmtl2struct(fullfile(d,m_str));
else
    s.m = struct('name',{string.empty});
end
[~,m_i] = ismember(str(m_x),[s.m.name]');
s_i = str(s_x);

s_x = [1 ; s_x];
s_i = ["on" ; s_i];

s_i = s_i.replace(["on" "off"],["1" "0"]).double;

v_t = type == "v";
vt_t = type == "vt";
vn_t = type == "vn";

s.v = single(lines2mat(str(v_t),7).double);
s.vt = single(lines2mat(str(vt_t),3).double);
s.vn = single(lines2mat(str(vn_t),3).double);

[v_x,v_n] = tfExtents(v_t);
[vt_x,vt_n] = tfExtents(vt_t);
[vn_x,vn_n] = tfExtents(vn_t);
f_x = tfExtents(type == "f");

clear v_t vt_t vn_t

v_s = cumsum(v_n);
vt_s = cumsum(vt_n);
vn_s = cumsum(vn_n);

nf = height(f_x);
c = cell(nf,1);
f_g = c;
f_o = c;
f_m = c;
f_s = c;
f_v = c;
f_vt = c;
f_vn = c;
f_n = c;
for i=1:nf
    f_i = f_x(i,1);
    f_g{i} = findId(g_x,f_i);
    f_o{i} = findId(o_x,f_i);
    f_m{i} = m_i(findId(m_x,f_i));
    f_s{i} = s_i(findId(s_x,f_i));
    
    f = lines2mat(str(f_x(i,1):f_x(i,2)),inf);
    f(f.strlength == 0) = "//";
    k = f.count("/") == 1;
    f(k) = f(k).append("/");
    f = int32(f.split("/",3).double);
    if triangulateFlag && width(f) > 3
        newf = [];
        newf(:,:,1) = trifan(f(:,:,1));
        newf(:,:,2) = trifan(f(:,:,2));
        newf(:,:,3) = trifan(f(:,:,3));
        f = newf;
    end
    o = v_s(findId(v_x(:,2),f_i))+1;
    f_v{i} = applyOffset(f(:,:,1),o);

    if ~isempty(vt_x) && ~all(f(:,:,2)==0,'all')
        o = vt_s(findId(vt_x(:,2),f_i))+1;
        f_vt{i} = applyOffset(f(:,:,2),o);
    end

    if ~isempty(vn_x) && ~all(f(:,:,3)==0,'all')
        o = vn_s(findId(vn_x(:,2),f_i))+1;
        f_vn{i} = applyOffset(f(:,:,3),o);
    end

    f_n{i} = height(f);
end

s.f = struct('o',f_o,'g',f_g,'m',f_m,'s',f_s,'v',f_v,'vt',f_vt,'vn',f_vn,'n',f_n);

l_x = tfExtents(type == "l");
if isempty(l_x), return, end

nl = height(l_x);
c = cell(nl,1);
l_g = c;
l_o = c;
l_v = c;

for i=1:nl
    l_i = l_x(i,1);
    lv = str(l_x(i,1):l_x(i,2));

    lv = num2cell(lv);
    lv = cellfun(@(c) int32(c.split(" ",2).double),lv,'uni',0);
    lv = linearSimplify(lv);

    o = vn_s(findId(vn_x(:,2),l_i))+1;
    lv = cellfun(@(c) applyOffset(c,o),lv,'uni',0);
    nlv = numel(lv);
    l_v{i} = lv;
    l_o{i} = repmat({findId(o_x,l_i)},nlv,1);
    l_g{i} = repmat({findId(g_x,l_i)},nlv,1);

end
vc = @(x) vertcat(x{:});
s.l = struct('g',vc(l_g),'o',vc(l_o),'v',vc(l_v));

end

function [i,n] = tfExtents(tf)
    i = [strfind([0 tf(:)'],[0 1])' strfind([tf(:)' 0],[1 0])'];
    n = diff(i,[],2)+1;
end

function str = lines2mat(str,maxDim2)
    if isempty(str), return, end
    ns = str.count(" ");
    ms = max(ns);
    if ms+1 > maxDim2
        error('size of dim 2 exceeds %i',maxDim2)
    end
    str = str.pad(str.strlength + ms - ns,"right"," ").split(" ",2);
end

function id = findId(x,i)
    id = find(x < i,1,'last');
    if isempty(id), id = []; end
end

function x = applyOffset(x,o)
    tf = x < 0;
    x(tf) = x(tf) + o;
end

function s = wmtl2struct(filename)
    [type,str] = readTypeTextLines(filename);
    s = struct('name',num2cell(str(type == "newmtl")));
    m = 0;
    for i=1:numel(type)
        if type(i) == "newmtl"
            m = m+1;
            continue
        end
        s(m).(type(i)) = str(i);
    end
    s=s(:);
end

function [type,str] = readTypeTextLines(filename)
    str = readlines(filename,"WhitespaceRule","trim","EmptyLineRule","skip");
    icom = str.contains("#");
    str(icom) = strtrim(str(icom).extractBefore("#"));
    str = str.replace(sprintf('\t'),' ');
    str = str(str.strlength > 0);
    type = str.extractBefore(' ');
    str = str.extractAfter(' ').strip;
end

function ind2 = linearSimplify(ind)
    ind2 = ind;
    return
    
    % todo
    % simplify [1 2 ; 2 3 ; 3 4 ; ... ] to [1 2 3 4] (easy)
    % also [1 2 ; 3 4 ; 3 2] to [1 2 3 4] (less easy)
    
    % x = cellfun(@(x) x([1 end]),ind,'Uni',0);
    % x = vertcat(x{:});

end

