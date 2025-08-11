function str = engnum(val)
    exp3 = floor(log10(abs(val))/3)*3;
    mant = val / 10^exp3;
    str = sprintf('%gE%d', mant, exp3);
end

