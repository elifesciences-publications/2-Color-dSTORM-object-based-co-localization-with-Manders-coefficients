function mandalyserGUI_beta
%% this is a working version of a program for the image-based segmentation of
% superresolved image and colocalization analysis based on Manders
% coefficients, ripleys function and nearest neighbour distance function
% this program will be shortly compleated
 
% set your screen size units as pixel
set(0,'units','pixels')
% get the screen size
Pix_SS = get(0,'screensize');
if ~ismac
    flagslash = '\';
else
    flagslash = '/';
end
% set the position and size of your figure
width = floor(7*Pix_SS(3)/8);
height = floor(width*Pix_SS(4)/Pix_SS(3));
left = floor((Pix_SS(3)-width)/2);
bottom = floor((Pix_SS(4)-height)/2);

%  Create and then hide the UI as it is being constructed.
f = figure('Visible','on','Position',[left bottom floor(3*width/4) height],'Menubar','none');%,'Toolbar','none',...
%               'Menubar','none');

movegui(f,'center');
left_ha = 70;
bottom_ha = 70;
width_ha = floor((width - left_ha)/2);
height_ha = width_ha;
pbw = 65; pbh = 15;pbs = 7;
%% image axes
s_ha = [left_ha,bottom_ha,width_ha,height_ha];
ha = axes('Parent', f,'Units','pixels','Position',s_ha);
set(ha, 'XTick', [], 'YTick', []);
%%
global imRGB
imRGB = [];

zcount = 0;
totalMask1 = [];
flagmask = 0;
pos0 = []; 
hrect = [];
im2 = [];
flagalign = 0; 
updowncount = [0,0];
leftrightcount = [0,0];
im1 = [];
imax2 = 0; 
imax1 = 0;
pathBGR = [];
fileBGR = [];
visu1 = 0;

%% intensity sliders
% Construct the components;pushbottoms; sliders etc
s_slider1 = [left_ha,floor(bottom_ha/2),width_ha,floor(bottom_ha/6)];
planeslider = uicontrol('Style','slider','Position',...
    s_slider1,'Tag','slider1','Min',1,'Max',2,'Value',1,'SliderStep',[1,1]);

% image sliders for grayscale image
s_slider2 = [floor(left_ha/2),bottom_ha,floor(left_ha/5),height_ha];
imagesliderMax = uicontrol('Style','slider','Position',s_slider2,...
    'Tag','slider2','Callback',@imagesliderMax_Callback);

s_slider3 = [floor(left_ha/2)-floor(left_ha/5),bottom_ha,floor(left_ha/5),height_ha];
imagesliderMin = uicontrol('Style','slider','Position',s_slider3,...
    'Tag','slider3','Callback',@imagesliderMin_Callback);

s_textmin1 = [s_slider3(1),s_slider3(2) - pbh - pbs, pbw pbh];             
textmin1 = uicontrol('Style','edit',...
                'String','0',...
                'Position',s_textmin1);
            
s_textmin2 = [s_textmin1(1),s_slider3(2)+s_slider3(4) + pbs, pbw pbh];             
textmax2 = uicontrol('Style','edit',...
                'String','0',...
                'Position',s_textmin2);
%% disply rgb image
function displyrgbimage(~,~)
    cla(ha,'reset')
    imagesliderMax.Min = 0;
    imagesliderMax.Max = 2^bd;
    imagesliderMax.Value = 2^bd;
    imagesliderMax.SliderStep = [1,1] /  (imagesliderMax.Max - imagesliderMax.Min);
     imagesc(imRGB,'Parent',ha);
    imagesliderMin.Min = 0;
    imagesliderMin.Max = 2^bd;
    imagesliderMin.Value = 0;
    imagesliderMin.SliderStep = [1,1] / (imagesliderMin.Max - imagesliderMin.Min);
    imax1 = max(max(imRGB(:,:,1)));
    imax2 = max(max(imRGB(:,:,2)));
    planeslider.Min = 1;
    planeslider.Max = 2;
    planeslider.Value = 1;
    planeslider.SliderStep = [1, 1];
    maxI1 = imax1;
    maxI2 = imax2;
    minI1 = 0;
    minI2 = 0;
    textmax2.String = num2str(floor(2^bd));
end
%% load 2 color image
hrgb = [];
img1 = [];
img2 = [];
bd = [];
s_loadimage1 = [left_ha,2*bottom_ha+height_ha-floor(bottom_ha/2)-floor(bottom_ha/6),pbw,pbh];
uicontrol('Style','pushbutton','String','Load image',...
           'Tag','loadimage1','Position',s_loadimage1,...
           'Callback',@loadimage1_Callback);
