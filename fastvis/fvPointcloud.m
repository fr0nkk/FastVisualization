function fv = fvPointcloud(varargin)

[ax,args,t] = internal.fvParse(varargin{:});

p = inputParser;
p.addOptional('xyz',nan);
p.addOptional('col',[]);
p.addOptional('ind',[]);
p.KeepUnmatched = true;
p.parse(args{:});

xyz = p.Results.xyz;
col = p.Results.col;
if isscalar(xyz) && isnan(xyz)
    [X,Y,Z] = peaks(200);
    xyz = [X(:) Y(:) Z(:)];
    s = struct('X',X(:),'Y',Y(:),'Z',Z(:));
    col = fvColor(s,'Current','Z');
    % if isempty(col)
        % col = rescale(xyz(:,3));
    % end
end

fv = internal.fvPrimitive(ax,'GL_POINTS',xyz,col,[],[],[],[],'Name','fvPointcloud',p.Unmatched);

end

% classdef fvPointcloud < internal.fvPrimitive
% %FVPOINTCLOUD view a pointcloud in fast vis
% % fvPointcloud(xyz,color,indices,'Property',Value,...)
% 
%     properties(Transient,SetObservable)
% 
%         % PointSize - Size of the points, in world units
%         % A size of 0 default to MinPointSize (in pixels)
%         PointSize (1,1) double {mustBeFinite, mustBeNonnegative} = 0
% 
%         % MinPointSize - Minimum size of points, in pixels
%         MinPointSize = 2;
% 
%         % PointShape - Shape of the drawn points
%         % valid values are 'square', 'round', or an alpha matrix [m x n]
%         % for custom shapes
%         PointShape = 'square'
%     end
% 
%     methods
%         function obj = fvPointcloud(varargin)
%             [ax,args,t] = internal.fvParse(varargin{:});
% 
%             p = inputParser;
%             p.addOptional('xyz',nan);
%             p.addOptional('col',[]);
%             p.addOptional('ind',[]);
%             p.KeepUnmatched = true;
%             p.parse(args{:});
% 
%             xyz = p.Results.xyz;
%             col = p.Results.col;
%             if isscalar(xyz) && isnan(xyz)
%                 [X,Y,Z] = peaks(200);
%                 xyz = [X(:) Y(:) Z(:)];
%                 s = struct('X',X(:),'Y',Y(:),'Z',Z(:));
%                 col = fvColor(s,'Current','Z');
%                 % if isempty(col)
%                     % col = rescale(xyz(:,3));
%                 % end
%             end
% 
%             obj@internal.fvPrimitive(ax,'GL_POINTS',xyz,col,[],[],[],[],'Name','fvPointcloud',p.Unmatched);
%         end
% 
%         function set.PointSize(obj,v)
%             obj.PointSize = v;
%             obj.Update;
%         end
% 
%         function set.MinPointSize(obj,v)
%             obj.MinPointSize = v;
%             obj.Update;
%         end
% 
%         function set.PointShape(obj,val)
%             if isscalartext(val)
%                 switch val
%                     case 'square'
%                         pointMask = 0;
%                     case 'round'
%                         pointMask = 1;
%                     otherwise
%                         error('invalid value: %s',val)
%                 end
%             else
%                 [gl,temp] = obj.getContext;
%                 if isinteger(val)
%                     val = single(val)./single(intmax(class(val)));
%                 elseif islogical(val)
%                     val = single(val);
%                 end
%                 if size(val,3) > 1
%                     val = mean(val,3);
%                 end
%                 tex = glmu.Texture(7,'GL_TEXTURE_2D',flipud(val),'GL_RED',1);
%                 obj.glDrawable.uni.pointMask_tex = tex;
%                 pointMask = 2;
%             end
%             obj.glDrawable.uni.pointMask = pointMask;
%             obj.PointShape = val;
%             obj.Update;
%         end
%     end
% 
%     methods(Access=protected)
%         function DrawFcn(obj,varargin)
%             u = obj.glDrawable.program.uniforms;
% 
%             u.pointSize.Set(obj.PointSize);
%             u.minPointSize.Set(obj.MinPointSize);
% 
%             obj.DrawFcn@internal.fvPrimitive(varargin{:});
%         end
%     end
% end
