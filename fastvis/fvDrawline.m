function l = fvDrawline(varargin)

[parent,args,temp] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('Closed',false);
p.KeepUnmatched = true;
p.parse(args{:});

isClosed = p.Results.Closed;

isfig = isa(parent,'fvFigure');
if isfig
    fvfig = parent;
else
    fvfig = parent.fvfig;
end

tf = fvfig.PopupMenuActive;
fvfig.PopupMenuActive = false;

if isfig
    h = fvhold(parent,'on');
end

m = fvMarker(parent);
l = fvLine(parent,[nan nan nan],'Clickable',false,'Color',[1 1 0],p.Unmatched);

if isfig
    fvhold(parent,h);
end

el1 = addlistener(fvfig,'MouseMoved',@mousehover);
el2 = addlistener(fvfig,'MouseClicked',@mouseclicked);

clear temp

waitfor(l,'Clickable',true);

delete([el1 el2]);

drawnow

if isvalid(fvfig)

    fvfig.PopupMenuActive = tf;

end


    function mousehover(src,evt)
        t = l.PauseUpdates;
        x = evt.data.xyz;
        x = mapply(x,parent.full_model,0);
        m.Model = MTrans3D(x);
        l.Coord(end,:) = x;
        clear t
    end

    function mouseclicked(src,evt)
        t = l.PauseUpdates;
        if evt.java.getButton == evt.java.BUTTON3
            l.Coord(end,:) = [];
            delete([el1 el2]);
            delete(m);
            l.Clickable = true;
        else
            l.Coord(end+1,:) = [nan nan nan];
        end
        c = l.Count;
        if c > 0 && isClosed
            l.Index = [(1:c) 1]';
        end
        clear t
    end

    

end