function loadimage1_Callback(hObject,eventdata)
    [fileBGR,pathBGR] = uigetfile('*.tif*','Select 2 color storm image...');
    img1 = imread(strcat(pathBGR,flagslash,fileBGR), 1);
    img2 = imread(strcat(pathBGR,flagslash,fileBGR), 2);
    bd1 = nextpow2(max(max(img1)));
    bd2 = nextpow2(max(max(img2)));
    bd = max(bd1,bd2);
    clear imRGB;
    imax1 = max(max(img1));
    imax2 = max(max(img2));
    im1 = img1*(2^bd/imax1);
    im2 = img2*(2^bd/imax2);
    imRGB(:,:,1) = im1;
    imRGB(:,:,2) = im2;
    imRGB(:,:,3) = zeros(size(im1));
    visu1 = 1;
    displyrgbimage
    disp('Loading finished: BGR image')
end
%% zoom button
s_zoom = s_loadimage1 + [pbw+pbs 0 0 0];            

uicontrol( ...
    'Style', 'togglebutton', ...
    'Position', s_zoom, ...
    'String', 'Toggle Zoom', ...
    'Callback', {@myzoombutton,ha} ... % Pass along the handle structure as well as the default source and eventdata values
    ); 
function myzoombutton(source, ~,ha)

togglestate = source.Value;

switch togglestate
    case 1
        % Toggle on, turn on zoom
        zoom(ha, 'on')
    case 0
        % Toggle off, turn off zoom
        zoom(ha, 'off')
end
end
%% pixel size
s_stpixelsize = s_zoom + [pbw+pbs 0 0 0];   
uicontrol('Style','text',...
                'String','Pixel size',...
                'Position',s_stpixelsize);
s_tpixelsize = s_stpixelsize + [pbw+pbs 0 0 0];   
tpixelsize = uicontrol('Style','edit',...
                'String','160',...
                'Position',s_tpixelsize);
%% close all but not gui
s_closeall = s_tpixelsize + [pbw+pbs 0 0 0];            
uicontrol('Style','pushbutton','String','Close all',...
          'Position',s_closeall,...
           'Callback',@closeall_Callback); 
function closeall_Callback(hObject,eventdata)
set(f, 'HandleVisibility', 'off');
close all;
set(f, 'HandleVisibility', 'on');
end  
%% reslice
s_reslice = s_closeall + [pbw+pbs 0 0 0];            
uicontrol('Style','pushbutton','String','Swap chanels',...
          'Position',s_reslice,...
           'Callback',@reslice_Callback); 
function reslice_Callback(~,~)
if visu1
    imRGB = imRGB(:,:,[2,1,3]);
    imagesliderMin_Callback  
end
end 
%% save image %displyrgbimage
s_saveimage = s_reslice + [pbw+pbs 0 0 0];            
uicontrol('Style','pushbutton','String','Save image',...
          'Position',s_saveimage,...
           'Callback',@saveimage_Callback); 
function saveimage_Callback(~,~)
if visu1
    uisave({'imRGB','img1','img2'},'imRGB_.mat')
end
end 
%% load mat rgb %
s_loadmat = s_saveimage + [pbw+pbs 0 0 0];            
uicontrol('Style','pushbutton','String','Load mat',...
          'Position',s_loadmat,...
           'Callback',@loadmatimage_Callback); 
function loadmatimage_Callback(~,~)
 [filename,path] = uigetfile('*.mat*','Load mat RGB image...');
tmp = load(strcat(path,flagslash,filename),'imRGB','img1','img2');
imRGB = tmp.imRGB;   
img1 = tmp.img1;   
img2 = tmp.img2;   
    displyrgbimage
end 
%% intensity slider
maxI1 = 0;
maxI2 = 0;
minI1 = 0;
minI2 = 0;
function imagesliderMax_Callback(~,~)
if visu1 == 1
plane = planeslider.Value;
cla(ha,'reset')
     minVal1 = imagesliderMin.Value;
     maxVal1 = imagesliderMax.Value;
     textmax2.String = num2str(floor(maxVal1));
     J = imRGB;
if plane == 1
     maxI1 = maxVal1;
     minI1 = minVal1;
     a = J(:,:,1);
     a(a <= minI1) = 0;
     a(a >= maxI1) = 2^bd;
     J(:,:,1) = a;  
      a = J(:,:,2);
     a(a <= minI2) = 0;
     a(a >= maxI2) = 2^bd;
     J(:,:,2) = a;
elseif plane == 2
     maxI2 = maxVal1;
     minI2 = minVal1;
     a = J(:,:,1);
     a(a <= minI1) = 0;
     a(a >= maxI1) = 2^bd;
     J(:,:,1) = a;  
      a = J(:,:,2);
     a(a <= minI2) = 0;
     a(a >= maxI2) = 2^bd;
     J(:,:,2) = a;
end
        imagesc(J,'Parent',ha);
        set(ha,'xtick',[])
        set(ha,'ytick',[])
        axis tight
end
end

function imagesliderMin_Callback(~,~)
if visu1 == 1
plane = planeslider.Value;
cla(ha,'reset')
     minVal1 = imagesliderMin.Value;
     maxVal1 = imagesliderMax.Value;
     textmin1.String = num2str(floor(minVal1));
     J = imRGB;
