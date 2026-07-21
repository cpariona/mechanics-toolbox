function normalized = normalizeColumnName(name)
%NORMALIZECOLUMNNAME Normalize table column names for robust matching.
name = lower(string(name));
normalized = regexprep(name, "[^a-z0-9]", "");
end
