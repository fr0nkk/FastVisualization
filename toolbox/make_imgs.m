
a = fvFigure;
a.Size = [300 250]

writesnap = @(imName) imwrite(a.Snapshot,imName);

M = MScale3D([1 1 0.5]);
pc = fvPointcloud('PointShape','round','PointUnit','world','PointSize',0.015,'MinPointSize',1.5,'Model',M);

a.Camera.Rotation(1) = -60;
a.Camera.Translation(3) = -15;
writesnap('pc1.jpg');

a.Camera.Origin = [-0.1 1.7 4];
a.Camera.Rotation = [-22 0 -230];
a.Camera.Translation = [0 0 -0.8];
writesnap('pc2.jpg');

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

fvclose(a);



