function label = formatUnitLabel(name, unit)
%FORMATUNITLABEL Append a bracketed unit to a plotting label.
arguments
    name (1,1) string
    unit (1,1) string
end

if contains(lower(name), "strain") && ...
        (unit == "-" || unit == "1" || strlength(unit) == 0)
    unit = "mm/mm";
end

if strlength(unit) == 0
    label = name;
else
    label = name + " [" + unit + "]";
end
end
