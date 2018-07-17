% function ( imname1,imname2,treshold,AminmaxIminmax1,minA_im2,transform,scale,mask,map,varargin )
% this is a working version of a simple program for image based
% segmentation of super-resolved images. It should work on low res images
% as well. This program will be shortly updated.

close all
clear all

% 
prompt1 = {'Enter threshold for image 1 binarisation',...
    'Enter background intensity for image 1',...
    'Enter watershed threshold for image 1',...
    'Enter threshold fo image 2 binarisation',...
    'Enter background intensity for image 2',...
    'Enter watershed threshold for image 2',...
    'Enter 1 to draw mask',...
    'Enter upper thr for im 1 display',...
    'Enter upper thr for im 2 display',...
    'Enter 1 to load rgb stack, 0 to load individual images separately, 2 if images are already loaded',...
    'Enter min size of an object image 1',...
    'Enter max size of an object image 1',...
    'Enter min size of an object image 2',...
    'Enter max size of an object image 2',...
    'Enter min intensity for an object image 1',...
    'Enter max intensity for an object image 1',...
    'Enter min intensity for an object image 2',...
    'Enter max intensity for an object image 2',...
    'Enter min distance for nn'};

    dlg_title1 = 'Enter parameter for image 1 processing';
    num_lines1 = 1;
    def1 = {'0.9','7','15','0.9','8','15','0','150','150','2',...
    '25','2000','10','2000',...
    '250','20000','100','20000','15'};
    answer1 = inputdlg(prompt1,dlg_title1,num_lines1,def1);
    answer = num2cell(arrayfun(@str2double,answer1)); 
    [THR1,BCG1,WTSH1,THR2,BCG2,WTSH2,bw,scale(1),scale(2),imload,...
    AminmaxIminmax1(1),AminmaxIminmax1(2),AminmaxIminmax2(1),AminmaxIminmax2(2),...%area
    AminmaxIminmax1(3),AminmaxIminmax1(4),AminmaxIminmax2(3),AminmaxIminmax2(4),nnd_tr] = answer{:};%intensity
    transform = [];
    map = jet;
    %% setting some more parameters
    
    fileflag = 'HR'; % enter a regular expression to find automaticcaly two color images.
    % all images with fileflag in the name will be detected, you should
    % have just two images like that in one folder, correspondinhg to image
    
    gauss1 = 0.5;
    gauss2 = 0.75; % gaussian smoothing parameters for chanel 1 and 2
    maxim1 = 50; % maximum value for image 1 scalin; only visualization
    conectivity = 4; % connevctivity to segment clusters
    sig = 3;
    circ = 0.2; % thresholds for image 1 object minimum eccentricity
    circ1 = 0.2; % thresholds for image 2 object minimum eccentricity
    %%
    % to chanel 1 and 2
    files = dir(pwd);
    C = {files.name};
    IndexC = strcmp(C, '.');
    files = files(~IndexC); 
    IndexC = strcmp({files.name}, '..');
    files = files(~IndexC); 
    files = {files.name};
    tfmat = ~cellfun('isempty',strfind(files,fileflag));
    files = files(tfmat);
    fname = files{1};
    im647 = imread(fname, 1);
    im532 = imread(fname, 2);
    im1 = double(im532);
    im2 = double(im647);
    im10=im1;
    im20=im2;
    im2 = imgaussfilt(im2,gauss1);
    im1 = imgaussfilt(im1,gauss2);
%     AminmaxIminmax2(1) = 5;

%% background substraction and watersheding of im1
    im1(im1<=BCG1)=0;
    im12 = imcomplement(im1);
    im3 = imhmin(im12,WTSH1);
    L = watershed(im3,conectivity);
    im1(L==0)=0;
    im12 = im1;
%%
    im1_tr = im2bw(im1,THR1); % thersholding im1
    figure;imagesc(im1_tr);
    figure;imagesc(im1 .* double(im1_tr),[0,maxim1]);
%%
LB1 = AminmaxIminmax1(1);
UB1 = AminmaxIminmax1(2);

im1_tr = bwmorph(im1_tr,'hbreak'); % removing h breaks from im1
%     im1_tr = bwmorph(im1_tr,'spur');

