function xy = jevt2coords(evt,absFlag)
    if ~isjava(evt)
        evt = evt.java;
    end
    if absFlag
        xy = [evt.getXOnScreen evt.getYOnScreen];
    else
        xy = [evt.getX evt.getY];
    end
end