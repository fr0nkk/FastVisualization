classdef fvPrimitive < internal.fvDrawable
%FVPRIMITIVE
    
    properties(Transient,SetObservable)
        Coord % vertex coords
        Color % vertex color | vertex texture uv
        Normal % vertex normals
        Index % index data
        MaterialIndex % vertex material index
        Material % glMaterial array
        PrimitiveType

        Colormap = 'jet' % [N x 3] array | char | function_handle
        Light = struct('Offset',[0 0 0],'Ambient',[0.2 0.2 0.2],'Diffuse',[0.8 0.8 0.8],'Specular',[1 1 1]);
        Cull = 0;

        % for use with normals and no material
        Specular = [0.5 0.5 0.5];
        Shininess = 10;
    end

    events
        CoordsChanged
        ColorChanged
        NormalsChanged
        PrimitiveIndexChanged
    end

    properties(Dependent)
        Count
        ndims
    end

    properties(Dependent,Hidden)
        % heavy to calculate
        worldCoords
        worldBBox
    end

    properties(Hidden,SetAccess=private)
        model_offset
        glDrawable
        batch_mtl_idx
        batch_mtl
    end

    properties(Access=protected)
        glProg
    end

    properties(Dependent,Access=protected)
        glCoords
        glNormals
        glColor

        validCoords
        validColor
        validPrimIdx
        validMtlIdx
        validMaterial
    end

    properties(Access=private)
        needRecalc = 1;
        auto_color_id
        mtl_el
    end
    
    methods

        function obj = fvPrimitive(parent,prim_type,coords,color,normals,prim_index,material,material_index,varargin)
            obj@internal.fvDrawable(parent);
            if nargin < 4, color = []; end
            if nargin < 5, normals = []; end
            if nargin < 6, prim_index = []; end
            if nargin < 7, material = []; end
            if nargin < 8, material_index = []; end
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
            obj.glDrawable = glmu.drawable.MultiElement(obj.glProg,obj.PrimitiveType,uint32(0),{obj.glCoords obj.glNormals obj.glColor});
            obj.glDrawable.idUni = obj.glDrawable.program.uniforms.elemid;
            obj.glDrawable.uni.pointMask = 0;

            if isa(parent,'fvFigure')
                parent.addprimitive(obj);
            else
                parent.addChild(obj);
            end
            obj.isInit = true;

            if nargin >= 9
                set(obj,varargin{:});
                if isa(obj.parent,'fvFigure') && ~obj.fvfig.isHold
                    obj.ZoomTo;
                end
            end

        end

        function n = get.Count(obj)
            n = height(obj.Coord);
        end

        function d = get.ndims(obj)
            d = width(obj.Coord);
        end

        function set.Coord(obj,v)
            if width(v) > 3
                error('Coords must be [N x 3] or [N x 2]')
            end
            temp2 = obj.UpdateOnCleanup;
            obj.Coord = v;
            obj.needRecalc = 1;
            obj.InvalidateBBox;
            if height(obj.Color) == 1
                obj.Color = obj.Color;
            end
            notify(obj,'CoordsChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({obj.glCoords});
        end

        function set.Normal(obj,v)
            temp2 = obj.UpdateOnCleanup;
            obj.Normal = v;
            notify(obj,'NormalsChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({[] obj.glNormals });
        end

        function set.Colormap(obj,cmap)
            sz = size(cmap);
            if ~isscalartext(cmap) && (sz(1) < 1 || sz(2) ~= 3 || numel(sz) > 2) && ~isa(cmap,'function_handle')
                error('Colormap must be [m x 3] where m is at least 1')
            end
            obj.Colormap = cmap;
            obj.UpdateColor();
        end

        function set.Color(obj,v)
            temp = obj.UpdateOnCleanup;
            obj.Color = v;
            obj.UpdateColor();
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

        function c = get.validColor(obj)
            c = obj.Color;
            if width(c) == 1
                cmap = obj.Colormap;
                if isscalartext(cmap)
                    cmap = str2func(cmap);
                end
                if isa(cmap,'function_handle')
                    cmap = cmap(256);
                end
                % colormap mode
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

        function set.Material(obj,mtl)
            obj.Material = mtl;
            obj.needRecalc = 1;
            obj.Update;
        end

        function M = get.validMaterial(obj)
            M = obj.Material;
            if iscell(M)
                M = vertcat(M{:});
            end
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

        function xyz = get.worldCoords(obj)
            xyz = mapply(obj.validCoords,obj.full_model);
        end

        function bbox = get.worldBBox(obj)
            bbox = fvBoundingBox.coords2bbox(obj.worldCoords);
        end

        function AutoCalcNormals(obj)
            T = triangulation(double(obj.validPrimIdx),double(obj.validCoords));
            obj.Normal = T.vertexNormal;
        end

        function ZoomTo(obj)
            obj.Camera.ZoomBBox(obj.worldBBox);
        end

        function delete(obj)
            delete(obj.mtl_el);
        end
    end

    methods(Access=protected)

        function DrawFcn(obj,M)
            if obj.needRecalc
                obj.RecalcBatch;
                obj.needRecalc = 0;
            end
            V = obj.Camera.MView;
            MO = M * obj.model_offset;
            uni = obj.glDrawable.program.uniforms;
            uni.modelview.Set(V * MO);
            
            uni.alpha.Set(obj.Alpha);
            
            if isempty(obj.Normal)
                uni.lighting.Set('none');
                uni.edlDivisor.Set(1);
            else
                uni.lighting.Set('phong');
                uni.edlDivisor.Set(0.001);
                uni.model.Set(MO);
                axLight = obj.fvfig.Light;
                uni.light.position.Set(axLight.Position + obj.Light.Offset);
                uni.light.ambient.Set(axLight.Ambient .* obj.Light.Ambient);
                uni.light.diffuse.Set(axLight.Diffuse .* obj.Light.Diffuse);
                uni.light.specular.Set(axLight.Specular .* obj.Light.Specular);
                if isempty(obj.Material)
                    uni.material_spec.Set(obj.Specular);
                    uni.material_shin.Set(obj.Shininess);
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

        function UpdateColor(obj)
            notify(obj,'ColorChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({[] [] obj.glColor});
            obj.Update;
        end
    end

    methods (Access = protected)
        function propgrp = getPropertyGroups(~)
            propgrp = matlab.mixin.util.PropertyGroup({'Specular'});
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



