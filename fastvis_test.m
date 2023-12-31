
a = fvFigure;

a.Camera.Origin = [0 0 0];
a.Camera.Rotation = [-45 0 -45];
a.Camera.Translation = [0 0 -30];
fvhold on

wo = wobj('f16.obj');
[tri,xyz,texCoord,normals,materials,vertex_material] = wo.getDrawData;
m = fvMesh(tri,xyz,texCoord,normals,materials,vertex_material);
m.Rotate([90 0 0],1).Translate([0 0 5.5]);
m.Material(2).Alpha = 0.5;

p = fvPointcloud;
a.Model = MTrans3D(1) * MRot3D([10 10 10],1);
p.Translate([1 1 1]).Rotate([10 10 10],1);
fvText(p).Rotate([10 20 30],1).Translate([3 3 0]);
p.Colormap = pink;

line = fvLine('LineWidth',2);
line.Scale([1 1 3]);

im = fvImage();
im.Scale(2/max(im.ImageSize)).Rotate([45 0 0],1).Translate([1 0.5 6]);

fvText('TEST','TextSize',0,'Alpha',0.5,'Color',[1 0 0]).Translate([-2 -2 2]);

bb = fvBoundingBox(line,[]);

ind = bb.Extract(p);
p2 = fvPointcloud(p.Coord(ind,:)).Translate([-3 0 0]);
p2.PointUnit = 'world';
p2.PointSize = 0.05;
p2.MinPointSize = 3;
p2.PointShape = imresize([0 1 0 ; 1 1 1 ; 0 1 0],5,'nearest');

fvBoundingBox(a,p.worldBBox);
fvBoundingBox(p,[]);

a.ResetCamera;

