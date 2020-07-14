function [information, wrong_det,tamper]  = watermark_decode(Im,bin_len,pos_shift,code_len,Key)

tamper = 0;

wrong_det_counter = 0;
tamper_counter = 0;

Ind = find(Key);


while(Ind(1) <= pos_shift)
    Ind = Ind(2:end);
end

code_Ind_end = [];
for j = 1:code_len
    if mod(Im(j),2) == 0
        code_Ind_end = [code_Ind_end,'0'];
    else
        code_Ind_end = [code_Ind_end,'1'];
    end
end

Ind_end = char(gf2dec(bchdec(gf(double(code_Ind_end) - 48),31,16),1,3) + 48);

Ind_end = bin2dec(Ind_end);

if(Ind_end > length(Ind)) 
    Ind_end = length(Ind);
    disp('length error')
    tamper = 1;
end

tamper = tamper || (mod(Ind_end,code_len) ~= 0);

num = floor(Ind_end/code_len);

information = [];
for j = 1:max(num,1)
    temp = [];
    for k = 1:code_len
        if mod(Im(Ind(code_len*(j-1)+k)),2) == 0
            temp = [temp,'0'];
        else
            temp = [temp,'1'];
        end
    end
    
    [Decoded_GF,Corr] = bchdec(gf(double(temp) - 48),31,16);
    Decoded = char(gf2dec(Decoded_GF,1,3) + 48);
    
    wrong_det_counter = wrong_det_counter + (Corr == -1);
    tamper_counter = tamper_counter + (Corr ~= 0);
    
    information = [information,char(bin2dec(Decoded(1:bin_len))),char(bin2dec(Decoded(bin_len+1:end)))];
end

wrong_det = (wrong_det_counter > 3);
tamper = tamper || (tamper_counter > 3);

end