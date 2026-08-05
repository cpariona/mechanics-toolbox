function label = formatUnitLabel(name, unit)
%FORMATUNITLABEL Append a bracketed display unit to a plotting label.
arguments
    name (1,1) string
    unit (1,1) string
end

unit = strtrim(unit);
if strlength(unit) == 0
    label = name;
else
    label = name + " [" + unit + "]";
end
end
