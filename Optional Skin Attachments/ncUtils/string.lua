ncUtils.String = {}

--Check if string starts with head
function ncUtils.String:head_match(check, head)
	return head == check:sub(1, #head)
end

--Check if string ends with tail
function ncUtils.String:tail_match(check, tail)
	return tail == "" or tail == check:sub(-#tail)
end

--Check if string contains substring
--Use find with literal matching
function ncUtils.String:contains(check, substring)
	return check:find(substring, 1, true) ~= nil
end

--Remove prefix if present.
--Returns the original string if prefix is "" or prefix does not match.
function ncUtils.String:strip_prefix(check, prefix)
	if prefix == "" or not self:head_match(check, prefix) then
		return check
	end

	return check:sub(#prefix + 1)
end

--Remove suffix if present.
--Returns the original string if suffix is "" or suffix does not match.
function ncUtils.String:strip_suffix(check, suffix)
	if suffix == "" or not self:tail_match(check, suffix) then
		return check
	end

	return check:sub(1, -#suffix - 1)
end
