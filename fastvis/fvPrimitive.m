classdef fvPrimitive < fvDrawable
    %GLPOINTCLOUD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Transient,SetObservable)
        Coord % vertex coords
        Color % vertex color | vertex texture uv
        Normal % vertex normals
        Index % index data
        MaterialIndex % vertex material index
        Material % glMaterial array
        Colormap = jet(256) % [N x 3] array
        Light = struct('Offset',[0 0 0],'Ambient',[0.2 0.2 0.2],'Diffuse',[1 1 1],'Specular',[1 1 1]);

        % for use with normals and no material
        Specular = [0.5 0.5 0.5];
        Shininess = 10;
        primitive_type
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

    properties(Hidden,SetAccess=protected)
        model_offset
        glDrawable
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

        function obj = fvPrimitive(parent,prim_type,coords,color,normals,prim_index,material,material_index)
            obj@fvDrawable(parent);
            if nargin < 4, color = []; end
            if nargin < 5, normals = []; end
            if nargin < 6, prim_index = []; end
            if nargin < 7, material = []; end
            if nargin < 8, material_index = []; end
            obj.Coord = coords;
            obj.Normal = normals;
            obj.Color = color;
            obj.Index = prim_index;
            obj.primitive_type = prim_type;
            obj.Material = material;
            obj.MaterialIndex = material_index;
            obj.auto_color_id = obj.fvfig.NextColorId;
            
            [gl,gltemp] = obj.getContext;

            obj.glProg = obj.fvfig.ctrl.InitProg('fvprim');
            obj.glDrawable = glmu.drawable.MultiElement(obj.glProg,obj.primitive_type,uint32(0),{obj.glCoords obj.glNormals obj.glColor});
            obj.glDrawable.idUni = obj.glDrawable.program.uniforms.elemid;
            obj.glDrawable.uni.pointMask = 0;

            if isa(parent,'fvFigure')
                parent.addprimitive(obj);
            else
                parent.addChild(obj);
            end
            obj.isInit = true;
        end

        function n = get.Count(obj)
            n = height(obj.Coord);
        end

        function d = get.ndims(obj)
            d = width(obj.Coord);
        end

        function set.Coord(obj,v)
            temp2 = obj.UpdateOnCleanup;
            obj.Coord = v;
            obj.InvalidateBBox;
            obj.AdjustIData;
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
            obj.AdjustIData;
            notify(obj,'PrimitiveIndexChanged');
            obj.Update;
        end

        function set.primitive_type(obj,p)
            obj.primitive_type = p;
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
            n = var2gl(n,3,obj.Count)';
        end

        function c = get.glColor(obj)
            c = obj.validColor;
            c = var2gl(c,3,obj.Count)';
        end

        function ind = get.validPrimIdx(obj)
            ind = obj.Index;
            if isempty(ind)
                ind = (1:obj.Count)';
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
        end

        function c = get.validColor(obj)
            c = obj.Color;
            if width(c) == 1
                % colormap mode
                if isinteger(c)
                    c = single(c) ./ single(intmax(class(c)));
                end
                h = height(obj.Colormap);
                c = clamp(floor(c.*h)+1,1,h);
                c = obj.Colormap(c,:);
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

        function UpdateColor(obj)
            notify(obj,'ColorChanged');
            if ~obj.isInit, return, end
            [gl,temp] = obj.getContext;
            obj.glDrawable.array.EditBuffer({[] [] obj.glColor});
            obj.Update;
        end

        function xyz = get.worldCoords(obj)
            xyz = mapply(obj.validCoords,obj.full_model);
        end

        function bbox = get.worldBBox(obj)
            bbox = fvBoundingBox.coords2bbox(obj.worldCoords);
        end

        function ZoomTo(obj)
            obj.fvfig.Camera.ZoomBBox(obj.worldBBox);
        end

        function delete(obj)
            delete(obj.mtl_el);
        end
    end

    methods(Access=protected)

        function DrawFcn(obj,V)
            if obj.needRecalc
                obj.RecalcBatch;
                obj.needRecalc = 0;
            end
            MO = obj.full_model * obj.model_offset;
            uni = obj.glDrawable.program.uniforms;
            uni.modelview.Set(V * MO);
            
            uni.alpha.Set(obj.alpha);
            
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
                [um,~,g] = unique(m);
                F = splitapply(@(c) {c},p,g);
                
                co = cellfun(@numel,F);
                co = [co cumsum([0 ; co(1:end-1)])];

                obj.glDrawable.EditElement(ind2glind(vertcat(F{:})));
                M = obj.validMaterial(um);
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
        
        function AdjustIData(obj)
            k = any(obj.Index > obj.Count | obj.Index < 1,2);
            if any(k)
                obj.Index = obj.Index(~k,:);
            end
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



