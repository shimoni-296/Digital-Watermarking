clc;
clear;
close all;
RawFilename = '..\Data\CTS1\000004.dcm';
InfoDataName = '..\Data\InfoS1\000004.txt';
WM = readtable(InfoDataName);
IMAGE = double(dicomread(RawFilename));
HEADER = dicominfo(RawFilename);
figure;imshow(IMAGE,[]);title('original image');

%%%%%%%%%%%%%%%%%%%%%%%% watermark encode %%%%%%%%%%%%%%%%%%%%%%%%
bin_len = 8;
pos_shift = 16;
Im_co = watermark_encode(IMAGE,WM,bin_len,pos_shift);
figure;imshow(Im_co,[]);title('watermarking image in spatial domain');
figure;imshow(Im_co-IMAGE,[]);title('');title('differential image');

%%%%%%%%%%%%%%%%%%%%%%%% watermark decode %%%%%%%%%%%%%%%%%%%%%%%%
bin_len2 = 8;
pos_shift2 = 16;
information = watermark_decode(Im_co,bin_len2,pos_shift2);

%%%%%%%%%%%%%%%%%%%%%%%% evaluation %%%%%%%%%%%%%%%%%%%%%%%%
[m,n] = size(IMAGE);
MSE = sum(sum((Im_co-IMAGE).*(Im_co-IMAGE)))/(m*n);


