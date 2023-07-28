
a = fvFigure;
hold(a,'on');
a.Size = [300 250];
cam = a.Camera;

writesnap = @(imName) imwrite(a.Snapshot,[imName '.png']);

M = MScale3D([1 1 0.5]);
pc = fvPointcloud('PointShape','round','PointUnit','world','PointSize',0.015,'MinPointSize',1.5,'Model',M);

cam.Origin = [0 0 0];
cam.Rotation = [-60 0 -45];
cam.Translation = [0 0 -15];
writesnap('pc1');

cam.Origin = [-0.1 1.7 4];
cam.Rotation = [-22 0 -230];
cam.Translation = [0 0 -0.8];
writesnap('pc2');

delete(pc)

msh = fvMesh();

cam.Origin = [0.2165 0 1.5750];
cam.Rotation = [-60 0 -150];
cam.Translation = [0 0 -9.5];
writesnap('msh1');

msh.Colormap = jet;
writesnap('msh2');

msh.Color = [0.8 0.8 0.8];
a.BackgroundColor = [1 1 1];
a.EDLWithBackground = true;
writesnap('msh3');

msh.Normal = [];
a.EDL = 0.3;
writesnap('msh4');

msh.Color = [1-rescale(msh.Coord(:,1)) rescale(msh.Coord(:,3))];
msh.AutoCalcNormals;
msh.Material = fvMaterial('peppers.png');
msh.Light.Ambient = [0.5 0.5 0.5];
writesnap('msh5');

msh.Alpha = 0.6;
writesnap('msh6');

delete(msh)

srf = fvSurf('Colormap','pink');
a.BackgroundColor = [1 1 1];
a.EDLWithBackground = true;
cam.Origin = [60 55 10];
cam.Rotation = [-75 0 45];
cam.Translation = [11 -18 -350];
writesnap('srf1');

delete(srf)

lin = fvLine('LineWidth',2,'Colormap','cool');
a.BackgroundColor = [0 0 0];
cam.Origin = [0 0 0.7];
cam.Rotation = [-67 0 -40];
cam.Translation = [0 0 -4];
writesnap('lin1');

delete(lin)

txt = fvText('Fast Visualization!','ConstantSize',0);
txt.Color = rescale(txt.Coord(:,1));
txt.Colormap = jet;
a.BackgroundColor = [1 1 1];
a.EDLWithBackground = true;
a.CameraConstraints = '3D';

[p,tri] = cubemesh;
cub = fvMesh(txt,tri,p,[0.75 0.75 0.75],'AutoCalcNormals',false);
cub.Model = MTrans3D([-0.2 0 -1.1]) * MScale3D([7.5 1 1]);

cam.Origin = [4 0 -0.5];
cam.Rotation = [-41 0 28];
cam.Translation = [1 0 -10];

writesnap('txt1');

delete(txt)

im = fvImage;
cam.Origin = [0 0 0];
cam.Rotation = [0 0 0];
cam.Translation = [-fliplr(im.ImageSize)./2 -700];

writesnap('im1');

fvclose(a);



