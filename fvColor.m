classdef fvColor < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
    %FVCOLOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetObservable)
        Mode char {mustBeMember(Mode,{'Attribute','Function'})} = 'Attribute'
        Attributes struct
        Function char = '[1 1 1]'
        Rescale (1,1) logical = false
    end

    properties(Transient,SetObservable)
        MinMaxValue (1,2) double {mustBeReal}
        AutoScale (1,1) logical
        Current char
    end

    events
        ColorChanged
    end

    properties(Access=private)
        iMinMaxValue = [0 1]
        iAutoScale = true
        iCurrent
    end
    
    methods
        function obj = fvColor(attr,varargin)
            if ~isstruct(attr)
                attr = struct('Value',attr);
            end
            fn = fieldnames(attr);
            obj.Attributes = attr;
            obj.Current = fn{1};
            if nargin >= 2
                set(obj,varargin{:});
            end
            addlistener(obj,{'Mode','Function'},'PostSet',@(src,evt) notify(evt.AffectedObject,'ColorChanged'));
        end
        
        function c = Result(obj)
            switch obj.Mode
                case 'Attribute'
                    c = obj.Attributes.(obj.Current);
                case 'Function'
                    F = str2func(['@(a)' obj.Function]);
                    c = F(obj.Attributes);
            end
            
            if ~obj.Rescale, return, end

            if obj.iAutoScale
                obj.iMinMaxValue = [min(c(:),[],1,'omitnan') max(c(:),[],1,'omitnan')];
            end
            mm = obj.iMinMaxValue;
            c = single(rescale(c,'InputMin',min(mm),'InputMax',max(mm)));
            if diff(mm) < 0
                c = 1-c;
            end
        end

        function v = get.MinMaxValue(obj)
            v = obj.iMinMaxValue;
        end

        function set.MinMaxValue(obj,v)
            obj.iMinMaxValue = v;
            obj.iAutoScale = false;
            notify(obj,'ColorChanged');
        end

        function set.Current(obj,c)
            if ~isfield(obj.Attributes,c)
                error('Invalid attribute: %s\nMust be member of %s',c,strjoin(fieldnames(obj.Attributes),', '));
            end
            obj.iCurrent = c;
            notify(obj,'ColorChanged');
        end

        function c = get.Current(obj)
            c = obj.iCurrent;
        end

        function set.Rescale(obj,tf)
            obj.Rescale = tf;
            notify(obj,'ColorChanged');

        end

        function set.AutoScale(obj,tf)
            obj.iAutoScale = tf;
            notify(obj,'ColorChanged');
        end

        function tf = get.AutoScale(obj)
            tf = obj.iAutoScale;
        end
    end

    methods(Hidden)
        function ui(obj,parent)

            fvJLinkedValue(parent,mfilename);

            items = fieldnames(obj.Attributes);
            fvJLinkedValue(parent,'Mode',obj,'Mode');
            fvJLinkedValue(parent,'Attribute',obj,'Current','Comp',@fvJLinkedComboBox,'Items',items);
            fvJLinkedValue(parent,'Function',obj,'Function');

            fvJLinkedValue(parent,'Rescale',obj,'Rescale');
            fvJLinkedValue(parent,'AutoLimits',obj,{'AutoScale','MinMaxValue'});

            fcn = @(o) abs(diff(o.MinMaxValue))./200;
            fvJLinkedValue(parent,'Limits',obj,{'MinMaxValue','AutoScale','Current','Mode','Rescale'},'DragStep',fcn);

        end
    end
end