if plane == 1
     maxI1 = maxVal1;
     minI1 = minVal1;
  a = J(:,:,1);
     a(a <= minI1) = 0;
     a(a >= maxI1) = 2^bd;
     J(:,:,1) = a;  
      a = J(:,:,2);
     a(a <= minI2) = 0;
     a(a >= maxI2) = 2^bd;
     J(:,:,2) = a;
elseif plane == 2
     maxI2 = maxVal1;
     minI2 = minVal1;
  a = J(:,:,1);
     a(a <= minI1) = 0;
     a(a >= maxI1) = 2^bd;
     J(:,:,1) = a;  
      a = J(:,:,2);
     a(a <= minI2) = 0;
     a(a >= maxI2) = 2^bd;
     J(:,:,2) = a;
end
       imagesc(J,'Parent',ha);
        set(ha,'xtick',[])
        set(ha,'ytick',[])
        axis tight
end
end
%% align image
a_stalign = [s_ha(1) + s_ha(3) + pbs, s_ha(2) + s_ha(4) + pbh,pbw, pbh ]; 
uicontrol('Style','text',...
                'String','Align chanels',...
                'Position',a_stalign);
s_ststep = a_stalign - [0 pbh + pbs 0 0];
uicontrol('Style','text',...
                'String','Step',...
                'Position',s_ststep);
s_tstep = s_ststep - [0 pbh + pbs 0 0];
tstep = uicontrol('Style','edit',...
                'String','1',...
                'Position',s_tstep);
            % aligning images
s_pushup = s_tstep - [0 pbh + pbs 0 0];            
uicontrol('Style','pushbutton','String','UP',...
           'Tag','pushup','Position',s_pushup,...
           'Callback',@pushup_Callback);
s_pushdown = s_pushup - [0 s_pushup(4) + pbs 0 0];            
uicontrol('Style','pushbutton','String','DOWN',...
           'Tag','pushdown','Position',s_pushdown,...
           'Callback',@pushdown_Callback);
s_pushleft = s_pushdown - [0 s_pushdown(4) + pbs 0 0];            
uicontrol('Style','pushbutton','String','LEFT',...
           'Tag','pushleft','Position',s_pushleft,...
           'Callback',@pushleft_Callback);
s_pushright = s_pushleft - [0 s_pushleft(4) + pbs 0 0];            
uicontrol('Style','pushbutton','String','RIGHT',...
           'Tag','pushright','Position',s_pushright,...
           'Callback',@pushright_Callback);
s_pushresetX = s_pushright - [0 s_pushright(4) + pbs 0 0];            
uicontrol('Style','pushbutton','String','RESET x',...
           'Tag','pushresetX','Position',s_pushresetX,...
           'Callback',@pushresetX_Callback); 
       
s_pushresetY = s_pushresetX - [0 pbh + pbs 0 0];            
uicontrol('Style','pushbutton','String','RESET Y',...
           'Tag','pushrightY','Position',s_pushresetY,...
           'Callback',@pushresetY_Callback); 
s_pushresetALL = s_pushresetY - [0 pbh + pbs 0 0];            
uicontrol('Style','pushbutton','String','RESET ALL',...
           'Tag','pushrightALL','Position',s_pushresetALL,...
           'Callback',@pushresetALL_Callback);  
s_savealign = s_pushresetALL - [0 pbh + pbs 0 0];            
uicontrol('Style','pushbutton','String','Save align',...
           'Tag','savealign','Position',s_savealign,...
           'Callback',@savealign_Callback);   
s_loadalign = s_savealign - [0 s_savealign(4) + pbs 0 0];            
uicontrol('Style','pushbutton','String','Load align',...
           'Tag','loadalign','Position',s_loadalign,...
           'Callback',@loadalign_Callback); 
%%
function pushup_Callback(~,~)
    step = -eval(tstep.String);
    plane = planeslider.Value;
    if ~flagalign
       flagalign = 1;
    end  
    if plane == 1
        imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[0,step],'FillValues',0);
        updowncount(1) = updowncount(1) + step;
    elseif plane == 2
        imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[0,step],'FillValues',0);
        updowncount(2) = updowncount(2) + step;
    end  
       cla(ha,'reset')
       imagesliderMin_Callback
end
%down
function pushdown_Callback(~,~)
    step = eval(tstep.String);
    plane = planeslider.Value;
    if ~flagalign
       flagalign = 1;
    end  
    if plane == 1
        imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[0,step],'FillValues',0);
        updowncount(1) = updowncount(1) + step;
    elseif plane == 2
        imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[0,step],'FillValues',0);
        updowncount(2) = updowncount(2) + step;
    end  
       cla(ha,'reset')
       imagesliderMin_Callback
