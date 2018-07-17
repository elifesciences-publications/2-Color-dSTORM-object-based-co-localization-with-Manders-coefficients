%% manders analysis

psave = 1; % saveing flag
name = strcat('Cell',num2str(13)); % saveing name, use whatever
xlsname = strcat(name,'.xls'); % excel saveing name
matname = strcat(name,'.mat'); % mat saving name
if psave
    delete('*.xls') % close any opne excel file
end
% reg1 and reg2 is a data structure obtained using 
data1 = struct2cell(reg1)'; % area, eccentr, pixelIDXlist, pixel list, pixel values, WC
data2 = struct2cell(reg2)';
totI1 = cellfun(@sum,{reg1(:).PixelValues}');
totI2 = cellfun(@sum,{reg2(:).PixelValues}');
% a1nf=[reg1(:).Area]';
% a2nf=[reg2(:).Area]';
a1nf=cellfun(@(x)numel(nonzeros(x)),{reg1(:).PixelValues}');
a2nf=cellfun(@(x)numel(nonzeros(x)),{reg2(:).PixelValues}');

Imin = 12000; % minimum integrated intensity for an object in image 1   nd 2
ind1 = find(totI1 <= Imin);
ind2 = find(totI2 <= Imin);
I1 = totI1(ind1);
A1 = a1nf(ind1);
I2 = totI2(ind2);
A2 = a2nf(ind2);
totI1 = totI1(ind1);
a1nf = a1nf(ind1);
totI2 = totI2(ind2);
a2nf = a2nf(ind2);
data1 = data1(ind1,:);
data2 = data2(ind2,:);

distthr = 100; % minimum distance between two object for Manders coefficient to be calculated
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
% calculation of MAnders coeffcients
for ii = 1:n1
    PixelIdxList1 = data1{inthr(ii),3};
    PixelIdxList2 = data2{ind12min(ii),3};
    PixelPixelValues1 = data1{inthr(ii),5};
    PixelPixelValues2 = data2{ind12min(ii),5};
    [intsc,i1,i2] = intersect(PixelIdxList1,PixelIdxList2);
    G1_colocR2 = PixelPixelValues1(i1);
    R2_colocG1 = PixelPixelValues2(i2);
    MandersPairedG1(ii) = sum(G1_colocR2)/sum(PixelPixelValues1); %flag1th Mander coefficient
    MandersPairedR2(ii) = sum(R2_colocG1)/sum(PixelPixelValues2); %flag1th Mander coefficient
end
%
edges = [0:0.01:05]; % bin vector for the display of M's coefficients
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
%% preparing the data for saveing

T = table;
T.A1 = A1;
T.A2 = A2;
T.I1 = I1;
T.I2 = I2;
T.C2C_12 = C2C12min;
T.Manders1 = MandersPairedG1;
T.Manders2 = MandersPairedR2;

T1 = table;
T1.firstNN_ALL = C2CminNT;

T2 = table;
T2.I1_ALL = totI1;
T2.A1_ALL = a1nf;

T3 = table;
T3.I2_ALL = totI2;
T3.A2_ALL = a2nf;

C2C12_sort = sort(C2C12,2);
C2C12_sort10 = C2C12_sort(:,1:10);
T4 = table;
T4.C2C_12_first10neighbours = C2C12_sort10;
%% saving the data to excel sheet
if psave
writetable(T,xlsname,'Sheet',1,'Range','A1')
writetable(T1,xlsname,'Sheet',1,'Range','I1')
writetable(T3,xlsname,'Sheet',1,'Range','K1')
writetable(T2,xlsname,'Sheet',1,'Range','N1')
save(matname)
writetable(T4,xlsname,'Sheet',1,'Range','r1')
end
%%
% tmp = load('mask.mat','BW647');
% mask = tmp.BW647;
% mask = flipud(mask);
% [rm cm] = find(mask);
% R = [rm cm]; 
% nr = numel(R(:,1));
% n1 = size(c1,1);
% n2 = size(c2,1);
% % c1r = zeros(n1,Nsimul);
% Nsimul = 100;
% c2r = zeros(n2,Nsimul);
% 
% for i = 1:Nsimul
% i
% RP2 = randperm(nr,nn);
% c2r(:,2) = R([unique(RP2)],2);
% c2r(:,1) = R([unique(RP2)],1);
% end