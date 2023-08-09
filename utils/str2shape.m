function shp = str2shape(str,lineSize,fontname,hAlignment,vAlignment,pts_per_bezier)

if ~ispc
    warning('str2shape may not be compatible since it uses NET.addAssembly')
end

NET.addAssembly('System.Drawing');

% call with no args returns all available fonts
persistent fonts
if nargin == 0
    if isempty(fonts)
        families = System.Drawing.Text.InstalledFontCollection().Families;
        n = families.Length;
        fonts = cell(n,1);
        for i=1:n
            fonts{i} = char(families(i).Name);
        end
    end
    shp = fonts;
    return
end

if nargin < 2, lineSize = 1; end
if nargin < 3, fontname = 'Arial'; end
if nargin < 4, hAlignment = 'left'; end
if nargin < 5, vAlignment = 'bottom'; end
if nargin < 6, pts_per_bezier = 4; end

FontData = System.Drawing.Drawing2D.GraphicsPath();

font = System.Drawing.Font(fontname,1);
family = font.FontFamily;

style=System.Drawing.FontStyle.Regular;

origin=System.Drawing.PointF(0,0);
format=System.Drawing.StringFormat();
format = format.GenericTypographic;

eh = double(family.GetEmHeight(style));
ls = double(family.GetLineSpacing(style))/eh;

switch lower(hAlignment)
    case 'left'
        format.Alignment = System.Drawing.StringAlignment.Near;
    case 'right'
        format.Alignment = System.Drawing.StringAlignment.Far;
    case 'center'
        format.Alignment = System.Drawing.StringAlignment.Center;
    otherwise
        error('Invalid hAlignment: %s \n Must be left, right or center',hAlignment)
end

switch lower(vAlignment)
    case 'top'
        format.LineAlignment = System.Drawing.StringAlignment.Near;
    case 'bottom'
        format.LineAlignment = System.Drawing.StringAlignment.Far;
    case 'center'
        format.LineAlignment = System.Drawing.StringAlignment.Center;
    otherwise
        error('Invalid vAlignment: %s \n Must be top, bottom or center',vAlignment)
end

FontData.AddString(str,family,int32(style),1,origin,format);

if ~FontData.PointCount
    shp = polyshape(zeros(0,2));
    return
end

n = FontData.PathPoints.Length;
xy = zeros(n,2);
p = FontData.PathPoints;

% this is slow, could not find a way to get all x and/or y at once...
for i=1:n
    pp = p(i);
    xy(i,:) = [pp.X pp.Y];
end
xy(:,2) = -xy(:,2); % ij to xy
xy = xy ./ ls .* lineSize;

t = FontData.PathTypes.uint8';

tb = double(bitand(t,uint8(7)));

shp2 = makeline(xy,tb,pts_per_bezier);

shp = polyshape(shp2,'Simplify',0);

end

function L = makeline(xy,t,ppl)

    nx = numel(t);
    nL = sum(t==3)/3*(ppl-1)+sum(t==1)+sum(t==0)*2;
    L = zeros(nL,2);
    
    ib = linspace(0,1,ppl);
    ib = ib(2:end)';
    
    ix=1;
    iL=1;
    
    while ix <= nx
        switch t(ix)
            case 0
                % start of new shape
                L(iL:iL+1,:) = [nan nan ; xy(ix,:)];
                iL = iL+1;
            case 1
                % line
                L(iL,:) = xy(ix,:);
            case 3
                % cubic bezier spline
                L(iL:iL+ppl-2,:) = bezier3( ib, xy(ix-1:ix+2,:) );
                iL = iL + ppl - 2;
                ix = ix + 2;
        end
        iL = iL+1;
        ix = ix+1;
    end

end

function B = bezier3( t, P )
    
    tinv = 1-t;

    B = 1 .* t.^0 .* tinv.^3 .* P(1,:) + ...
        3 .* t.^1 .* tinv.^2 .* P(2,:) + ...
        3 .* t.^2 .* tinv.^1 .* P(3,:) + ...
        1 .* t.^3 .* tinv.^0 .* P(4,:);

end