end
% left
function pushleft_Callback(~,~)
   step = -eval(tstep.String);
    plane = planeslider.Value;
    if ~flagalign
       flagalign = 1;
    end  
    if plane == 1
        imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[step, 0],'FillValues',0);
        leftrightcount(1) = leftrightcount(1) + step;
    elseif plane == 2
        imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[step, 0],'FillValues',0);
        leftrightcount(2) = leftrightcount(2) + step;
    end  
       cla(ha,'reset')
       imagesliderMin_Callback
end
% right
function pushright_Callback(~,~)
    step = eval(tstep.String);
    plane = planeslider.Value;
    if ~flagalign
       flagalign = 1;
    end  
    if plane == 1
        imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[step, 0],'FillValues',0);
        leftrightcount(1) = leftrightcount(1) + step;
    elseif plane == 2
        imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[step, 0],'FillValues',0);
        leftrightcount(2) = leftrightcount(2) + step;
    end  
       cla(ha,'reset')
       imagesliderMin_Callback
end
% reset
function pushresetX_Callback(~,~)

imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[-leftrightcount(1), 0],'FillValues',0);
imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[-leftrightcount(2), 0],'FillValues',0);

cla(ha,'reset')
imagesliderMin_Callback
leftrightcount = [0,0];
disp('Reset X') 
end
function pushresetY_Callback(~,~)
imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[0,-updowncount(1)],'FillValues',0);
imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[0,-updowncount(2)],'FillValues',0);

cla(ha,'reset')
imagesliderMin_Callback
leftrightcount = [0,0];
disp('Reset Y') 
end

function pushresetALL_Callback(~,~)
imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[-leftrightcount(1), 0],'FillValues',0);
imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[-leftrightcount(2), 0],'FillValues',0);
imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[0,-updowncount(1)],'FillValues',0);
imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[0,-updowncount(2)],'FillValues',0);
cla(ha,'reset')
imagesliderMin_Callback
flagalign = 0; 
updowncount = [0,0];
leftrightcount = [0,0];
disp('Reset all') 
end
% save align     
function savealign_Callback(~,~)
    if flagalign
        filenamesavealign = strcat(pathBGR,flagslash,fileBGR(1:end-4),'_aligned.mat');
        uisave({'leftrightcount','updowncount'},filenamesavealign) 
    disp('Saveing finished')
    end
end
% load align
function loadalign_Callback(hObject,eventdata)
[filename,path] = uigetfile('*.mat*','Select file with aligned data...');
tmp = load(strcat(path,flagslash,filename),'leftrightcount','updowncount');
leftrightcount = tmp.leftrightcount;
updowncount = tmp.updowncount;
flagalign = 1;
disp('Loading align finished')
if visu1
    imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[leftrightcount(1), 0],'FillValues',0);
    imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[leftrightcount(2), 0],'FillValues',0);
    imRGB(:,:,1) = imtranslate(imRGB(:,:,1),[0,updowncount(1)],'FillValues',0);
    imRGB(:,:,2) = imtranslate(imRGB(:,:,2),[0,updowncount(2)],'FillValues',0);
    cla(ha,'reset')
    imagesliderMin_Callback
end
end
%% 
a_ssegmentation = [s_ha(1) + s_ha(3) + pbs + 3*pbw s_ha(2) + s_ha(4) + pbh pbw+pbs  pbh]; 
uicontrol('Style','text',...
                'String','Segmentation',...
                'Position',a_ssegmentation);
s_stchanel1 = a_ssegmentation - [pbw/2 pbh + pbs pbs 0];
uicontrol('Style','text',...
                'String','CH1',...
                'Position',s_stchanel1);
s_stchanel2 = s_stchanel1 + [pbw+pbs 0 0 0];
uicontrol('Style','text',...
                'String','CH2',...
                'Position',s_stchanel2);
% min I
s_stminI = s_stchanel1 - [pbw+pbs pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','min I',...
                'Position',s_stminI);
s_tminI1 = s_stchanel1 - [0 pbh+pbs 0 0];
tminI1=uicontrol('Style','edit',...
                'String','10',...
                'Position',s_tminI1);
 s_tminI2 = s_stchanel2 - [0 pbh+pbs 0 0];
tminI2=uicontrol('Style','edit',...
                'String','10',...
                'Position',s_tminI2);
            
% max I
s_stmaxI = s_stminI - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','max I',...
                'Position',s_stmaxI);
s_tmaxI1 = s_tminI1 - [0 pbh+pbs 0 0];
tmaxI1=uicontrol('Style','edit',...
                'String','10000',...
                'Position',s_tmaxI1);
 s_tmaxI2 = s_tminI2 - [0 pbh+pbs 0 0];
tmaxI2=uicontrol('Style','edit',...
                'String','10000',...
                'Position',s_tmaxI2);
            
% watershed
s_stwatershed = s_stmaxI - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','Watershed',...
                'Position',s_stwatershed);
