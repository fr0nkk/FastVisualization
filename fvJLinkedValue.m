function c = fvJLinkedValue(parent,str,obj,prop,varargin)

p = inputParser;
p.addParameter('Comp',[]);
p.KeepUnmatched = true;
p.parse(varargin{:});
comp = p.Results.Comp;

gbl = JGridLayout(parent,'X',[70 -1],'Y',25,'Padding',0);
gbl.MaximumSize(2) = gbl.PreferredSize(2);

c = JLabel(gbl,'Text',str,'Constraints',JConstraints(1,1));

if nargin <= 2
    c.Font.Style = 'Bold';
    c.Constraints.X = [1 2];
    c.HorizontalAlignment = 'Center';
    return
end

prop = cellstr(prop);
P = metaclass(obj).PropertyList;
P = P(strcmp(prop{1},{P.Name}));

str = sprintf('%s: %s',P.Name,P.Description);
c.ToolTip = sprintf('<html><p width="160">%s</p></html>',str);

if isempty(comp)
    % autodetect
    v = obj.(prop{1});
    switch class(v)
        case {'double','single'}
            comp = @fvJLinkedNumericField;
        case 'logical'
            comp = @fvJLinkedCheckBox;
        case 'char'
            F = P.Validation.ValidatorFunctions;
            F = cellfun(@func2str,F,'uni',0);
            tf = contains(F,'mustBeMember');
            if tf
                str = regexp(F{tf},'(?<=mustBeMember\(.*?{).*?(?=}.*?\))','match','once');
                str = strrep(str,'''','');
                items = strsplit(str,',');
                comp = @(varargin) fvJLinkedComboBox(varargin{:},'Items',items);
            else
                comp = @fvJLinkedTextField;
            end
    end
end

c = comp(gbl,obj,prop,p.Unmatched,'Constraints',JConstraints(2,1));

end

