function information  = TAF_decode(Im,pos_shift,code_len,Key)

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
end

information = [];
for j = 1:Ind_end
    information = [information,mod(Im(Ind(j)),2)];
end

end