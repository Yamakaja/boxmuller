%%%%%%%%%%%%%%%%%%%
% output_remapper %
%%%%%%%%%%%%%%%%%%%

%#codegen
function y_out = output_remapper(x_in, factor, offset)
    % declare registers
    persistent r_1 r_2 r_3 r_4 r_5;
    
    % Reset circuit
    if isempty(r_1)
        r_1 = 0;
        r_2 = 0;
        r_3 = 0;
        r_4 = 0;
        r_5 = 0;
    end
    
    y_out = r_5;
    r_5 = r_4;
    r_4 = min(max(r_3, -7.5), 7.5);
    r_3 = r_2 + offset;
    r_2 = r_1 * factor;    
    
    r_1 = x_in;
    
end