function AttackedImg = attack(IMAGE,attacktype,parameter)
if length(attacktype)~=length(parameter)
    error(message('attack set and parameter set should have same length'));
end
AttackedImg = cell(size(attacktype));
MAX = max(max(IMAGE));
MIN = min(min(IMAGE));
[m,n] = size(IMAGE);

for i = 1:length(attacktype)
    switch attacktype{i}
        case 'gaussian'
            if length(parameter{i})~=2
                error(message('Gaussian noise should have 2 parameters M and V'));
            end
            Noise = (MAX-MIN)*(sqrt(parameter{i}(2))*randn(size(IMAGE)) + parameter{i}(2));
            AttackedImg{i} = IMAGE + Noise;
        case 'salt & pepper'
            if length(parameter{i})~=1
                error(message('salt & pepper noise should have 1 parameter d'));
            end
            AttackedImg{i} = IMAGE;
            x = rand(size(IMAGE));
            AttackedImg{i}(x < parameter{i}/2) = MIN; % Minimum value
            AttackedImg{i}(x >= parameter{i}/2 & x < parameter{i}) = MAX; % Maximum (saturated) value
        case 'medfilt'
            if length(parameter{i})~=1
                error(message('median filtering should have 1 parameter s'));
            end
            AttackedImg{i} = medfilt2(IMAGE,[parameter{i} parameter{i}]);
        case 'gaussfilt'
            if length(parameter{i})~=1
                error(message('gaussian filtering should have 1 parameter s'));
            end
            AttackedImg{i} = imgaussfilt(IMAGE, parameter{i});
        case 'flip'
            if length(parameter{i})~=1
                error(message('flip transform should have 1 parameter o'));
            end
            if (parameter{i}~=1 && parameter{i}~=2)
                  error(message('flip operation from 1:upside-down, 2:mirror'));
            end
            AttackedImg{i} = flip(IMAGE, parameter{i});
        case 'modification'
            if length(parameter{i})~=2
                error(message('modification should have 2 parameter p and s'));
            end
            AttackedImg{i} = IMAGE;
            s = parameter{i}(1);
            p = parameter{i}(2);
            x = MAX*ones(s,s);
            if (p == 0)
                AttackedImg{i}((m-s)/2:(m-s)/2+s-1,(n-s)/2:(n-s)/2+s-1) = x;
            elseif (p == 1)
                AttackedImg{i}((m/8-s/2):(m/8-s/2)+s-1,(n/8-s/2):(n/8-s/2)+s-1) = x;
            elseif (p == 2)
                AttackedImg{i}((m/8-s/2):(m/8-s/2)+s-1,(n*7/8-s/2):(n*7/8-s/2)+s-1) = x;
            elseif (p == 3)
                AttackedImg{i}((m*7/8-s/2):(m*7/8-s/2)+s-1,(n/8-s/2):(n/8-s/2)+s-1) = x;
            elseif (p == 4)
                AttackedImg{i}((m*7/8-s/2):(m*7/8-s/2)+s-1,(n*7/8-s/2):(n*7/8-s/2)+s-1) = x;
            else
                error(message('choose modification position from 0:center, 1:top left, 2:top right, 3:bottom left, 4:bottom right'));
            end
        case 'scale'
            if length(parameter{i})~=1
                error(message('scale transform should have 1 parameter s'));
            end
            AttackedImg{i} = imresize(IMAGE, parameter{i});
        otherwise
            error(message('error attacktype'));
    end
end
end