s_twatershed1 = s_tmaxI1 - [0 pbh+pbs 0 0];
twatershed1=uicontrol('Style','edit',...
                'String','15',...
                'Position',s_twatershed1);
 s_twatershed2 = s_tmaxI2 - [0 pbh+pbs 0 0];
twatershed2=uicontrol('Style','edit',...
                'String','15',...
                'Position',s_twatershed2);
% gaussian kernel
s_stgaussiankernel = s_stwatershed - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','Kernel size',...
                'Position',s_stgaussiankernel);
s_tgaussiankernel1 = s_twatershed1 - [0 pbh+pbs 0 0];
tgaussiankernel1=uicontrol('Style','edit',...
                'String','0.25',...
                'Position',s_tgaussiankernel1);
 s_tgaussiankernel2 = s_twatershed2 - [0 pbh+pbs 0 0];
tgaussiankernel2=uicontrol('Style','edit',...
                'String','0.25',...
                'Position',s_tgaussiankernel2);
% object analysis
s_stobjectanalysis = s_stgaussiankernel + [pbw+pbs -pbh-2*pbs + pbs pbw 0];
uicontrol('Style','text',...
                'String','Object analysis',...
                'Position',s_stobjectanalysis);
s_stmina = s_stobjectanalysis - [pbw+pbs 2*pbs + pbs pbw 0];
uicontrol('Style','text',...
                'String','min A',...
                'Position',s_stmina);
s_tmina1 = s_stmina + [pbw+pbs 0 0 0];
tmina1=uicontrol('Style','edit',...
                'String','5',...
                'Position',s_tmina1);
 s_tmina2 = s_tmina1  + [pbw+pbs 0 0 0];
tmina2=uicontrol('Style','edit',...
                'String','20',...
                'Position',s_tmina2);
s_stmaxa = s_stmina - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','max A',...
                'Position',s_stmaxa);
s_tmaxa1 = s_stmaxa + [pbw+pbs 0 0 0];
tmaxa1=uicontrol('Style','edit',...
                'String','2000',...
                'Position',s_tmaxa1);
 s_tmaxa2 = s_tmaxa1  + [pbw+pbs 0 0 0];
tmaxa2=uicontrol('Style','edit',...
                'String','2000',...
                'Position',s_tmaxa2);
% object I min            
s_stminoI = s_stmaxa - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','min I',...
                'Position',s_stminoI);
s_tminoI1 = s_stminoI + [pbw+pbs 0 0 0];
tminoI1=uicontrol('Style','edit',...
                'String','25',...
                'Position',s_tminoI1);
 s_tminoI2 = s_tminoI1  + [pbw+pbs 0 0 0];
tminoI2=uicontrol('Style','edit',...
                'String','50',...
                'Position',s_tminoI2);
% object I max            
s_stmaxoI = s_stminoI - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','max I',...
                'Position',s_stmaxoI);
s_tmaxoI1 = s_stmaxoI + [pbw+pbs 0 0 0];
tmaxoI1=uicontrol('Style','edit',...
                'String','20000',...
                'Position',s_tmaxoI1);
 s_tmaxoI2 = s_tmaxoI1  + [pbw+pbs 0 0 0];
tmaxoI2=uicontrol('Style','edit',...
                'String','20000',...
                'Position',s_tmaxoI2);
% coloc
s_stcoloc = s_stmaxoI + [pbw+pbs -pbh-2*pbs + pbs pbw 0];
uicontrol('Style','text',...
                'String','Colocalization',...
                'Position',s_stcoloc);
s_stmindist = s_stcoloc - [pbw+pbs 2*pbs + pbs pbw 0];
uicontrol('Style','text',...
                'String','min Dist',...
                'Position',s_stmindist);
s_tmindist = s_stmindist + [pbw+pbs 0 0 0];
tmindist=uicontrol('Style','edit',...
                'String','100',...
                'Position',s_tmindist);
% connectivity
s_stconnectivity = s_stmindist - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','Connectivity',...
                'Position',s_stconnectivity);
            
s_tconnectivity = s_stconnectivity + [pbw+pbs 0 0 0];
tconnectivity=uicontrol('Style','edit',...
                'String','4',...
                'Position',s_tconnectivity);
% eccentricity
s_steccentricitys = s_stconnectivity - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','Ecc. small',...
                'Position',s_steccentricitys);
            
s_teccentricitys1 = s_steccentricitys + [pbw+pbs 0 0 0];
teccentricitys1=uicontrol('Style','edit',...
                'String','0.2',...
                'Position',s_teccentricitys1);
s_teccentricitys2 = s_teccentricitys1 + [pbw+pbs 0 0 0];
teccentricitys2=uicontrol('Style','edit',...
                'String','0.2',...
                'Position',s_teccentricitys2);
            
s_steccentricityl = s_steccentricitys - [0 pbh+pbs 0 0];
uicontrol('Style','text',...
                'String','Ecc. latge',...
                'Position',s_steccentricityl);
            
