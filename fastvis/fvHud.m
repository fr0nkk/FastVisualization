function h = fvHud()
fvclear
pc = fvPointcloud;
fvhold on
a = gcfv;

c = fvCamera;
c.viewParams.T = [0 0 -1/tand(c.projParams.F/2)];

xy = ([0 0 ; 0 1 ; 1 1 ; 1 0 ; 0 0]-0.5)./1.01+0.5;
h = fvLine(xy,[1 1 0],'Camera',c,'DepthRange',[0 0.1]);

ResizeHud(h);

addlistener(a.Camera,'Resized',@(src,evt) ResizeHud(h));

t = fvText(h,'Hud');
end

function ResizeHud(h)
sz = h.fvfig.Camera.projParams.size;
h.Camera.Resize(sz);
h.Model = MScale3D([sz./max(sz) 1]) * MTrans3D([-1 -1 0]) * MScale3D([2 2 1]);
end

