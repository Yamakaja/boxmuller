%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output_remapper Testbench %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear output_remapper;

N = 128;
N_par = 32;

factors = linspace(0, 15, N_par);
offsets = linspace(-7, 7, N_par);
samples = randn(N, 1);

for i_factor=1:N_par
    for i_offset=1:N_par
        for i=1:N
            output_remapper(samples(i), factors(i_factor), offsets(i_offset));
        end
    end
end
