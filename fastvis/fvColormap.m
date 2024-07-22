classdef fvColormap < handle & matlab.mixin.SetGet

    properties(SetObservable)
        Source
        N (1,1) double {mustBeInteger} = 256
        Interp char {mustBeMember(Interp,{'nearest','linear'})} = 'linear'
    end

    properties(Dependent)
        isFcn
        isBuiltin
    end

    events
        Modified
    end
    
    methods
        function obj = fvColormap(source,N,varargin)
            if nargin < 1, source = 'parula'; end

            if isempty(source)
                obj = fvColormap.empty;
                return
            end

            if isa(source,'fvColormap')
                obj = source;
                return
            end

            obj.Source = source;
            if nargin >= 2
                obj.N = N;
            end
            if ~isempty(varargin)
                set(obj,varargin{:});
            end

            addlistener(obj,{'Source','N','Interp'},'PostSet',@(~,evt) notify(obj,'Modified',evt));
        end

        function tf = get.isFcn(obj)
            tf = iisFcn(obj.Source);
        end

        function tf = get.isBuiltin(obj)
            tf = ismember(char(obj),obj.BuiltinColormaps);
        end

        function str = char(obj)
            if obj.isFcn
                str = char(obj.Source);
            else
                str = sprintf('%ix3 Custom',size(obj.Source,1));
            end
        end

        function im = img(obj)
            im = permute(double(obj),[3 1 2]);
        end

        function set.Source(obj,src)
            if iisFcn(src)
                testN = 10;
                try
                    cmap = feval(src,testN);
                catch
                    error('invalid colormap');
                end
                if size(cmap,1) ~= testN
                    error('invalid colormap format');
                end
            else
                src = double(src);
                cmap = src;
            end

            if ~isfloat(cmap) || ~ismatrix(cmap) || size(cmap,2) ~= 3
                error('invalid colormap format');
            end

            obj.Source = src;

        end

        function cmap = double(obj)
            n = obj.N;
            doFlip = n < 0;
            n = max(abs(n),1);
            if obj.isFcn
                cmap = feval(obj.Source,n);
            else
                k = size(obj.Source,1);
                idx = linspace(1,k,n);
                cmap = interp1((1:k)',obj.Source,idx,obj.Interp);
            end
            if doFlip, cmap = flipud(cmap); end
            cmap = double(cmap);
        end
        
    end

    methods(Hidden)

        function ui(obj,parent)

            fvJLinkedValue(parent,mfilename);

            items = obj.BuiltinColormaps;
            itemsData = items;
            if ~obj.isBuiltin
                items = [{char(obj)} ; items];
                itemsData = [{obj.Source} ; itemsData];
            end

            c = fvJLinkedValue(parent,'Colormap',obj,'Source','Comp',@fvJLinkedComboBox,'Items',items,'ItemsData',itemsData);
            gbl = c.parent;
            gbl.Y(2) = 6;
            gbl.MaximumSize(2) = gbl.PreferredSize(2);

            im = JImage(gbl,'Value',img(obj),'ScaleMethod','Stretch','Constraints',JConstraints([2 4],2));
            el = addlistener(obj,'Modified',@(src,evt) set(im,'Value',img(obj)));
            addlistener(im,'ObjectBeingDestroyed',@(~,~) delete(el));

            fvJLinkedValue(parent,'Cmap N',obj,'N','DragStep',0.25);

        end

    end

    methods(Static)
        function cmaps = BuiltinColormaps()
            cmaps = fvConfig().colormaps;
            tf = logical(cellfun(@(c) exist(c,'file'),cmaps));
            cmaps = cmaps(tf);
        end
    end

end

function tf = iisFcn(src)
    tf = ismember(class(src),{'function_handle','char','string'});
end

