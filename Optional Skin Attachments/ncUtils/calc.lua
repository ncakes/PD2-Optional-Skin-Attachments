ncUtils.Calc = {}

--Number of decimals defaults to 0
function ncUtils.Calc:round(val, decimals)
	decimals = decimals or 0
	local multiplier = 10 ^ decimals
	return math.floor(val * multiplier + 0.5) / multiplier
end

function ncUtils.Calc:clamp(val, min_val, max_val)
	return math.max(math.min(val, max_val), min_val)
end

function ncUtils.Calc:lerp(factor, min_val, max_val)
	return min_val + (max_val - min_val) * factor
end

function ncUtils.Calc:inverse_lerp(val, min_val, max_val)
	return (val - min_val) / (max_val - min_val)
end
