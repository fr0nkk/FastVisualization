
a = fvFigure;
hold(a,'on');
a.Size = [300 250];

writesnap = @(imName) imwrite(a.Snapshot,imName);

M = MScale3D([1 1 0.5]);
pc = fvPointcloud('PointShape','round','PointUnit','world','PointSize',0.015,'MinPointSize',1.5,'Model',M);

a.Camera.Origin = [0 0 0];
a.Camera.Rotation = [-60 0 -45];
a.Camera.Translation = [0 0 -15];
writesnap('pc1.jpg');

a.Camera.Origin = [-0.1 1.7 4];
a.Camera.Rotation = [-22 0 -230];
a.Camera.Translation = [0 0 -0.8];
writesnap('pc2.jpg');

delete(pc)

msh = fvMesh();

a.Camera.Origin = [0.2165 0 1.5750];
a.Camera.Rotation = [-60 0 -150];
a.Camera.Translation = [0 0 -9.5];
writesnap('msh1.jpg');

msh.Colormap = jet;
writesnap('msh2.jpg');

msh.Color = [0.8 0.8 0.8];
a.BackgroundColor = [1 1 1];
a.EDLWithBackground = true;
writesnap('msh3.jpg');

msh.Normal = [];
a.EDL = 0.3;
writesnap('msh4.jpg');

msh.Color = [1-rescale(msh.Coord(:,1)) rescale(msh.Coord(:,3))];
msh.AutoCalcNormals;
msh.Material = fvMaterial('peppers.png');
msh.Light.Ambient = [0.5 0.5 0.5];
writesnap('msh5.jpg');

msh.Alpha = 0.6;
writesnap('msh6.jpg');

delete(msh)

srf = fvSurf('Colormap','pink');
a.BackgroundColor = [1 1 1];
a.EDLWithBackground = true;
a.Camera.Origin = [60 55 10];
a.Camera.Rotation = [-75 0 45];
a.Camera.Translation = [11 -18 -350];
writesnap('srf1.jpg');

delete(srf)

lin = fvLine('LineWidth',2,'Colormap','cool');
a.BackgroundColor = [0 0 0];
a.Camera.Origin = [0 6.2305e-05 0.7854];
a.Camera.Rotation = [-67.4000 0 -49.6000];
a.Camera.Translation = [0 0.0884 -3.9999];
writesnap('lin1.jpg');

delete(lin)

% txt3D = fvText('Fast Visualization!','ConstantSize',0);
% txt3D.Color = rescale(txt3D.Coord(:,1))
%%
fvclose(a);