s_teccentricityl = s_steccentricityl + [pbw+pbs 0 0 0];
teccentricityl1=uicontrol('Style','edit',...
                'String','0.2',...
                'Position',s_teccentricityl);
s_teccentricityl2 = s_teccentricityl + [pbw+pbs 0 0 0];
teccentricityl2=uicontrol('Style','edit',...
                'String','0.2',...
                'Position',s_teccentricityl2);
%% segment
s_segment = s_teccentricityl - [0 pbh+pbs 0 0];            
uicontrol('Style','pushbutton','String','Segment',...
          'Position',s_segment,...
           'Callback',@segmentimage_Callback); 
reg1=[];
reg2 = [];
function segmentimage_Callback(~,~)
im1 = double(imRGB(:,:,1)); 
im2 = double(imRGB(:,:,2)); 
im2 = imgaussfilt(im2,eval(tgaussiankernel2.String));
im1 = imgaussfilt(im1,eval(tgaussiankernel1.String));
conectivity = eval(tconnectivity.String);
THR1 = eval(tgaussiankernel2.String);
BCG1 = eval(tminI1.String);
WTSH1 = eval(twatershed1.String);
THR2 = eval(tgaussiankernel2.String);
BCG2 = eval(tminI2.String);
WTSH2 = eval(twatershed2.String);
AminmaxIminmax1 = [eval(tmina1.String),eval(tmaxa1.String),...
    eval(tminoI1.String),eval(tmaxoI1.String)]; %
AminmaxIminmax2 = [eval(tmina2.String),eval(tmaxa2.String),...
    eval(tminoI2.String),eval(tmaxoI2.String)]; 

im1(im1<=BCG1)=0;
im12 = imcomplement(im1);
im3 = imhmin(im12,WTSH1);
L = watershed(im3,conectivity);
im1(L==0)=0;
im12 = im1;
im1_tr = zeros(size(im1));
im1_tr = im1 > BCG1;
LB1 = AminmaxIminmax1(1);
UB1 = AminmaxIminmax1(2);
im1_tr = bwmorph(im1_tr,'hbreak');
im2(im2<BCG2)=0;
im_comp = imcomplement(im2);
im_comp1 = imhmin(im_comp,WTSH2);
L2 = watershed(im_comp1,conectivity);
im2(L2==0)=0;
im2_tr = zeros(size(im2));
im2_tr = im2 > BCG2;
im2_tr = bwmorph(im2_tr,'hbreak');
LB2 = AminmaxIminmax2(1);
UB2 = AminmaxIminmax2(2);

im2_tr = xor(bwareaopen(im2_tr,LB2,conectivity),  bwareaopen(im2_tr,UB2,conectivity));
im1_tr = xor(bwareaopen(im1_tr,LB1,conectivity),  bwareaopen(im1_tr,UB1,conectivity));   

im1_tr = removesmallobj(im1 .* double(im1_tr),1,LB1,conectivity);
im1_tr(im1_tr > 0) = 1;

im2_tr = removesmallobj(im2 .* double(im2_tr),1,LB2,conectivity);
im2_tr(im2_tr > 0) = 1;

L1 = bwlabel(im1_tr,conectivity);
rgb1 = label2rgb(L1, 'jet', [.7 .7 .7], 'shuffle');   
L2 = bwlabel(im2_tr,conectivity);
rgb2 = label2rgb(L2, 'jet', [.7 .7 .7], 'shuffle');
figure; imshow(rgb1); title('Image 1') 
figure; imshow(rgb2); title('Image 2') 

reg1 = regionprops(L1,im10,'Area','WeightedCentroid','PixelValues',...
'PixelIdxList','PixelList','Eccentricity' );
reg2 = regionprops(L2,im20,'Area','WeightedCentroid','PixelValues',...
'PixelIdxList','PixelList','Eccentricity' );
% data1 = struct2cell(reg1)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
% data2 = struct2cell(reg2)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
end 
%% plot segment
s_plotsegment = s_segment - [0 pbh+pbs 0 0];            
uicontrol('Style','pushbutton','String','Plot Segment',...
          'Position',s_plotsegment,...
           'Callback',@plotsegment_callback); 
function plotsegment_callback(~,~)
eccs1 = eval(teccentricitys1.String);
eccl1 = eval(teccentricityl1.String);
eccs2 = eval(teccentricitys2.String);
eccl2 = eval(teccentricityl2.String);
AminmaxIminmax1 = [eval(tmina1.String),eval(tmaxa1.String),...
    eval(tminoI1.String),eval(tmaxoI1.String)]; %
AminmaxIminmax2 = [eval(tmina2.String),eval(tmaxa2.String),...
    eval(tminoI2.String),eval(tmaxoI2.String)]; 
conectivity = eval(tconnectivity.String);
% geting all properties of segmented objects in image1 and image2
B1 = bwboundaries(L1,conectivity,'noholes');
B2 = bwboundaries(L2,conectivity,'noholes'); %boudaries of objects im2
map = jet;

