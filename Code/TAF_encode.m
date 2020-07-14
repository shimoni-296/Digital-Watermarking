function Im = TAF_encode(IMAGE,WM,pos_shift,code_len,Key)

Ind = find(Key);

while(Ind(1) <= pos_shift)
    Ind = Ind(2:end);
end

Ind_end = length(WM);

Im = IMAGE;
for i = 1:length(WM)
    if (mod(IMAGE(Ind(i)),2) ~= int64(WM(i)))
        if (IMAGE(Ind(i))<0)
            Im(Ind(i)) = IMAGE(Ind(i)) + 1;
        else
            Im(Ind(i)) = IMAGE(Ind(i)) - 1;
            
        end
    end
end
    
Ind_end = dec2bin(Ind_end,16);

code_Ind_end = gf2dec(bchenc(gf(double(Ind_end) - 48),31,16),1,3);

for j = 1:code_len
    if (mod(IMAGE(j),2) ~= int64(code_Ind_end(j)))
        if (IMAGE(j)<0)
            Im(j) = IMAGE(j) + 1;
        else
            Im(j) = IMAGE(j) - 1;
        end
    end
end
end