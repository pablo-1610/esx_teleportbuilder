function validateTpBuilder(builder)
    return (builder.point_a.coords ~= nil and builder.point_b.coords ~= nil)
end

function replaceAll(str, find, replace)
    return string.gsub(str, find, replace)
end