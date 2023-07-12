
a = fvFigure;

writesnap = @(imName) imwrite(a.Snapshot,imName);

M = MScale3D([1 1 0.5]);
pc = fvPointcloud('PointShape','round','PointUnit','world','PointSize',0.02,'MinPointSize',1.5,'Model',M);

a.Camera.viewParams.R(1) = -60;
a.Camera.viewParams.T(3) = -15;
writesnap('pc1.jpg');

pc.Color = [1 1 1];
a.Camera.viewParams.O = [-0.1 1.7 4];
a.Camera.viewParams.R = [-22 0 -230];
a.Camera.viewParams.T = [0 0 -0.8];
writesnap('pc2.jpg');

msh = fvMesh();

a.Camera.viewParams.O = [0.2165 0 1.5750];
a.Camera.viewParams.R = [-60 0 -150];
a.Camera.viewParams.T = [0 0 -9.5];
writesnap('msh1.jpg');

msh.Colormap = parula;
writesnap('msh2.jpg');

msh.Color = [0.8 0.8 0.8];
a.BackgroundColor = [1 1 1];
a.edlWithBackground = true;
writesnap('msh3.jpg');

msh.Normal = [];
a.edl = 0.3;
writesnap('msh4.jpg');

msh.Color = [1-rescale(msh.Coord(:,1)) rescale(msh.Coord(:,3))];
msh.AutoCalcNormals;
msh.Material = fvMaterial('peppers.png');
msh.Light.Ambient = [0.5 0.5 0.5];
writesnap('msh5.jpg');

msh.Alpha = 0.6;
writesnap('msh6.jpg');

fvclose(a);



