clc;
clear;
close all;
%% ====================== read data ======================
RawFilename = '../Data/CTS1/000040.dcm';
InfoDataName = '../Data/Information.txt';
fileID = fopen(InfoDataName,'r');
values = '../Data/OutputParameters.txt';
output = fopen(values,'w');
LOGO = imread('../Data/Logo.png');
LOGO = rgb2gray(LOGO);
LOGO = imresize(LOGO,0.06);
LOGO = rescale(LOGO);
threshold = graythresh(LOGO);
LOGO = imbinarize(LOGO,threshold);
[Lm,Ln] = size(LOGO);
TAF = reshape(LOGO,[1,Lm*Ln]);
WM = textscan(fileID,'%s %s','Delimiter','|');
fclose(fileID);
IMAGE = double(dicomread(RawFilename));
HEADER = dicominfo(RawFilename);

%% ====================== ROI segmentation ======================
[B, MaskImg] = segmentation(IMAGE); %example of using segmentation

RONI = 1 - MaskImg;

%% ====================== Haar Filter ======================
%{
p = [1 2 1]/2;
h0 = poly(-1);
f0 = deconv(p,h0);
h0 = sqrt(2)*h0/sum(h0);
f0 = sqrt(2)*f0/sum(f0);
h1 = f0.*[1 -1];
f1 = h0.*[-1 1];
%}

%% ====================== Info Blocks ======================
PatientInfo_Idx = find(strcmp(WM{1},'PatientInfo'));
ImageInfo_Idx = find(strcmp(WM{1},'ImageInfo'));
Diagnosis_Idx = find(strcmp(WM{1},'Diagnosis'));
PhysicianInfo_Idx = find(strcmp(WM{1},'PhysicianInfo'));
Diagnosis_Idx2 = Diagnosis_Idx + (PhysicianInfo_Idx - Diagnosis_Idx - 1)/2;
PatientInfo = {WM{1}(PatientInfo_Idx+1:ImageInfo_Idx-1),WM{2}(PatientInfo_Idx+1:ImageInfo_Idx-1)};
ImageInfo = {WM{1}(ImageInfo_Idx+1:Diagnosis_Idx-1),WM{2}(ImageInfo_Idx+1:Diagnosis_Idx-1)};
Diagnosis1 = {WM{1}(Diagnosis_Idx+1:Diagnosis_Idx2),WM{2}(Diagnosis_Idx+1:Diagnosis_Idx2)};
Diagnosis2 = {WM{1}(Diagnosis_Idx2+1:PhysicianInfo_Idx-1),WM{2}(Diagnosis_Idx2+1:PhysicianInfo_Idx-1)};
PhysicianInfo = {WM{1}(PhysicianInfo_Idx+1:end),WM{2}(PhysicianInfo_Idx+1:end)};

fprintf(output,"\n\n\n");


%% ====================== 2D 3level DWT ======================
Level = 3;
[a,h,v,d] = haart2(IMAGE,Level);

% construct image in wavelet domain for display
Im = a;
for i = Level:-1:1
    Im = [Im h{i};v{i} d{i}];
end




%% ====================== Generating Key ======================

Zero_to_One_ratio = 10;

Key_incl_ROI = double(randi([0 Zero_to_One_ratio], 256,256) == 0);

Key = Key_incl_ROI & RONI(2:2:end,2:2:end);

Key2 = Key(2:2:end,2:2:end);



%% ====================== watermark encode ======================
bin_len = 8;
code_len = 31;
pos_shift = 31;
Q = 4;
d{1} = double(TAF_encode(int64(Q*d{1}),TAF,pos_shift,code_len,Key))/Q;
d{2} = double(watermark_encode(int64(Q*d{2}),PhysicianInfo,bin_len,pos_shift,code_len,Key2))/Q;
v{1} = double(watermark_encode(int64(Q*v{1}),PatientInfo,bin_len,pos_shift,code_len,Key))/Q;
h{1} = double(watermark_encode(int64(Q*h{1}),ImageInfo,bin_len,pos_shift,code_len,Key))/Q;
v{2} = double(watermark_encode(int64(Q*v{2}),Diagnosis1,bin_len,pos_shift,code_len,Key2))/Q;
h{2} = double(watermark_encode(int64(Q*h{2}),Diagnosis2,bin_len,pos_shift,code_len,Key2))/Q;

Im_re = ihaart2(a,h,v,d);
figure;
subplot(1,2,1);imshow(IMAGE,[]);title('original image');
subplot(1,2,2);imshow(Im_re,[]);title('watermarked image');



%% ====================== evaluation ======================

% construct image in wavelets domain for display
Im_co = a;
for i = Level:-1:1
    Im_co = [Im_co h{i};v{i} d{i}];
end
figure;
subplot(1,2,1);imshow(Im,[]);title('original image in wavelets domain');
subplot(1,2,2);imshow(Im_co,[]);title('watermarked image in wavelets domain');

