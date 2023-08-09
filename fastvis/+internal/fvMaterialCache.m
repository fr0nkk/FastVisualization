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
                col = mtl.Color;
                if size(col,2) == 1
                    col = [col col col];
                end
                if size(col,2) < 4
                    col(4) = 1;
                end
                col(4) = col(4) .* mtl.Alpha;
                s.material_col = col;
            end
            s.material_spec = mtl.Specular;
            s.material_shin = mtl.Shininess;
        end

    end
    methods(Access=private)
        function t = getTex(obj,k)
            if obj.texNeedRecalc(k)
                maxSize = 2048;
                m = obj.mtl(k);
                img = obj.getimg(m.Color,maxSize,3);
                if size(img,3) < 4
                    img(:,:,4) = 1;
                end
                sz = size(img);
                img(:,:,4) = img(:,:,4) .* obj.getimg(m.Alpha,maxSize,1,sz(1:2));
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
    methods(Static)
        function img = getimg(color,maxsz,expectedChannels,expectedSize)
            if isscalartext(color)
                [img,cmap] = imread(char(color));
                if ~isempty(cmap)
                    img = ind2rgb(img,cmap);
                end
            else
                img = color;
            end

            sz = size(img);
            sz = sz(1:2);
            if max(sz) > maxsz
                sz(sz > maxsz) = maxsz;
                img = imresize(img,sz);
            end
            if ~isfloat(img)
                    img = single(img)./single(intmax(class(img)));
            end
            if ~isa(img,'single')
                img = single(img);
            end
            c = size(img,3);
            if c == 1 && expectedChannels > 1
                img = repmat(img,1,1,expectedChannels);
            elseif c > 1 && expectedChannels == 1
                img = mean(img,3);
            end

            if nargin >= 4
                img = imresize(img,expectedSize);
            end

        end
    end
end