a1nf=cellfun(@(x)numel(nonzeros(x)),{reg1(:).PixelValues}');
a2nf=cellfun(@(x)numel(nonzeros(x)),{reg2(:).PixelValues}');
eccentricity = [reg1(:).Eccentricity]';
eccentricity2 = [reg2(:).Eccentricity]';

figure;
    imagesc(im1,[0 scale(1)]),title('chanel 1')
    colorbar;   colormap(map); axis tight; 
    axis equal; 
    hold on;
flag = 0;
flag1 = 0;
for k = 1:length(B1)
           if (sum(reg1(k).PixelValues) > AminmaxIminmax1(3)) & (sum(reg1(k).PixelValues) < AminmaxIminmax1(4))

               if ismember(reg1(k).Area,1:LB1) & (eccentricity(k) >= eccs1)
                           flag1 = flag1 + 1;
                           Ismall1(flag1) = sum(reg1(k).PixelValues);
                           Asmall1(flag1) = a1nf(k);
                           boundary = B1{k};
                           plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.5)
                           indSmall1(flag1) = k;
               elseif ismember(reg1(k).Area,LB1+1:AminmaxIminmax1(4)) & (eccentricity(k) >= eccl1)
                           flag = flag + 1;
                           Ibig1(flag) = sum(reg1(k).PixelValues);
                           Abig1(flag) = a1nf(k);
                           indBig1(flag) = k;
                           boundary = B1{k};
                           plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 0.5)
                           clear boundary; 
               end
         
           end
end
clear flag;
hold off;
figure
imagesc(im2,[0 scale(2)]),title('chanel 2')
colorbar;  colormap(map); axis tight; 
axis equal; 
hold on;
flag = 0;
flag1 = 0;
for k = 1:length(B2)
    if (sum(reg2(k).PixelValues) > AminmaxIminmax2(3)) & (sum(reg2(k).PixelValues) < AminmaxIminmax2(4))
     if ismember(reg2(k).Area,1:LB2) & (eccentricity2(k) >= eccs2)
           flag1 = flag1 + 1;
           Ismall2(flag1) = sum(reg2(k).PixelValues);
           Asmall2(flag1) = a2nf(k);
           indSmall2(flag1) = k;
           boundary = B2{k};
           plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.5)
        elseif ismember(reg2(k).Area,LB2+1:AminmaxIminmax2(4)) & (eccentricity2(k) >= eccl2)
           flag = flag + 1;
           Ibig2(flag) = sum(reg2(k).PixelValues);
           Abig2(flag) = a2nf(k);
           indBig(flag) = k;
           boundary = B2{k};
           plot(boundary(:,2), boundary(:,1), 'm', 'LineWidth', 0.5)
     end
          
    end
end
clear flag;
hold off;       
end
%% manders
s_manders = s_segment + [0 pbw+pbs 0 0];            
uicontrol('Style','pushbutton','String','Manders',...
          'Position',s_manders,...
           'Callback',@manders_callback);
A1 = [];A2=[];I1=[];I2=[];MandersPairedG1 = [];MandersPairedR2=[];C2C12min=[];
function manders_callback(~,~)

eccl1 = eval(teccentricityl1.String);
eccl2 = eval(teccentricityl2.String);

AminmaxIminmax1 = [eval(tmina1.String),eval(tmaxa1.String),...
    eval(tminoI1.String),eval(tmaxoI1.String)]; %
AminmaxIminmax2 = [eval(tmina2.String),eval(tmaxa2.String),...
    eval(tminoI2.String),eval(tmaxoI2.String)]; 
conectivity = eval(tconnectivity.String);
distthr = eval(tmindist.String); %tmindist

