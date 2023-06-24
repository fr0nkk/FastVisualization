classdef wobj < handle

    properties(SetAccess = protected)
        object          % string array
        group           % string array
        material        % string array
        vertices        % single array [nbVertex X (3-7)]
        texture_coords  % single array [nbVertexTex X (2-3)]
        normals         % single array [nbVertexNorm X 3]
        faces           % struct array containing indices for each set of faces
        lines           % struct array contining indices for each set of lines
    end
    
    methods
        function obj = wobj(filename)

            % if nargin < 2, triangulateFlag = false; end
            
            [type,str] = iReadTypeTextLines(filename);
            
            % obj = struct;
            
            o_x = find(type == "o");
            g_x = find(type == "g");
            m_x = find(type == "usemtl");
            s_x = find(type == "s");
            
            obj.group = str(g_x);
            obj.object = str(o_x);
            
            
            d = fileparts(filename);
            m_str = str(type == "mtllib");
            if ~isempty(m_str)
                obj.material = iReadMtl(fullfile(d,m_str));
            else
                obj.material = struct('name',{string.empty});
            end
            [~,m_i] = ismember(str(m_x),[obj.material.name]');
            s_i = str(s_x);
            
            s_x = [1 ; s_x];
            s_i = ["on" ; s_i];
            
            s_i = s_i.replace(["on" "off"],["1" "0"]).double;
            
            v_t = type == "v";
            vt_t = type == "vt";
            vn_t = type == "vn";
            
            obj.vertices = single(iLines2Mat(str(v_t),7).double);
            obj.texture_coords = single(iLines2Mat(str(vt_t),3).double);
            obj.normals = single(iLines2Mat(str(vn_t),3).double);
            
            [v_x,v_n] = iExtents(v_t);
            [vt_x,vt_n] = iExtents(vt_t);
            [vn_x,vn_n] = iExtents(vn_t);
            f_x = iExtents(type == "f");
            
            clear v_t vt_t vn_t
            
            v_s = cumsum(v_n);
            vt_s = cumsum(vt_n);
            vn_s = cumsum(vn_n);
            
            nf = height(f_x);
            fc = cell(nf,8);
            for i=1:nf
                f_i = f_x(i,1);
                fc{i,1} = iFindId(o_x,f_i);
                fc{i,2} = iFindId(g_x,f_i);
                fc{i,3} = m_i(iFindId(m_x,f_i));
                fc{i,4} = s_i(iFindId(s_x,f_i));
                
                f = iLines2Mat(str(f_x(i,1):f_x(i,2)),inf);
                f(f.strlength == 0) = "//";
                k = f.count("/") == 1;
                f(k) = f(k).append("/");
                f = int32(f.split("/",3).double);
                o = v_s(iFindId(v_x(:,2),f_i))+1;
                fc{i,5} = iApplyOffset(f(:,:,1),o);
            
                if ~isempty(vt_x) && ~all(f(:,:,2)==0,'all')
                    o = vt_s(iFindId(vt_x(:,2),f_i))+1;
                    fc{i,6} = iApplyOffset(f(:,:,2),o);
                end
            
                if ~isempty(vn_x) && ~all(f(:,:,3)==0,'all')
                    o = vn_s(iFindId(vn_x(:,2),f_i))+1;
                    fc{i,7} = iApplyOffset(f(:,:,3),o);
                end
            
                fc{i,8} = height(f);
            end

            fc = [{'object','group','material','smooth','vertices','texture_coords','normals','count'} ; num2cell(fc,1)];
            obj.faces = struct(fc{:});
            
            l_x = iExtents(type == "l");
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
                lv = iLinearSimplify(lv);
            
                o = vn_s(iFindId(vn_x(:,2),l_i))+1;
                lv = cellfun(@(c) iApplyOffset(c,o),lv,'uni',0);
                nlv = numel(lv);
                l_v{i} = lv;
                l_o{i} = repmat({iFindId(o_x,l_i)},nlv,1);
                l_g{i} = repmat({iFindId(g_x,l_i)},nlv,1);
            end
            
            vc = @(x) vertcat(x{:});
            obj.lines = struct('g',vc(l_g),'o',vc(l_o),'v',vc(l_v));
        end
    end
end

function [i,n] = iExtents(tf)
    i = [strfind([0 tf(:)'],[0 1])' strfind([tf(:)' 0],[1 0])'];
    n = diff(i,[],2)+1;
end

function str = iLines2Mat(str,maxDim2)
    if isempty(str), return, end
    ns = str.count(" ");
    ms = max(ns);
    if ms+1 > maxDim2
        error('size of dim 2 exceeds %i',maxDim2)
    end
    str = str.pad(str.strlength + ms - ns,"right"," ").split(" ",2);
end

function id = iFindId(x,i)
    id = find(x < i,1,'last');
    if isempty(id), id = []; end
end

function x = iApplyOffset(x,o)
    tf = x < 0;
    x(tf) = x(tf) + o;
end

function s = iReadMtl(filename)
    [type,str] = iReadTypeTextLines(filename);
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

function [type,str] = iReadTypeTextLines(filename)
    str = readlines(filename,"WhitespaceRule","trim","EmptyLineRule","skip");
    icom = str.contains("#");
    str(icom) = strtrim(str(icom).extractBefore("#"));
    str = str.replace(sprintf('\t'),' ');
    str = str(str.strlength > 0);
    type = str.extractBefore(' ');
    str = str.extractAfter(' ').strip;
end

function ind2 = iLinearSimplify(ind)
    ind2 = ind;
    return
    
    % todo
    % simplify [1 2 ; 2 3 ; 3 4 ; ... ] to [1 2 3 4] (easy)
    % also [1 2 ; 3 4 ; 3 2] to [1 2 3 4] (less easy)
    
    % x = cellfun(@(x) x([1 end]),ind,'Uni',0);
    % x = vertcat(x{:});

end

