classdef fvMaterialCache < handle
    %GLMATERIALCACHE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fvfig fvFigure
        mtl fvMaterial
        tex cell
        texNeedRecalc logical
    end
    
    methods
        function obj = fvMaterialCache(fvfig)
            obj.fvfig = fvfig;
        end
        
        function s = UniStruct(obj,mtl,forceRecalc)
            % must be on a gl context
            k = find(ismember(obj.mtl,mtl));
            if isempty(k)
                k = numel(obj.mtl)+1;
                obj.mtl(k) = mtl;
                obj.tex{k} = [];
                obj.texNeedRecalc(k) = true;
            end

            obj.texNeedRecalc(k) = forceRecalc | obj.texNeedRecalc(k);

            s=struct;
            if mtl.isTex
                s.color_source = 'material_texture';
                s.material_tex = obj.getTex(k);
            else
                s.color_source = 'material_color';
                col = mtl.color;
                if width(col) < 4
                    col(:,4) = 1;
                end
                s.material_col = col;
            end
            s.material_spec = mtl.specular;
            s.material_shin = mtl.shininess;
        end

    end
    methods(Access=private)
        function t = getTex(obj,k)
            if obj.texNeedRecalc(k)
                m = obj.mtl(k);
                if ischar(m.color) || isstring(m.color)
                    img = imread(m.color);
                else
                    img = m.color;
                end
                sz = size(img,[1 2]);
                if max(sz) > 2048
                    sz(sz > 2048) = 2048;
                    img = imresize(img,sz);
                end
                if ~isfloat(img)
                    img = single(img)./single(intmax(class(img)));
                end
                if ~isa(img,'single')
                    img = single(img);
                end
                if size(img,3) == 1
                    img = repmat(img,1,1,3);
                end
                if size(img,3) < 4
                    img(:,:,4) = 1;
                end
                if isempty(obj.tex{k})
                    obj.tex{k} = glmu.Texture(7,'GL_TEXTURE_2D',img,'GL_RGBA',0);
                else
                    obj.tex{k}.Edit(img,'GL_RGBA',1);
                end
                obj.texNeedRecalc(k) = 0;
            end
            t = obj.tex{k};
        end
    end
end