[m,n] = size(IMAGE);
figure;
subplot(1,2,1);imshow(Im_co-Im,[]);title('differential image in wavelets domain');
subplot(1,2,2);imshow(Im_re-IMAGE,[]);title('differential image in spatial domain');
MSE = sum(sum((Im_re-IMAGE).*(Im_re-IMAGE)))/(m*n);
SNR = snr(IMAGE,IMAGE-Im_re);
PSNR = psnr(Im_re,IMAGE,max(max(IMAGE)));


fprintf(output,"--------------- Output Values Calculated -----------------\n\n");
fprintf(output,"\n Mean Square Error (MSR) = %f\n",MSE);
fprintf(output,"\n Signal to Noise Ratio (SNR) = %f\n",SNR);
fprintf(output,"\n Peak Signal to Noise Ratio (PSNR) = %f\n",PSNR);

wrong_det = zeros(2,4);
tamper = zeros(2,4);

%%dicomwrite(Im_re, "../Data/WatermarkedImage.dcm");

%% ====================== watermark decode ======================

[a2,h2,v2,d2] = haart2(Im_re,Level);
TAF_re = logical(TAF_decode(int64(Q*d2{1}),pos_shift,code_len,Key));
[Diagnosis1_re,wrong_det_1,tamper_1] = watermark_decode(int64(Q*v2{2}),bin_len,pos_shift,code_len,Key2);
[Diagnosis2_re,wrong_det_2,tamper_2] = watermark_decode(int64(Q*h2{2}),bin_len,pos_shift,code_len,Key2);
wrong_det(1,1) = wrong_det_1 & wrong_det_2;
tamper(1,1) = tamper_1 & tamper_2;
[PhysicianInfo_re,wrong_det(1,2),tamper(1,2)] = watermark_decode(int64(Q*d2{2}),bin_len,pos_shift,code_len,Key2);
[PatientInfo_re,wrong_det(1,3),tamper(1,3)] = watermark_decode(int64(Q*v2{1}),bin_len,pos_shift,code_len,Key);
[ImageInfo_re,wrong_det(1,4),tamper(1,4)] = watermark_decode(int64(Q*h2{1}),bin_len,pos_shift,code_len,Key);
TAF_ratio = sum(abs(TAF_re-TAF))/length(TAF);

figure;


subplot(1,2,1);imshow(LOGO,[]);title('original LOGO');
subplot(1,2,2);imshow(reshape(TAF_re,[Lm,Ln]),[]);title('retrieved LOGO');
%% ====================== attack testing ======================

Atk_Num = 5;

attacktype = {'flip','gaussfilt','medfilt','modification','salt & pepper','gaussian'}; 
parameter = {2, 0.2, 5, [32 0], 0.01, [0 0.01]};
AttackedImg = attack(Im_re,attacktype,parameter);
figure;
subplot(1,2,1);imshow(Im_re,[]);title('watermarked image');
subplot(1,2,2);imshow(AttackedImg{Atk_Num},[]);title('watermarked image after attacking');
MSE2 = sum(sum((AttackedImg{Atk_Num}-IMAGE).*(AttackedImg{Atk_Num}-IMAGE)))/(m*n);
SNR2 = snr(IMAGE,IMAGE-AttackedImg{Atk_Num});
PSNR2 = psnr(AttackedImg{Atk_Num},IMAGE,max(max(IMAGE)));

fprintf(output,"\n\n --------Output Values after attacking the watermarked image-----------\n\n");
fprintf(output,"\n Mean Square Error (MSR) = %f\n",MSE2);
fprintf(output,"\n Signal to Noise Ratio (SNR) = %f\n",SNR2);
fprintf(output,"\n Peak Signal to Noise Ratio (PSNR) = %f\n",PSNR2);
%% ====================== watermark retrieve ======================

[a3,h3,v3,d3] = haart2(AttackedImg{Atk_Num},Level);
TAF_re2 = logical(TAF_decode(int64(Q*d3{1}),pos_shift,code_len,Key));
[Diagnosis1_re2,wrong_det_1,tamper_1] = watermark_decode(int64(Q*v3{2}),bin_len,pos_shift,code_len,Key2);
[Diagnosis2_re2,wrong_det_2,tamper_2] = watermark_decode(int64(Q*h3{2}),bin_len,pos_shift,code_len,Key2);
wrong_det(1,1) = wrong_det_1 & wrong_det_2;
tamper(1,1) = tamper_1 & tamper_2;
[PhysicianInfo_re2,wrong_det(2,2),tamper(2,2)] = watermark_decode(int64(Q*d3{2}),bin_len,pos_shift,code_len,Key2);
[PatientInfo_re2,wrong_det(2,3),tamper(2,3)] = watermark_decode(int64(Q*v3{1}),bin_len,pos_shift,code_len,Key);
[ImageInfo_re2,wrong_det(2,4),tamper(2,4)] = watermark_decode(int64(Q*h3{1}),bin_len,pos_shift,code_len,Key);
TAF_ratio2 = sum(abs(TAF_re2-TAF))/length(TAF);

figure;
subplot(1,2,1);imshow(LOGO,[]);title('original LOGO');
subplot(1,2,2);imshow(reshape(TAF_re2,[Lm,Ln]),[]);title('retrieved LOGO after attacking');


fclose(output);