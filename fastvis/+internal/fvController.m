classdef fvController< glmu.GLController
%FVCONTROLLER

    properties
        fvfig
        figSize
        
        progs = struct
        screen

        MSframebuffer
        framebuffer
        
        clearFlag
        clearColor = {0 0 0};

        drawnPrimitives = {}
        lastViewParams
    end
    
    methods
        
        function InitFcn(obj,gl,ax,msaaSamples)
            msaaSamples = max(msaaSamples,1);
            
            obj.fvfig = ax;
            shdDir = execdir(fileparts(mfilename('fullpath')),'shaders');
            % obj.mesh = glmu.Program(fullfile(shdDir,'fvprim'));
            
            % MSAA render buffer setup
            MSTcol = glmu.Texture(0,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTcamDist = glmu.Texture(1,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTxyz = glmu.Texture(2,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSTid = glmu.Texture(3,gl.GL_TEXTURE_2D_MULTISAMPLE);
            MSrenderbuffer = glmu.Renderbuffer(gl.GL_DEPTH_COMPONENT16,msaaSamples);
            MSrenderbuffer.AddTexture(MSTcol,gl.GL_FLOAT,gl.GL_RGBA,gl.GL_RGBA16F);
            MSrenderbuffer.AddTexture(MSTcamDist,gl.GL_FLOAT,gl.GL_RG,gl.GL_RG32F);
            MSrenderbuffer.AddTexture(MSTxyz,gl.GL_FLOAT,gl.GL_RGB,gl.GL_RGB32F);
            MSrenderbuffer.AddTexture(MSTid,gl.GL_UNSIGNED_INT,gl.GL_RG_INTEGER,gl.GL_RG32UI);
            obj.MSframebuffer = glmu.Framebuffer(gl.GL_FRAMEBUFFER,MSrenderbuffer,gl.GL_DEPTH_ATTACHMENT);

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
            obj.screen.program.uniforms.msaa.Set(msaaSamples);
            obj.screen.uni.colorTex = MSTcol;
            obj.screen.uni.camDistTex = MSTcamDist;
            obj.screen.uni.xyzTex = MSTxyz;
            obj.screen.uni.idTex = MSTid;
            
            % clear flags setup
            obj.clearFlag = glmu.BitFlags('GL_COLOR_BUFFER_BIT','GL_DEPTH_BUFFER_BIT');
            gl.glClearColor(0,0,0,0);

            % enable primitive restart on max int element index
            gl.glEnable(gl.GL_PRIMITIVE_RESTART_FIXED_INDEX);

            % enable variable point size
            gl.glEnable(gl.GL_PROGRAM_POINT_SIZE);

        end
        
        function UpdateFcn(obj,gl)
            t = tic;
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


            [MProj,MView] = obj.fvfig.Camera.PrepareDraw;
            structfun(@(s) PrepareProgs(s,MProj,obj.fvfig.Camera.getCamPos),obj.progs);

            C = obj.fvfig.validateChilds('internal.fvDrawable');
            M = obj.fvfig.full_model;
            j = 0;
            drawnPrims = {};
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,MView,M,j,drawnPrims);
            end
            obj.drawnPrimitives = drawnPrims;
            obj.lastViewParams = obj.fvfig.Camera.viewParams;


            obj.framebuffer.DrawTo(1:3);

            gl.glColorMaski(2,1,1,1,1);
            gl.glColorMaski(3,1,1,1,1);

            gl.glDisable(gl.GL_DEPTH_TEST);
            
            gl.glClear(gl.GL_COLOR_BUFFER_BIT);

            gl.glEnable(gl.GL_CULL_FACE);
            gl.glFrontFace(gl.GL_CCW);

            obj.screen.program.uniforms.edlStrength.Set(obj.fvfig.edl);
            obj.screen.Draw;
            
            glmu.Blit(obj.framebuffer,0,gl.GL_COLOR_BUFFER_BIT,gl.GL_NEAREST,1,[0 0],obj.figSize)
            
            toc(t);
        end
        
        function ResizeFcn(obj,gl,sz)
            obj.figSize = sz;

            gl.glViewport(0,0,sz(1),sz(2));
            obj.fvfig.Camera.Resize(sz);
            obj.MSframebuffer.Resize(sz);
            obj.framebuffer.Resize(sz);
        end

        function [xyz,id] = glGetZone(obj,c,r)
            [gl,temp] = obj.canvas.getContext;

            w = 2*r+1; % square side length px
            
            s = obj.figSize';
            c(2) = s(2) - c(2);

            bid = javabuffer(zeros(2,w*w,'int32'));
            obj.framebuffer.ReadFrom(3);
            gl.glReadPixels(c(1)-r,c(2)-r,w,w,gl.GL_RG_INTEGER,gl.GL_INT,bid.p);

            id = bid.array';
            validId = id(:,1) > 0;
            
            if any(validId)
                bxyz = javabuffer(zeros(3,w*w,'single'));
                obj.framebuffer.ReadFrom(2);
                gl.glReadPixels(c(1)-r,c(2)-r,w,w,gl.GL_RGB,gl.GL_FLOAT,bxyz.p);

                xyz = bxyz.array';
                xyz(~validId,:) = nan;
            else
                xyz = nan(w*w,3);
            end
%             xyz
%             id
        end

        function prog = InitProg(obj,fullname)
            [~,name] = fileparts(fullname);
            if ~isfield(obj.progs,name)
                % shdDir = execdir(fileparts(mfilename('fullpath')),'shaders');
                obj.progs.(name) = glmu.Program(fullname);
            end
            prog = obj.progs.(name);
        end

        function s = id2info(obj,id)
            drawId = mod1(id(1),65535);
            s.object = obj.drawnPrimitives{drawId};
            elemId = floor((id(1)-1)/65535)+1;
            s.mtlId = [];
            if ~isempty(s.object.Material)
                id(2) = s.object.batch_mtl_idx{elemId}(id(2));
                s.mtlId = s.object.batch_mtl(elemId);
            end
            s.primId = id(2);
        end

        function [xyz,info] = coord2closest(obj,coord,radius)
            [xyzs,ids] = obj.glGetZone(coord,radius);

            v = obj.lastViewParams;
            if any(ids(:,1))
                [~,k] = max(xyzs(:,3));
                xyz = mapply(double(xyzs(k,:)),MTrans3D(v.T) * MRot3D(v.R,1,[1 3]),1) + v.O;
                id = ids(k,:);
                info = obj.id2info(id);
                info.xyz = xyz;
            else
                xyz = [nan nan nan];
                info = [];
            end
        end
    end
end

function PrepareProgs(prog,MProj,viewPos)
    prog.uniforms.projection.Set(MProj);
    prog.uniforms.viewPos.Set(viewPos);
end