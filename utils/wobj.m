classdef wobj < handle

    properties(SetAccess = protected)
        source
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
            fn = which(filename);
            if isempty(fn), fn = filename; end
            obj.source = fn;
            [type,str] = iReadTypeTextLines(obj.source);
            
            o_x = find(type == "o");
            g_x = find(type == "g");
            m_x = find(type == "usemtl");
            s_x = find(type == "s");
            
            obj.group = str(g_x);
            obj.object = str(o_x);
            
            
            d = fileparts(obj.source);
            m_str = str(type == "mtllib");
            if ~isempty(m_str)
                obj.material = iReadMtl(fullfile(d,m_str));
                [~,m_i] = ismember(str(m_x),[obj.material.name]');
            else
                obj.material = struct.empty;
                m_i = [];
            end
            m_i = int32(m_i);
            
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
                tf = ~f.contains("/");
                f(tf) = f(tf).append("//");
                k = f.count("/") == 1;
                f(k) = f(k).append("/");
                f = int32(f.split("/",3).double);
                o = v_s(iFindId(v_x(:,2),f_i))+1;
                fc{i,5} = iApplyOffset(f(:,:,1),o);
            
                if ~isempty(vt_x)% && ~all(f(:,:,2)==0,'all')
                    o = vt_s(iFindId(vt_x(:,2),f_i))+1;
                    fc{i,6} = iApplyOffset(f(:,:,2),o);
                end
            
                if ~isempty(vn_x)% && ~all(f(:,:,3)==0,'all')
                    o = vn_s(iFindId(vn_x(:,2),f_i))+1;
                    fc{i,7} = iApplyOffset(f(:,:,3),o);
                end
            
                fc{i,8} = height(f);
            end

            fc = [{'object','group','material','smooth','vertices','texture_coords','normals','count'} ; num2cell(fc,1)];
            obj.faces = struct(fc{:});
            clear fc
            
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

        function [tri,xyz,texCoord,normals,materials,vertex_material] = getDrawData(obj)
            fv = cellfun(@trifan,{obj.faces.vertices},'uni',0);
            h = cellfun(@height,fv);
            fv = vertcat(fv{:});
            tf = ~any(fv==0,2);
            fv = fv(tf,:);
            
            fn = cellfun(@trifan,{obj.faces.normals},'uni',0);
            fn = vertcat(fn{:});
            if ~isempty(fn), fn = fn(tf,:); end
            fn(fn==0) = 1;
            
            ft = cellfun(@trifan,{obj.faces.texture_coords},'uni',0);
            ft = vertcat(ft{:});
            if ~isempty(ft), ft = ft(tf,:); end
            ft(ft==0) = 1;
            
            fm = repmat(repelem([obj.faces.material],1,h)',1,3);
            if ~isempty(fm), fm = fm(tf,:); end
            
            w = [width(obj.vertices) width(obj.normals) width(obj.texture_coords) width(fm)/3];
            
            V = [obj.vertices(fv,:) obj.normals(fn,:) obj.texture_coords(ft,:) single(fm(:))];
            [uv,~,tri] = unique(V,'rows');
            tri = reshape(tri,[],3);
            
            uv = mat2cell(uv,height(uv),w);
            [xyz, normals, texCoord, vertex_material] = uv{:};
            
            materials = cell(numel(obj.material),1);
            d0 = fileparts(obj.source);
            for i=1:numel(obj.material)
                m = obj.material(i);
                if isfield(m,'map_Kd') && ~isempty(m.map_Kd)
                    col = fullfile(d0,m.map_Kd);
                else
                    col = m.Kd.split(" ",2).double;
                end
                if isfield(m,'map_d') && ~isempty(m.map_d)
                    a = imread(fullfile(d0,m.map_d));
                    a = single(a) ./ 255;
                    a = mean(a,3);
                elseif isfield(m,'d')
                    a = m.d.double;
                else
                    a = 1;
                end
                materials{i} = fvMaterial(col,a);
            end
            materials = vertcat(materials{:});
        end
    end
end

function [i,n] = iExtents(tf)
    i = [strfind([0 tf(:)'],[0 1])' strfind([tf(:)' 0],[1 0])'];
    n = diff(i,[],2)+1;
end

function str = iLines2Mat(str,maxDim2)
    if isempty(str), str = string.empty; return, end
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

