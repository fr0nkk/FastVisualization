classdef fvPrimitive < internal.fvDrawable
%FVPRIMITIVE
    
    properties(Transient,SetObservable)
        % Coord - vertex coordinates
        % Must be [N x 2] or [N x 3] where N is the number of vertex
        Coord

        % Color - Vertex color, texture uv, or index for colormap.
        % If floating point (single or double), range must be from 0 to 1
        % Color per vertex: [N x 3]
        % Texture uv per vertex: [N x 2]
        % Index for colormap: [N x 1]
        % If empty, the primitive's color will use the ColorOrder of its fvFigure
        % If there are less colors than the number of coords, the last
        % color will be replicated to match the number of coords.
        Color

        % Normal - vertex normals
        % Used for rendering triangulated surfaces
        % if not set and the primitive is a triangulated surface, the
        % render will use EDL to render the light
        Normal

        % Index - Coord's index to render
        % If empty, all the vertex are used sequentially
        Index

        % MaterialIndex - Index of material to use for each vertex
        MaterialIndex
        
        % Material - array of fvMaterial indexes by MaterialIndex
        Material

        % PrimitiveType - Type of primitive
        % Can be: GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN
        PrimitiveType

        % Colormap - Colormap to use when colors are in colormap mode
        % Can be [M x 3] where M is the number of colors, or the name of a colormap
        Colormap = 'parula'
        
        % Light - Struct containing information about this primitive's light
        % The struct must contain Offset, Ambient, Diffuse and Specular
        Light = struct('Offset',[0 0 0],'Ambient',[0.3 0.3 0.3],'Diffuse',[0.8 0.8 0.8],'Specular',[1 1 1]);

        % Cull - Cull the front faces
        % 0: no cull
        % 1: cull font faces
        % -1 cull back faces
        Cull = 0;

        % Specular - Primitive's specular when rendering with color per vertex
        Specular = [0.5 0.5 0.5];

        % Shininess - Primitive's shininess when rendering with color per vertex
        Shininess = 10;
    end

    properties(Dependent)
        isColormapped
    end

    events
        CoordsChanged
        ColorChanged
        NormalsChanged
        PrimitiveIndexChanged
    end

    properties(Hidden,SetAccess=private)
        model_offset
        glDrawable
        batch_mtl_idx
        batch_mtl
    end

    properties(Access=protected)
        glProg glmu.Program
    end
    
    properties(Access=private)
        needRecalc = 1;
        auto_color_id
        mtl_el
    end

    properties(Hidden,Dependent)
        glCoords
        glNormals
        glColor
        validPrimIdx
        validMtlIdx
        validCoords
        validMaterial
        validColor
    end
    
    methods

        function obj = fvPrimitive(parent,prim_type,coords,color,normals,prim_index,material,material_index,varargin)
            if nargin < 1, parent = []; end
            obj@internal.fvDrawable(parent);
            
            if nargin < 2, prim_type = 'GL_POINTS'; end
            if nargin < 3, coords = [0 0 0]; end
            if nargin < 4, color = []; end
            if nargin < 5, normals = []; end
            if nargin < 6, prim_index = []; end
            if nargin < 7, material = []; end
            if nargin < 8, material_index = []; end

            if height(coords) == 1 && width(coords) > 3
                coords = coords';
            end

            if width(coords) == 1
                coords(:,2) = (1:height(coords))';
                coords = fliplr(coords);
            end

            obj.Coord = coords;
            obj.Normal = normals;
            obj.Color = color;
            obj.Index = prim_index;
            obj.PrimitiveType = prim_type;
            obj.Material = material;
            obj.MaterialIndex = material_index;
            obj.auto_color_id = obj.fvfig.NextColorId;
            
            [gl,gltemp] = obj.getContext;

            shdPath = execdir(fileparts(mfilename('fullpath')),'shaders','fvprim');
            obj.glProg = obj.fvfig.ctrl.InitProg(shdPath);
            obj.glDrawable = glmu.drawable.MultiElement(obj.glProg,obj.PrimitiveType,uint32([0 0 0]),{obj.glCoords obj.glNormals obj.glColor});
            obj.glDrawable.idUni = obj.glDrawable.program.uniforms.elemid;
            obj.glDrawable.uni.pointMask = 0;
            obj.Name = 'fvPrimitive';
            obj.RightClickMenu = @internal.fvPrimitive.Menu;
            % parent.addChild(obj);
            obj.isInit = true;
            
            if ~isempty(varargin)
                set(obj,varargin{:});
            end

        end

        function n = Count(obj)
            n = height(obj.Coord);
        end

        function d = ndims(obj)
            d = width(obj.Coord);
        end

        function set.Coord(obj,v)
            if width(v) > 3
                error('Coords must be [N x 3] or [N x 2]')
            end
            temp2 = obj.PauseUpdates;
            obj.Coord = v;
            obj.needRecalc = 1;
            obj.InvalidateBBox;
            obj.UpdateColor;
            notify(obj,'CoordsChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({obj.glCoords});
        end

        function set.Normal(obj,v)
            temp2 = obj.PauseUpdates;
            obj.Normal = v;
            notify(obj,'NormalsChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({[] obj.glNormals });
            obj.Update;
        end

        function set.Colormap(obj,cmap)
            sz = size(cmap);
            if ~isscalartext(cmap) && (sz(1) < 1 || sz(2) ~= 3 || numel(sz) > 2) && ~isa(cmap,'function_handle')
                error('Colormap must be [m x 3] where m is at least 1')
            end
            obj.Colormap = cmap;
            obj.UpdateColor();
            notify(obj,'ColorChanged');
        end

        function set.Color(obj,v)
            temp = obj.PauseUpdates;
            obj.Color = v;
            obj.UpdateColor();
            notify(obj,'ColorChanged');
        end

        function set.Index(obj,idx)
            obj.Index = idx;
            obj.needRecalc = 1;
            obj.InvalidateBBox;
            notify(obj,'PrimitiveIndexChanged');
            obj.Update;
        end

        function set.PrimitiveType(obj,p)
            obj.PrimitiveType = p;
            if ~obj.isInit, return, end
            obj.glDrawable.primitive = obj.glDrawable.Const(p);
            obj.Update;
        end

        function set.Material(obj,mtl)
            obj.Material = mtl;
            obj.needRecalc = 1;
            obj.Update;
        end

        function set.Light(obj,s)
            obj.Light = s;
            obj.Update;
        end

        function set.Cull(obj,c)
            obj.Cull = c;
            obj.Update;
        end

        function set.Shininess(obj,s)
            obj.Shininess = s;
            obj.Update;
        end

        function set.Specular(obj,s)
            if numel(s) == 1
                s = [s s s];
            end
            obj.Specular = s;
            obj.Update;
        end

        function xyz = worldCoords(obj)
            xyz = mapply(obj.validCoords,obj.full_model);
        end

        function bbox = worldBBox(obj)
            bbox = fvBoundingBox.coords2bbox(obj.worldCoords);
        end

        function AutoCalcNormals(obj)
            T = triangulation(double(obj.validPrimIdx),double(obj.validCoords));
            obj.Normal = T.vertexNormal;
        end

        function ZoomTo(obj)
            bbox = obj.BoundingBox;
            xyz = fvBoundingBox.bbox2corners(bbox);
            xyz = mapply(xyz,obj.fvfig.Model * obj.full_model);
            bbox = fvBoundingBox.coords2bbox(xyz);
            obj.validCamera.ZoomBBox(bbox);
        end

        function xyz = get.glCoords(obj)
            xyz = double(obj.validCoords);
            xyz0 = mean(xyz,'omitnan');
            xyz = single(xyz - xyz0)';
            obj.model_offset = MTrans3D(xyz0);
        end

        function n = get.glNormals(obj)
            n = obj.Normal;
            if isempty(n)
                n = [0 0 1];
            end
            n = internal.var2gl(n,3,obj.Count)';
        end

        function c = get.glColor(obj)
            c = obj.validColor;
            c = internal.var2gl(c,3,obj.Count)';
        end

        function ind = get.validPrimIdx(obj)
            ind = obj.Index;
            if isempty(ind)
                ind = (1:obj.Count)';
            end

            k = any(ind > obj.Count | ind < 1,2);
            if any(k)
                ind = ind(~k,:);
            end
        end

        function m = get.validMtlIdx(obj)
            m = obj.MaterialIndex;
            m(end+1:obj.Count,1) = 1;
        end

        function xyz = get.validCoords(obj)
            xyz = obj.Coord;
            if width(xyz) < 3
                xyz(:,end+1:3) = 0;
            end
            if ~isfloat(xyz)
                xyz = single(xyz);
            end
        end

        function tf = get.isColormapped(obj)
            tf = width(obj.Color) == 1;
        end

        function c = get.validColor(obj)
            c = obj.Color;
            if obj.isColormapped
                % colormap mode
                cmap = obj.Colormap;
                if isscalartext(cmap)
                    cmap = str2func(cmap);
                end
                if isa(cmap,'function_handle')
                    cmap = cmap(256);
                end
                h = height(cmap);
                if isfloat(c)
                    c = floor(c.*h)+1;
                end
                
                c = cmap(clamp(c,1,h),:);
            end
            if isempty(c)
                cmap = obj.fvfig.ColorOrder;
                k = mod1(obj.auto_color_id,height(cmap));
                c = cmap(k,:);
            end
        end

        function M = get.validMaterial(obj)
            M = obj.Material;
            if iscell(M)
                M = vertcat(M{:});
            end
        end

        function delete(obj)
            delete(obj.mtl_el);
        end
    end

    methods(Access=protected)

        function DrawFcn(obj,M,j)
            if obj.needRecalc
                obj.RecalcBatch;
                obj.needRecalc = 0;
            end

            u = obj.glProg.uniforms;
            cam = obj.validCamera;
            u.drawid.Set(j);
            u.projection.Set(cam.MProj);
            u.viewPos.Set(cam.getCamPos);

            MO = M * obj.model_offset;
            u.modelview.Set(cam.MView * MO);
            
            u.alpha.Set(obj.Alpha);
            
            if isempty(obj.Normal)
                u.lighting.Set('none');
                u.edlDivisor.Set(1);
            else
                u.lighting.Set('phong');
                u.edlDivisor.Set(0.001);
                u.model.Set(MO);
                axLight = obj.fvfig.Light;
                u.light.position.Set(axLight.Position + obj.Light.Offset);
                u.light.ambient.Set(axLight.Ambient .* obj.Light.Ambient);
                u.light.diffuse.Set(axLight.Diffuse .* obj.Light.Diffuse);
                u.light.specular.Set(axLight.Specular .* obj.Light.Specular);
                if isempty(obj.Material)
                    u.material_spec.Set(obj.Specular);
                    u.material_shin.Set(obj.Shininess);
                end
            end

            gl = obj.glDrawable.gl;
            if obj.Cull
                gl.glEnable(gl.GL_CULL_FACE);
                if obj.Cull > 0
                    gl.glFrontFace(gl.GL_CCW);
                else
                    gl.glFrontFace(gl.GL_CW);
                end
            else
                gl.glDisable(gl.GL_CULL_FACE);
            end

            obj.glDrawable.Draw;
        end

        function RecalcBatch(obj)
            p = obj.validPrimIdx;
            delete(obj.mtl_el);
            if isempty(obj.Material)
                obj.glDrawable.multi_uni = [];
                glp = ind2glind(p);
                obj.glDrawable.EditElement(glp);

                obj.glDrawable.uni.color_source = 'vertex_color';
                obj.glDrawable.countoffsets = [numel(glp) 0];
            else
                if isfield(obj.glDrawable.uni,'color_source')
                    obj.glDrawable.uni = rmfield(obj.glDrawable.uni,'color_source');
                end
                m = mode(obj.validMtlIdx(p),2);
                [obj.batch_mtl,~,g] = unique(m);
                obj.batch_mtl_idx = splitapply(@(c) {c},int32(1:height(p))',g);
                
                co = cellfun(@numel,obj.batch_mtl_idx).*width(p);
                co = [co cumsum([0 ; co(1:end-1)])];

                p = p(vertcat(obj.batch_mtl_idx{:}),:);
                obj.glDrawable.EditElement(ind2glind(p));
                M = obj.validMaterial(obj.batch_mtl);
                obj.glDrawable.multi_uni = arrayfun(@(a) obj.fvfig.mtlCache.UniStruct(a,0),M,'uni',0);
                mtl_idx = (1:numel(M))';
                obj.mtl_el = arrayfun(@(k) addlistener(M(k),'PropChanged',@(src,evt) obj.EditMaterial(src,k)),mtl_idx);
                obj.glDrawable.countoffsets = co;
            end
        end

        function bbox = GetBBox(obj)
            ind = obj.validPrimIdx;
            ind = ind(~skipIdx(ind));
            x = obj.validCoords(ind(:),:);
            bbox = fvBoundingBox.coords2bbox(x);
        end

        function EditMaterial(obj,src,k)
            [gl,temp] = obj.getContext;
            obj.glDrawable.multi_uni{k} = obj.fvfig.mtlCache.UniStruct(src,1);
            obj.Update;
        end
    end

    methods(Hidden)

        function UpdateColor(obj)
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({[] [] obj.glColor});
            obj.Update;
        end
        
        function s = id2info(obj,elemId,primId)
            s.mtlId = [];
            if ~isempty(obj.Material)
                primId = obj.batch_mtl_idx{elemId}(primId);
                s.mtlId = obj.batch_mtl(elemId);
            end
            s.primId = primId;
        end
    end

    methods(Hidden,Static)
        function m = Menu(o,evt)
            x = mapply(evt.data.xyz,o.full_model,0);
            m = {
                    JMenuItem(internal.fvPopup.CoordText(x,'local'), @(~,~) assignans(x));
                };
            m = [m ; Menu@internal.fvChild(o,evt)];
        end
    end

end

function ind = ind2glind(ind)
    ind = ind' - 1;
    if isa(ind,'uint32'), return, end
    k = skipIdx(ind);
    ind = uint32(ind);
    ind(k) = intmax('uint32');
end

function tf = skipIdx(ind)
    if isinteger(ind)
        tf = ind == intmax(class(ind));
    else
        tf = isnan(ind);
    end
end



