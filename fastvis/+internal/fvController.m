classdef fvController < glmu.GLController
%FVCONTROLLER

    properties
        fvfig
        
        progs = struct
        screen

        MSframebuffer
        framebuffer
        
        clearFlag
        clearColor = {0 0 0};

        drawnPrimitives = {}
        lastViewMatrix
    end
    
    methods
        
        function InitFcn(obj,gl,ax,msaaSamples)
            obj.fvfig = ax;
            shdDir = execdir(fileparts(mfilename('fullpath')),'shaders');

            % resolved render buffer setup
            Tcol = glmu.Texture(4,gl.GL_TEXTURE_2D);
            Txyz = glmu.Texture(5,gl.GL_TEXTURE_2D);
            Tid = glmu.Texture(6,gl.GL_TEXTURE_2D);
            renderbuffer = glmu.Renderbuffer(gl.GL_DEPTH_COMPONENT16);
            renderbuffer.AddTexture(Tcol,gl.GL_FLOAT,gl.GL_RGBA,gl.GL_RGBA16F);
            renderbuffer.AddTexture(Txyz,gl.GL_FLOAT,gl.GL_RGB,gl.GL_RGB32F);
            renderbuffer.AddTexture(Tid,gl.GL_UNSIGNED_INT,gl.GL_RG_INTEGER,gl.GL_RG32UI);
            obj.framebuffer = glmu.Framebuffer(gl.GL_FRAMEBUFFER,renderbuffer,gl.GL_DEPTH_ATTACHMENT);

            % blend setup
            gl.glEnable(gl.GL_BLEND);
            gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);
            gl.glBlendFunci(1,gl.GL_ONE, gl.GL_ZERO);
            gl.glBlendFunci(2,gl.GL_ONE, gl.GL_ZERO);

            % render screen setup
            quadVert = single([-1 -1 0 0; 1 -1 1 0;-1 1 0 1;  1 1 1 1]');
            obj.screen = glmu.drawable.Array(fullfile(shdDir,'pass1'),gl.GL_TRIANGLE_STRIP,quadVert);

            % MSAA render buffer setup
            obj.SetMSAA(msaaSamples);
            
            % clear flags setup
            obj.clearFlag = glmu.BitFlags('GL_COLOR_BUFFER_BIT','GL_DEPTH_BUFFER_BIT');
            gl.glClearColor(0,0,0,0);

            % enable primitive restart on max int element index
            gl.glEnable(gl.GL_PRIMITIVE_RESTART_FIXED_INDEX);

            % enable variable point size
            gl.glEnable(gl.GL_PROGRAM_POINT_SIZE);

            % gl.glEnable(gl.GL_FRAMEBUFFER_SRGB);

            gl.glPixelStorei(gl.GL_PACK_ALIGNMENT,1);

        end
        
        function UpdateFcn(obj,gl)
            obj.MSframebuffer.DrawTo(1:4);

            % clear everything
            gl.glEnable(gl.GL_DEPTH_TEST);
            gl.glClearColor(0,0,0,0);
            gl.glClear(obj.clearFlag);

            % bg color
            gl.glColorMaski(0,1,1,1,1);
            gl.glColorMaski(1,0,0,0,0);
            gl.glColorMaski(2,0,0,0,0);
            gl.glColorMaski(3,0,0,0,0);
            gl.glClearColor(obj.clearColor{:},0);
            gl.glClear(gl.GL_COLOR_BUFFER_BIT);
            gl.glColorMaski(1,1,1,1,1);
            gl.glColorMaski(2,1,1,1,1);
            gl.glColorMaski(3,1,1,1,1);

            C = obj.fvfig.validateChilds('internal.fvDrawable');
            M = obj.fvfig.Model;
            j = 0;
            drawnPrims = {};
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,M,j,drawnPrims);
            end
            obj.drawnPrimitives = drawnPrims;
            obj.lastViewMatrix = {obj.fvfig.Camera.MView M};

            obj.framebuffer.DrawTo(1:3);

            gl.glColorMaski(2,1,1,1,1);
            gl.glColorMaski(3,1,1,1,1);

            gl.glDisable(gl.GL_DEPTH_TEST);
            gl.glDepthRange(0,1);
            gl.glClear(gl.GL_COLOR_BUFFER_BIT);

            gl.glEnable(gl.GL_CULL_FACE);
            gl.glFrontFace(gl.GL_CCW);

            obj.screen.program.uniforms.edlStrength.Set(obj.fvfig.EDL);
            obj.screen.Draw;
            
            glmu.Blit(obj.framebuffer,0,gl.GL_COLOR_BUFFER_BIT,gl.GL_NEAREST,1,[0 0],obj.canvas.size)
        end
        
        function ResizeFcn(obj,gl,sz)
            gl.glViewport(0,0,sz(1),sz(2));
            obj.MSframebuffer.Resize(sz);
            obj.framebuffer.Resize(sz);
            obj.fvfig.ResizeCallback(sz);
        end

        function nSamples = SetMSAA(obj,nSamples)
            nSamples = max(nSamples,1);
            [gl,temp] = obj.canvas.getContext;
            maxSamples = glmu.Get(gl,@glGetIntegerv,gl.GL_MAX_SAMPLES,1,'int32');
            if nSamples > maxSamples
                nSamples = maxSamples;
                warning('MSAA has been clamped to GL_MAX_SAMPLES (%i)',maxSamples)
            end
            % MSAA render buffer setup
            MSTcol = glmu.Texture(0,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTcamDist = glmu.Texture(1,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTxyz = glmu.Texture(2,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTid = glmu.Texture(3,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSrenderbuffer = glmu.Renderbuffer(gl.GL_DEPTH_COMPONENT16,nSamples);
            MSrenderbuffer.AddTexture(MSTcol,gl.GL_FLOAT,gl.GL_RGBA,gl.GL_RGBA16F);
            MSrenderbuffer.AddTexture(MSTcamDist,gl.GL_FLOAT,gl.GL_RG,gl.GL_RG32F);
            MSrenderbuffer.AddTexture(MSTxyz,gl.GL_FLOAT,gl.GL_RGB,gl.GL_RGB32F);
            MSrenderbuffer.AddTexture(MSTid,gl.GL_UNSIGNED_INT,gl.GL_RG_INTEGER,gl.GL_RG32UI);
            obj.MSframebuffer = glmu.Framebuffer(gl.GL_FRAMEBUFFER,MSrenderbuffer,gl.GL_DEPTH_ATTACHMENT);

            obj.screen.program.uniforms.msaa.Set(nSamples);
            obj.screen.uni.colorTex = MSTcol;
            obj.screen.uni.camDistTex = MSTcamDist;
            obj.screen.uni.xyzTex = MSTxyz;
            obj.screen.uni.idTex = MSTid;
            obj.canvas.resizeNeeded = 1;
        end

        function data = glGetZone(obj,xy,whd,iTex,type,target)
            [gl,temp] = obj.canvas.getContext;
            b = javabuffer(zeros(whd([3 1 2]),type));

            utypes = {'','UNSIGNED_'};
            glType = gl.(['GL_' utypes{startsWith(b.matType,'u')+1} upper(b.javaType)]);

            obj.framebuffer.ReadFrom(iTex);
            target = obj.framebuffer.Const(target);
            gl.glReadPixels(xy(1),xy(2),whd(1),whd(2),target,glType,b.p);

            data = permute(b.array,[2 3 1]);
            data = rot90(data);
        end

        function [img,depth] = Snapshot(obj)
            sz = [obj.canvas.size 3];
            xy = [0 0];

            img = obj.glGetZone(xy,sz,1,'uint8','GL_RGB');
            depth = obj.glGetZone(xy,sz,2,'single','GL_RGB');

            if obj.fvfig.Camera.isPerspective
                depth = vecnorm(depth,2,3);
            else
                depth = depth(:,:,3);
            end
            depth(depth==0) = inf;
        end

        function prog = InitProg(obj,fullname)
            [~,name] = fileparts(fullname);
            if ~isfield(obj.progs,name)
                obj.progs.(name) = glmu.Program(fullname);
            end
            prog = obj.progs.(name);
        end

        function s = coord2closest(obj,coord,radius)

            w = 2.*radius+1; % square side length px
            
            coord(2) = obj.canvas.size(2) - coord(2);

            xy = coord-radius;
            sz = [w w];
            ids = obj.glGetZone(xy,[sz 2],3,'int32','GL_RG_INTEGER');
            validId = ids(:,:,1) > 0;

            x = [nan nan nan];
            s=struct('xyz',x,'xyz_gl',x,'xyz_view',x,'object',[],'info',struct);
            
            if ~any(validId,'all'), return, end

            xyzs = obj.glGetZone(xy,[sz 3],2,'single','GL_RGB');
            xyzs(repmat(~validId,1,1,3)) = nan;

            [~,k] = max(xyzs(:,:,3),[],'all');
            idx = k + prod(sz).*(0:2);

            s.xyz_view = double(xyzs(idx));
            s.xyz_gl = mapply(s.xyz_view,obj.lastViewMatrix{1},0);
            id = ids(idx(1:2));
            drawId = mod1(id(1),65535);
            o = obj.drawnPrimitives{drawId};
            elemId = floor((id(1)-1)/65535)+1;
            s.xyz = mapply(s.xyz_gl,obj.lastViewMatrix{2},0);
            s.object = o;
            s.info = o.id2info(elemId,id(2));
        end
    end
end

function x = unpack3(x)
    x = permute(x,[2 3 1]);
    x = rot90(x);
end