data1 = struct2cell(reg1)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
data2 = struct2cell(reg2)';
totI1 = cellfun(@sum,{reg1(:).PixelValues}');
totI2 = cellfun(@sum,{reg2(:).PixelValues}');
% a1nf=[reg1(:).Area]';
% a2nf=[reg2(:).Area]';
a1nf=cellfun(@(x)numel(nonzeros(x)),{reg1(:).PixelValues}');
a2nf=cellfun(@(x)numel(nonzeros(x)),{reg2(:).PixelValues}');
eccentricity1 = [reg1(:).Eccentricity]';
eccentricity2 = [reg2(:).Eccentricity]';

ind1 = find(totI1 <= AminmaxIminmax1(4)) | find(totI1 >= AminmaxIminmax1(3)) ...
    | find(a1nf >= AminmaxIminmax1(1))  | find(a1nf <= AminmaxIminmax1(2))...
    | find(eccentricity1 >= eccl1);


ind2 = find(totI2 <= AminmaxIminmax2(4)) | find(totI2 >= AminmaxIminmax2(3)) ...
    | find(a2nf >= AminmaxIminmax2(1))  | find(a2nf <= AminmaxIminmax2(2))...
    | find(eccentricity2 >= eccl2);

clear c2 c1
cen2=[reg2(:).WeightedCentroid]';
c2(:,1)= cen2(1:2:end);
c2(:,2)= cen2(2:2:end);
cen1=[reg1(:).WeightedCentroid]';
c1(:,1)= cen1(1:2:end);
c1(:,2)= cen1(2:2:end);
clear cen1 cen2

I1 = totI1(ind1);
A1 = a1nf(ind1);
I2 = totI2(ind2);
A2 = a2nf(ind2);

data1 = data1(ind1,:);
data2 = data2(ind2,:);

C2C12 = pdist2(c1(ind1,:),c2(ind2,:));
[C2C12min,ind12min] = min(C2C12,[],2);
C2CminNT = C2C12min;
I2 = I2(ind12min);
A2 = A2(ind12min);

inthr = find(C2C12min <= distthr);
C2C12min = C2C12min(inthr);
ind12min = ind12min(inthr);
I1 = I1(inthr);
I2 = I2(inthr);
A1 = A1(inthr);
A2 = A2(inthr);
n1 = numel(inthr);
MandersPairedG1 = ones(n1,1);
MandersPairedR2 = ones(n1,1);
for ii = 1:n1
    PixelIdxList1 = data1{inthr(ii),3};
    PixelIdxList2 = data2{ind12min(ii),3};
    PixelPixelValues1 = data1{inthr(ii),5};
    PixelPixelValues2 = data2{ind12min(ii),5};
    [~,i1,i2] = intersect(PixelIdxList1,PixelIdxList2);
    G1_colocR2 = PixelPixelValues1(i1);
    R2_colocG1 = PixelPixelValues2(i2);
    MandersPairedG1(ii) = sum(G1_colocR2)/sum(PixelPixelValues1); %flag1th Mander coefficient
    MandersPairedR2(ii) = sum(R2_colocG1)/sum(PixelPixelValues2); %flag1th Mander coefficient
end
%
edges = [0:0.01:1];
[NG1,edges] = histcounts(MandersPairedG1,edges, 'Normalization', 'probability');
[NR2,edges] = histcounts(MandersPairedR2,edges, 'Normalization', 'probability');
figure;
subplot(2,2,1)
h1 = cdfplot(MandersPairedG1);
% histogram(NG1,edges,'Normalization','probability')
title('MG1')
axis square

subplot(2,2,2)
h1 = cdfplot(MandersPairedR2);
% histogram(NR2,edges,'Normalization','probability')
title('MR2')
axis square

edges1 = 1:100;
[NC2C,edges1] = histcounts(C2CminNT,edges1, 'Normalization', 'probability');

subplot(2,2,3)
plot(edges1(1:end-1),NC2C)
% histogram(NC2C,edges1,'Normalization','probability')
title('C2C min')
axis square
subplot(2,2,4)
plot(MandersPairedG1,MandersPairedR2,'.k')
title('MandersPairedG1 vs. MandersPairedR2')
axis square
end
%% save manders
s_savemanders = s_manders + [pbw+pbs 0 0 0];            
uicontrol('Style','pushbutton','String','Manders',...
          'Position',s_savemanders,...
           'Callback',@savemanders_callback); 
function savemanders_callback(~,~)
    
    choice = menu('Chose a file type to save','mat','excel','txt');
    prompt = {'Enter file name to save:'};
    dlg_title = 'Input';
    num_lines = 1;
    def = {'manders'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    name = answer{1};
    
    switch choice
        case 1
            matname = strcat(name,'A1_I1_A2_I2_C2C_M1_M2','.mat');
            save(matname,'A1','A2','I1','I2','C2C12min','MandersPairedG1',...
            'MandersPairedR2')    
        case 2
            xlsname = strcat(name,'.xls');
            T = table;
            T.A1 = A1;
            T.A2 = A2;
            T.I1 = I1;
            T.I2 = I2;
            T.C2C_12 = C2C12min;
            T.Manders1 = MandersPairedG1;
            T.Manders2 = MandersPairedR2;
            writetable(T,xlsname,'Sheet',1,'Range','A1')
        case 3
            txtname = strcat(name,'A1_I1_A2_I2_C2C_M1_M2','.txt');
            fileID = fopen(txtname,'w');
            fprintf(fileID,'%d %d %d %d %d %d %d\r\n',[A1,I1,A2,I2,C2C12min,...
                MandersPairedG1,MandersPairedR2]');
            fclose(fileID);
            
    end
end
%%
function BW2 = removesmallobj(I2,minI2,minAobj2,con)


            BW2 = I2;
            BW2(I2 < minI2) = 0;
            CC2 = bwconncomp(BW2,con);
            numPixels2 = cellfun(@numel,CC2.PixelIdxList);
            [~,idx2] = find(numPixels2 <= minAobj2);
            for k = 1:numel(idx2)
            BW2(CC2.PixelIdxList{idx2(k)}) = 0;
            end
end
end
