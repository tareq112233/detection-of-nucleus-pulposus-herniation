function rrrrr(imgor)
%  clc 
% clear all;
% info = dicominfo('C:\Users\tareq\OneDrive\Documents\fadel.dcm');
% imgor= dicomread(info); 
imgor2=histeq(imgor);
figure (1);imshow(imgor,[])

img =imadjust(imgor2,[0.75 0.95],[]);
se = strel('disk',3);
img1 = imopen(img, se);
figure (2);imshow(img1,[])
%تحسين الصورة  
mask = adapthisteq(img1,'clipLimit',0.2,'Distribution','rayleigh');
se = strel('disk',7);
marker = imerode(mask,se);
obr = imreconstruct(marker,mask,8);
figure (3);imshow(obr,[])
%اعادة البناء الصرفي (عملية مورفولوجيه)
img2=imbinarize(obr,0.65);
%التحويل الى صورة ثنائيه بعتبة مساميه
img4=immultiply(imgor,img2);
figure (4);imshow(img4,[])
%ضرب الصورة الناتجة بالصورة الاصليه
img_max = max(imgor(:));
if (img_max > 800) && (img_max <= 1000)
    img5=img4>650;
elseif (img_max > 350) && (img_max <= 800)
    img5=img4>300;
else
 level = graythresh(img4);
img5 = imbinarize(img4,level);
end
figure (5);imshow(img5,[])

%حلقه للتعتيب (لتعتيب بشكل متناسب مع حجم البيكسلات او حجم الصورة)
se = strel('disk',5);
img6 = imdilate(img5,se);
img7=imcomplement(img6);
% img77=medfilt2(img7);
img8=imfill(img7,'holes');
img9=imcomplement(img8);
img11=imsubtract(img2,img9);
bin2=imbinarize(img11,'global');
%خوارزمية لازالة الهيكل الكبير ذو السويات  الرمادية المتقاربه من سويات
%الحبل
img00=immultiply(imgor,bin2);
% img00=medfilt2(img00);
 se = strel('disk',3);
img01 = imopen(img00,se);
marker0=img01>215;
 se = strel('disk',2);
imgt = imdilate(marker0,se);
% img02 = bwareafilt(imgt,2);
img03 = bwareaopen(imgt,1600);
figure (6);imshow(img03,[])

%تجزئه الحبل الشوكي لبعض الحالات
[B, L] = bwboundaries(img03, 'noholes'); %CCl
% plotObjectsAndBoundaries(B, L) % to show opjects selected in the image 
stats2 = regionprops('table',img03,'Area','Centroid',...
    'MajorAxisLength','MinorAxisLength','Eccentricity','ConvexArea','PixelList', 'Solidity');%
%قياس خصائص الصورة الطبيه 
[rows1, cols1] = size(stats2);
if rows1 > 1
 se = strel('disk',10);
imgt11 = imopen(img03,se);
 imgt12=imsubtract(img03,imgt11);
img03 = bwareaopen(imgt12,1000);
else
imshow(img03,[])
end
%حلقه شرطيه لايجاد هيكل واحد يكون الحبل الشوكي فقط 
se=strel('line',24,55);
a1=imclose(img03,se);
b1=imopen(a1,se);
ii=imsubtract(img03,b1);
i = bwareaopen(ii,100);
t=immultiply(i,imgor);
tt=t>300;
tt = bwareaopen(tt,15);
se=strel('disk',15);
ta=imdilate(tt,se);
ttaa=immultiply(ta,imgor);
figure (7);imshow(ttaa,[])

%تجزئة الحبل للمناطق غير المطلوبة
se=strel('line',21,30);
b2=imopen(ta,se);
tta=immultiply(b2,imgor);
ttta=tta>120;
taa=imsubtract(b2,ttta);
se=strel('disk',2);
taq=imerode(taa,se);
[B1, L2] = bwboundaries(taq, 'noholes'); 
stats3 = regionprops('table',img03,'Area','Centroid','MajorAxisLength' ...
    ,'MinorAxisLength','BoundingBox','Eccentricity','ConvexArea','PixelList', 'Solidity');%
p=stats3.Area;
if p<3000
tar = bwareaopen(taq,70);
else
    tar= bwareaopen(taq,110);
end
figure (8);imshow(tar,[])
se=strel('line',70,105);
taq2=imdilate(tar,se);
se=strel('disk',10);
taq3=imdilate(taq2,se);
imge=immultiply(imgor,taq3);
title('Mask Over Original Image')
BWoutline = bwperim(imge);
Segout = imgor; 
Segout(BWoutline) = 800; 
figure (9);imshow(Segout,[])
end