%% image2 segmentation
im2(im2<BCG2)=0;
im_comp = imcomplement(im2);
im_comp1 = imhmin(im_comp,WTSH2);
L2 = watershed(im_comp1,conectivity);
im2(L2==0)=0;
im2_tr = im2bw(im2,THR2);% treshold im2
im2_tr = bwmorph(im2_tr,'hbreak');
%     im2_tr = bwmorph(im2_tr,'spur');
LB2 = AminmaxIminmax2(1);
UB2 = AminmaxIminmax2(2);
%% removing small and dim objects from an image
im2_tr = xor(bwareaopen(im2_tr,LB2,conectivity),  bwareaopen(im2_tr,UB2,conectivity));
im1_tr = xor(bwareaopen(im1_tr,LB1,conectivity),  bwareaopen(im1_tr,UB1,conectivity));   

im1_tr = removesmallobj(im1 .* double(im1_tr),1,LB1,conectivity);
im1_tr(im1_tr > 0) = 1;

im2_tr = removesmallobj(im2 .* double(im2_tr),1,LB2,conectivity);
im2_tr(im2_tr > 0) = 1;
%% displying segmented image with labe matrix
L1 = bwlabel(im1_tr,conectivity);
rgb1 = label2rgb(L1, 'jet', [.7 .7 .7], 'shuffle');   
L2 = bwlabel(im2_tr,conectivity);
rgb2 = label2rgb(L2, 'jet', [.7 .7 .7], 'shuffle');
figure; imshow(rgb1);  
figure; imshow(rgb2); 

% geting all properties of segmented objects in image1 and image2
B1 = bwboundaries(L1,conectivity,'noholes');
B2 = bwboundaries(L2,conectivity,'noholes'); %boudaries of objects im2
reg1 = regionprops(L1,im10,'Area','WeightedCentroid','PixelValues',...
'PixelIdxList','PixelList','Eccentricity' );
reg2 = regionprops(L2,im20,'Area','WeightedCentroid','PixelValues',...
'PixelIdxList','PixelList','Eccentricity' );
data1 = struct2cell(reg1)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
data2 = struct2cell(reg2)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
% clearvars('*', '-except', 'data1','data2','im10','im20','L1','L2','reg1','reg2','B1','B2',...
%     'scale','AminmaxIminmax1','AminmaxIminmax2','LB1','LB2','UB1','UB2');

% displaying 2 color segmented image
figure;imshowpair(L1>0,L2>0)
figure;imshowpair(im1,im2,'Scaling','none')
%% pgetting some parameters of segmented objects from the image
clear c2 c1
cen2=[reg2(:).WeightedCentroid]';
c2(:,1)= cen2(1:2:end);
c2(:,2)= cen2(2:2:end);

cen1=[reg1(:).WeightedCentroid]';
c1(:,1)= cen1(1:2:end);
c1(:,2)= cen1(2:2:end);

a1nf=cellfun(@(x)numel(nonzeros(x)),{reg1(:).PixelValues}');
a2nf=cellfun(@(x)numel(nonzeros(x)),{reg2(:).PixelValues}');

totI1 = cellfun(@sum,{reg1(:).PixelValues}');
totI2 = cellfun(@sum,{reg2(:).PixelValues}');

%%
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

               if ismember(reg1(k).Area,1:LB1) & (eccentricity(k) >= circ)
                           flag1 = flag1 + 1;
                           Ismall1(flag1) = sum(reg1(k).PixelValues);
                           Asmall1(flag1) = a1nf(k);
                           boundary = B1{k};
                           plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.5)
                           indSmall1(flag1) = k;
               elseif ismember(reg1(k).Area,LB1+1:AminmaxIminmax1(4)) & (eccentricity(k) >= circ1)
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
% subplot(2,1,2);
figure
imagesc(im2,[0 scale(2)]),title('chanel 2')
colorbar;  colormap(map); axis tight; 
axis equal; 

hold on;
flag = 0;
flag1 = 0;
for k = 1:length(B2)
    if (sum(reg2(k).PixelValues) > AminmaxIminmax2(3)) & (sum(reg2(k).PixelValues) < AminmaxIminmax2(4))
     if ismember(reg2(k).Area,1:LB2) & (eccentricity2(k) >= circ)
           flag1 = flag1 + 1;
           Ismall2(flag1) = sum(reg2(k).PixelValues);
           Asmall2(flag1) = a2nf(k);
           indSmall2(flag1) = k;
           boundary = B2{k};
           plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 0.5)
        elseif ismember(reg2(k).Area,LB2+1:AminmaxIminmax2(4)) & (eccentricity2(k) >= circ1)
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